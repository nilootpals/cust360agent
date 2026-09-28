"""
Customer360 SQL Agent + API server (LangChain + FastAPI)
========================================================

One file that is both the AI agent and the server side of the React UI.

How a chat question flows
-------------------------
  React  --POST /api/chat-->  chat()  -->  Customer360SQLAgent.ask_with_trace()
     --> LangChain agent loop (create_agent):
           1. the LLM (init_chat_model(C360_MODEL), default openai:gpt-4.1) reads the question
              and the system prompt, and decides which tool to call;
           2. the tool runs on this server: run_sql (validated, read-only SQL on Postgres),
              describe_objects, list_objects or search_news;
           3. the tool result goes back to the LLM; steps 1-3 repeat until it writes the answer.
     <-- {"answer", "steps", "thread_id"} back to React
  Conversation memory is kept per thread_id (InMemorySaver).
  Dashboards, search and shortcuts do NOT call the LLM: they query the pre-computed
  analytics layer directly, so they are instant and free.

Run
---
    pip install -r requirements.txt
    export DATABASE_URL="postgresql+psycopg://postgres@localhost:5432/customer360"
    export OPENAI_API_KEY=sk-...                 # chat only
    export C360_MODEL="openai:gpt-4.1"           # optional, any init_chat_model id

    python customer360_sql_agent.py              # HTTP API on http://127.0.0.1:8000 (+ UI if frontend/dist exists)
    python customer360_sql_agent.py --reload     # same, auto-reload while developing
    python customer360_sql_agent.py cli          # chat in the terminal instead
    uvicorn customer360_sql_agent:app --port 8000   # or run the app with uvicorn directly

Interactive API docs: http://127.0.0.1:8000/docs
"""

from __future__ import annotations

import datetime as dt
import decimal
import json
import logging
import os
import threading
import uuid
from functools import lru_cache
from pathlib import Path
from typing import Any

import psycopg
import sqlglot
from sqlglot import exp
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import DBAPIError

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from langchain.agents import create_agent
from langchain.chat_models import init_chat_model
from langchain_core.tools import tool
from langgraph.checkpoint.memory import InMemorySaver

logging.basicConfig(level=os.getenv("C360_LOG_LEVEL", "INFO"))
logger = logging.getLogger("customer360_agent")

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql+psycopg://postgres@localhost:5432/customer360"
)
MODEL_ID = os.getenv("C360_MODEL", "openai:gpt-5.6-sol")
MAX_ROWS = int(os.getenv("C360_MAX_ROWS", "200"))
STATEMENT_TIMEOUT_MS = int(os.getenv("C360_STATEMENT_TIMEOUT_MS", "15000"))
MAX_CELL_CHARS = 300  # truncates long text / pgvector embeddings in results

# Pre-computed analytics layer (analytics_layer.sql) and ML outputs: the agent's first stop.
ANALYTICS_OBJECTS = {
    "mv_customer_360": "START HERE. One row per customer: profile, SGD totals, allocation %, leverage, concentration, rate-hike impact and rank, income, behaviour, investor type, ML segment, age-cohort percentiles, suitability flags.",
    "mv_position_sgd": "Every position (holding, fund, FD, cash, margin loan) in SGD with economic exposure (delta-adjusted derivatives), duration, complexity and risk rating.",
    "mv_customer_exposure": "Allocation, economic exposure, leverage, concentration and complex products per customer (SGD).",
    "mv_customer_rate_sensitivity": "Duration, DV01, +25bp/+100bp impact, FD repricing, FDs below market rate, per customer (SGD).",
    "mv_customer_income": "Trailing-12m investment income, earned income, spending and FD maturity ladder (SGD).",
    "mv_customer_behaviour": "Trailing-12m trading behaviour: trades/month, option share, turnover, net premium, flows (SGD).",
    "ml_customer_segment": "K-Means segment per customer (segment_id, segment_name).",
    "ml_segment_profile": "Description and centre of each ML segment.",
    "ml_transaction_anomaly": "Transactions flagged as unusual by the Isolation Forest model, with score and reasons.",
    "metric_catalog": "Definition, formula, unit and caveats of every pre-computed metric.",
    "ref_fx_rate": "FX rates to SGD used for conversion.",
    "ref_market_rate": "Current market deposit rates used for FD comparisons.",
    "ref_duration_assumption": "Duration assumptions used for rate sensitivity.",
    "vw_customer_model_gap": "Customer allocation vs their life-stage model portfolio, per bucket (actual_pct, target_pct, gap_pct, gap_status).",
    "ref_model_portfolio": "Model portfolio targets by bucket and the age range each model applies to.",
    "vw_customer_news_relevance": "Recent news matched to each customer (match_type, matched_on, exposure_sgd, relevance_score). Use for 'which news matters to X'.",
}

# Semantic layer views on the raw data.
SEMANTIC_VIEWS = {
    "vw_dim_customer": "Customer profile: name, age, occupation, income, net worth, segment, tenure.",
    "vw_fact_customer_wealth": "Portfolio aggregation per ACTIVE customer: cash, equity, fund, fixed-deposit values, total_portfolio_value, liquidity_ratio.",
    "vw_fact_risk_profile": "Risk metrics: equity/fund/fixed-income %, concentration, diversification_score, risk_profile.",
    "vw_fact_trading_activity": "Trading/transaction behaviour, unrealised P&L, win rate, days since last activity.",
    "vw_investor_profile": "Investor classification (investor_type) with the metrics behind it; already joins name, age and wealth.",
    "vw_fact_relevant_news": "News from the last 90 days linked to a customer's equity holdings by symbol/sector (macro news with no sector is NOT linked).",
}
# Base tables allowed for drill-down (fund categories, FD rates/maturities,
# sectors, macro news, product-level transactions). PII-heavy tables
# (customer_profile, channel_activity) are deliberately excluded. Override with C360_EXTRA_TABLES.
DRILLDOWN_TABLES = {
    t.strip()
    for t in os.getenv(
        "C360_EXTRA_TABLES",
        "holding,security,derivative_contract,fund_investment,fixed_deposit,account,customer_transaction,news_research,customer_insight",
    ).split(",")
    if t.strip()
}
ALLOWED_OBJECTS = set(ANALYTICS_OBJECTS) | set(SEMANTIC_VIEWS) | DRILLDOWN_TABLES

# Functions that could read server files, sleep, or reach other servers.
BLOCKED_FUNCTIONS = {
    "pg_sleep", "pg_read_file", "pg_read_binary_file", "pg_ls_dir", "pg_stat_file",
    "lo_import", "lo_export", "dblink", "dblink_exec", "pg_terminate_backend",
    "pg_cancel_backend", "set_config", "pg_reload_conf", "query_to_xml",
    "current_setting", "refresh_analytics",
}
EMBEDDING_MODEL = os.getenv("C360_EMBEDDING_MODEL", "text-embedding-3-small")


# --------------------------------------------------------------------------- #
# Database access
# --------------------------------------------------------------------------- #

@lru_cache(maxsize=1)
def get_engine() -> Engine:
    """Every session is read-only with a statement timeout, enforced by Postgres itself."""
    return create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        connect_args={
            "options": f"-c default_transaction_read_only=on "
                       f"-c statement_timeout={STATEMENT_TIMEOUT_MS}"
        },
    )


class SQLValidationError(ValueError):
    pass


def validate_sql(sql: str) -> str:
    """Parse the SQL and allow only a single read-only query over allowed objects.

    Uses a real SQL parser instead of substring checks, so column names like
    `last_updated` or text like ILIKE '%delete%' are not falsely rejected, and
    CTEs (WITH ...) and UNIONs are allowed.
    """
    sql = sql.strip().rstrip(";").strip()
    if not sql:
        raise SQLValidationError("Empty query.")
    try:
        statements = [s for s in sqlglot.parse(sql, read="postgres") if s is not None]
    except sqlglot.errors.ParseError as e:
        raise SQLValidationError(f"Could not parse SQL: {e}") from e
    if len(statements) != 1:
        raise SQLValidationError("Exactly one SQL statement is allowed.")
    stmt = statements[0]

    if not isinstance(stmt, exp.Query):  # Select / Union / Intersect / Except (incl. WITH)
        raise SQLValidationError("Only SELECT queries are allowed.")
    forbidden = (exp.Insert, exp.Update, exp.Delete, exp.Drop, exp.Create,
                 exp.Alter, exp.Command, exp.Into, exp.Merge, exp.TruncateTable)
    for node in stmt.walk():
        if isinstance(node, forbidden):
            raise SQLValidationError(f"{type(node).__name__} is not allowed; read-only SELECT only.")
        if isinstance(node, (exp.Anonymous, exp.Func)):
            fname = (node.name if isinstance(node, exp.Anonymous) else node.sql_name()).lower()
            if fname in BLOCKED_FUNCTIONS:
                raise SQLValidationError(f"Function {fname}() is not allowed.")

    cte_names = {cte.alias_or_name.lower() for cte in stmt.find_all(exp.CTE)}
    for table in stmt.find_all(exp.Table):
        name = table.name.lower()
        if not name:  # table-valued function such as generate_series(...)
            continue
        if table.db and table.db.lower() != "public":
            raise SQLValidationError(f"Schema '{table.db}' is not allowed.")
        if name not in ALLOWED_OBJECTS and name not in cte_names:
            raise SQLValidationError(
                f"'{name}' is not an allowed object. Allowed: {', '.join(sorted(ALLOWED_OBJECTS))}"
            )
    return sql


def _jsonable(v: Any) -> Any:
    if isinstance(v, decimal.Decimal):
        return float(v)
    if isinstance(v, (dt.date, dt.datetime, dt.time)):
        return v.isoformat()
    if isinstance(v, dt.timedelta):
        return str(v)
    if isinstance(v, str) and len(v) > MAX_CELL_CHARS:
        return v[:MAX_CELL_CHARS] + "...(truncated)"
    if v is None or isinstance(v, (int, float, bool)):
        return v
    s = str(v)
    return s if len(s) <= MAX_CELL_CHARS else s[:MAX_CELL_CHARS] + "...(truncated)"


def execute_select(sql: str) -> dict:
    """Validate and run a query; returns columns/rows or raises."""
    sql = validate_sql(sql)
    # Wrap so the row cap never alters the query's own semantics (ORDER BY,
    # aggregates, existing LIMIT all keep working). Newline guards trailing -- comments.
    wrapped = f"SELECT * FROM (\n{sql}\n) AS _q LIMIT {MAX_ROWS + 1}"
    logger.info("SQL: %s", " ".join(sql.split())[:500])
    with get_engine().connect() as conn:
        # Raw psycopg cursor with no parameters: SQL goes to Postgres verbatim, so
        # model-written literals like ILIKE '%tan%' or ':' are never treated as placeholders.
        cur = conn.connection.driver_connection.cursor()
        try:
            cur.execute(wrapped)
            columns = [d.name for d in cur.description]
            rows = cur.fetchall()
        finally:
            cur.close()
            conn.rollback()
    truncated = len(rows) > MAX_ROWS
    rows = rows[:MAX_ROWS]
    return {
        "columns": columns,
        "rows": [[_jsonable(v) for v in r] for r in rows],
        "row_count": len(rows),
        "truncated": truncated,
    }


# --------------------------------------------------------------------------- #
# Tools exposed to the LLM
# --------------------------------------------------------------------------- #

@tool
def list_objects() -> str:
    """List the views and tables you are allowed to query, with a one-line purpose each.
    Semantic views are the primary source; base tables are for drill-down detail."""
    lines = ["PRE-COMPUTED ANALYTICS (use first; amounts in SGD):"]
    lines += [f"- {k}: {v}" for k, v in ANALYTICS_OBJECTS.items()]
    lines.append("SEMANTIC VIEWS (raw currency; for detail not in the analytics layer):")
    lines += [f"- {k}: {v}" for k, v in SEMANTIC_VIEWS.items()]
    lines.append("DRILL-DOWN TABLES:")
    lines += [f"- {t}" for t in sorted(DRILLDOWN_TABLES)]
    return "\n".join(lines)


@tool
def describe_objects(object_names: list[str], include_definition: bool = False) -> str:
    """Return the real column names, data types and column descriptions for the given
    views/tables, read live from Postgres. Set include_definition=True to also get a
    view's SQL definition, which shows exactly how its metrics and labels are calculated.
    Always call this before writing SQL against an object you have not described yet."""
    names = [n.strip().lower() for n in object_names if n.strip()]
    bad = [n for n in names if n not in ALLOWED_OBJECTS]
    if bad:
        return f"ERROR: not allowed/unknown: {bad}. Allowed: {sorted(ALLOWED_OBJECTS)}"
    out = []
    with get_engine().connect() as conn:
        for n in names:
            # pg_catalog (not information_schema) so materialized views are included too
            cols = conn.execute(
                text("""SELECT a.attname, format_type(a.atttypid, a.atttypmod), col_description(c.oid, a.attnum)
                        FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
                        JOIN pg_namespace ns ON ns.oid = c.relnamespace
                        WHERE ns.nspname = 'public' AND c.relname = :t AND a.attnum > 0 AND NOT a.attisdropped
                        ORDER BY a.attnum"""),
                {"t": n},
            ).fetchall()
            if not cols:
                out.append(f"## {n}\n(not found in database)")
                continue
            rel_comment = conn.execute(text("SELECT obj_description(CAST(:v AS regclass), 'pg_class')"),
                                       {"v": f"public.{n}"}).scalar()
            block = f"## {n}" + (f"\n{rel_comment}" if rel_comment else "") + "\n" + "\n".join(
                f"- {c} ({t})" + (f": {d}" if d else "") for c, t, d in cols)
            if include_definition and n.startswith(("vw_", "mv_")):
                d = conn.execute(text("SELECT pg_get_viewdef(CAST(:v AS regclass), true)"),
                                 {"v": f"public.{n}"}).scalar()
                block += f"\nDEFINITION:\n{d}"
            out.append(block)
        conn.rollback()
    return "\n\n".join(out)


@tool
def run_sql(query: str) -> str:
    """Execute ONE read-only PostgreSQL SELECT (CTEs allowed) against the allowed
    objects and return the result as JSON. At most 200 rows are returned; aggregate or
    ORDER BY ... LIMIT in SQL rather than pulling raw rows. If you get an ERROR, read it,
    fix the SQL and try again."""
    try:
        res = execute_select(query)
    except SQLValidationError as e:
        return f"ERROR (validation): {e}"
    except (DBAPIError, psycopg.Error) as e:
        msg = str(getattr(e, "orig", None) or e).strip().splitlines()
        return "ERROR (database): " + " | ".join(msg[:3])
    except Exception as e:  # noqa: BLE001 - surface anything to the model
        return f"ERROR: {type(e).__name__}: {e}"
    return json.dumps(res, default=str)


def _embed_query(query: str) -> str | None:
    """Embed the search text with the same model used by news_embeddings.py."""
    if not os.getenv("OPENAI_API_KEY"):
        return None
    from openai import OpenAI
    vec = OpenAI().embeddings.create(model=EMBEDDING_MODEL, input=[query]).data[0].embedding
    return "[" + ",".join(f"{v:.7f}" for v in vec) + "]"


NEWS_COLUMNS = ("research_id, published_at::date AS published, source, title, left(content, 400) AS summary, "
                "security_symbol, sector, country, sentiment, url")


@tool
def search_news(query: str, days: int = 90, k: int = 8) -> str:
    """Semantic search over news_research (real articles and research). Describe what you are
    looking for in plain words, e.g. 'impact of higher US rates on bonds' or 'Japanese yen and
    exporters'. Returns the closest articles from the last `days` days with source, date, url and
    sentiment. Falls back to keyword search if embeddings are not available."""
    k = max(1, min(int(k), 20))
    days = max(1, min(int(days), 3650))
    try:
        with get_engine().connect() as conn:
            cur = conn.connection.driver_connection.cursor()
            try:
                cur.execute("SELECT count(*) FROM news_research WHERE embedding IS NOT NULL")
                has_vectors = cur.fetchone()[0] > 0
                vec = _embed_query(query) if has_vectors else None
                if vec:
                    cur.execute(
                        f"""SELECT {NEWS_COLUMNS}, round((1 - (embedding <=> %s::vector))::numeric, 3) AS similarity
                            FROM news_research
                            WHERE embedding IS NOT NULL AND published_at >= now() - %s * interval '1 day'
                            ORDER BY embedding <=> %s::vector LIMIT %s""",
                        (vec, days, vec, k))
                    method = "semantic"
                else:
                    words = [w for w in query.lower().split() if len(w) > 2][:8] or [query.lower()]
                    patterns = [f"%{w}%" for w in words]
                    cur.execute(
                        f"""SELECT * FROM (
                              SELECT {NEWS_COLUMNS},
                                     (SELECT count(*) FROM unnest(%s::text[]) p
                                      WHERE lower(title || ' ' || coalesce(content, '')) LIKE p) AS words_matched
                              FROM news_research
                              WHERE published_at >= now() - %s * interval '1 day') n
                            WHERE words_matched > 0
                            ORDER BY words_matched DESC, (url IS NOT NULL) DESC, published DESC LIMIT %s""",
                        (patterns, days, k))
                    method = "keyword" if has_vectors else "keyword (no embeddings stored yet)"
                cols = [d.name for d in cur.description]
                rows = [[_jsonable(v) for v in r] for r in cur.fetchall()]
            finally:
                cur.close()
                conn.rollback()
    except Exception as e:  # noqa: BLE001
        return f"ERROR: {type(e).__name__}: {e}"
    return json.dumps({"method": method, "columns": cols, "rows": rows}, default=str)


TOOLS = [list_objects, describe_objects, run_sql, search_news]


# --------------------------------------------------------------------------- #
# Prompt
# --------------------------------------------------------------------------- #

SYSTEM_PROMPT = f"""You are a wealth-management analyst for a private bank. You answer questions
about customers' investments by querying the Customer360 PostgreSQL database with your tools.
Today is {{today}}.

WORKFLOW
1. Start with mv_customer_360 (one row per customer, amounts in SGD) and the other pre-computed
   objects (mv_*, ml_*). Read metric_catalog or describe_objects for what a metric means and how
   it is calculated; use the raw views/tables only for detail the analytics layer lacks.
2. Call describe_objects before querying an object you have not described (column names in your
   memory may be wrong; the database is the source of truth).
3. Write PostgreSQL and call run_sql. You may call it several times: look up the customer first,
   then drill down. If a query errors, fix it and retry.
4. For news and research use search_news (semantic search); cite source, date and url.
5. Answer from the returned data only. Never invent numbers, customers or columns.

SQL RULES
- Read-only SELECT (WITH ... allowed). Always alias tables and qualify columns: many views share
  column names (customer_id, customer_number, equity_pct, risk_profile ...) and unqualified names
  cause "ambiguous column" errors.
- Join on customer_id. Aggregate in SQL; use ORDER BY + LIMIT for rankings.
- Find a customer by name with c.full_name ILIKE '%name%' on mv_customer_360. If several customers
  match, list them and ask which one is meant.
- Do not return email or mobile_number unless the user explicitly asks for contact details.
- mv_customer_360 includes all statuses; filter status = 'ACTIVE' for rankings unless asked otherwise.

DOMAIN GUIDANCE
- "What kind of investor is X": combine investor_type (rule-based, with classification_confidence),
  ml_segment (behaviour/allocation cluster; see ml_segment_profile) and the numbers behind them
  (allocation %, trades_per_month, option_trade_share_pct, leverage_ratio, largest_position_pct,
  suitability_flags).
- "Best portfolio for their age": use age_band, wealth_percentile_in_age_band,
  return_percentile_in_age_band, unrealised_return_pct and growth_vs_age_target_pct (vs the
  110-minus-age guide). State the method and show the top candidates with numbers.
- Interest-rate / Fed questions: use net_impact_plus25bp_sgd / _pct and rate_hike_impact_rank
  (1 = most hurt), with the components (bond_pnl_plus100bp_sgd, dv01_sgd, income_gain_plus25bp_12m_sgd,
  margin cost, fd_below_market_sgd, fd_maturing_12m_sgd). Equity sensitivity is not modelled: mention
  tech_equity_exposure_pct as extra risk. These are estimates from positions and assumptions
  (ref_duration_assumption, ref_market_rate), not realised losses. Use search_news for what central
  banks actually did.
- Model portfolio / "portfolio vs model": vw_customer_model_gap (life-stage model by age; gaps beyond +/-10
  points are OVERWEIGHT/UNDERWEIGHT). News that matters to a customer: vw_customer_news_relevance ordered by
  relevance_score, explaining matched_on and exposure_pct_of_aum.
- Unusual activity: ml_transaction_anomaly (score, reasons) joined to customer_transaction; these are
  prompts for review, not proof of wrongdoing.
- Derivatives and structured products are rows in holding JOIN security with security.asset_class IN
  ('OPTION','FUTURE','FX_DERIVATIVE','STRUCTURED_PRODUCT','WARRANT'); their terms (strike, expiry, multiplier,
  barrier, coupon, capital protection, delta, product_risk_rating) are in derivative_contract (join on
  security_id). Negative quantity = short/written position. For futures, FX forwards and accumulators
  holding.market_value is mark-to-market P&L only; use notional (quantity x strike/price x multiplier, or
  notional_amount) to describe economic exposure. The views count all of these inside equity_value.
- Suitability questions: compare product_risk_rating / is_complex_product with the customer's age, income and
  risk profile, and check customer_insight for flagged issues.
- Fixed deposits: status ACTIVE, MATURING (included in wealth) or MATURED (excluded). Deposits locked at
  rates below current levels, and those maturing soon, matter for rate questions.
- News: news_research rows with a url are real articles (cite source, date and url when you use them);
  rows with source 'Synthetic Research Desk' are made-up test data, so prefer real rows and say when an item
  is synthetic.
- Customers with status other than ACTIVE (e.g. DORMANT) are only in vw_dim_customer.
- Transactions: customer_transaction joins to account (account_id -> customer_id). product_type, security_id,
  quantity and unit_price link a transaction to the product traded (EQUITY, ETF, OPTION, FUTURE, FX_DERIVATIVE,
  WARRANT, FUND, FIXED_DEPOSIT, STRUCTURED_PRODUCT, MARGIN, CASH). Inflows are positive, outflows negative.
  Use it for trading frequency, option/futures activity, income (DIVIDEND, FD_INTEREST, NOTE_COUPON) and cash
  flow questions; aggregate in SQL rather than listing raw rows.
- Currency: mv_* objects are in SGD (converted with ref_fx_rate). The raw vw_* views and base tables are in
  the account/instrument currency (SGD or USD) and do not convert; say so if you use them for totals.

ANSWER STYLE
Lead with the direct answer, then the supporting figures (a compact table is fine), then one line on
method/assumptions or data caveats. Be concise and professional; this is analysis, not financial advice.
"""


# --------------------------------------------------------------------------- #
# Agent
# --------------------------------------------------------------------------- #

def _load_examples() -> str:
    """Verified question -> SQL pairs from the example_queries table, used as few-shot guidance."""
    try:
        with get_engine().connect() as conn:
            rows = conn.execute(text("SELECT question, sql, notes FROM example_queries ORDER BY example_id")).fetchall()
            conn.rollback()
    except Exception:  # table not installed yet
        return ""
    if not rows:
        return ""
    parts = ["\nVERIFIED EXAMPLE QUERIES (adapt them; do not copy blindly)"]
    for q, sql, notes in rows:
        parts.append(f"Q: {q}\nSQL: {sql}" + (f"\nNote: {notes}" if notes else ""))
    return "\n\n".join(parts) + "\n"


class Customer360SQLAgent:
    """Conversational wrapper around a LangChain agent with per-thread memory."""

    def __init__(self, model: Any | None = None, recursion_limit: int = 30):
        if model is None:
            if MODEL_ID.startswith("openai:") and not os.getenv("OPENAI_API_KEY"):
                raise ValueError("OPENAI_API_KEY environment variable not set")
            model = init_chat_model(MODEL_ID,reasoning_effort="medium")
        self.recursion_limit = recursion_limit
        prompt = SYSTEM_PROMPT.replace("{today}", dt.date.today().isoformat()) + _load_examples()
        self.agent = create_agent(
            model=model,
            tools=TOOLS,
            system_prompt=prompt,
            checkpointer=InMemorySaver(),
        )
        self.thread_id = str(uuid.uuid4())
        logger.info("SQL agent ready (model=%s, db=%s)", MODEL_ID, get_engine().url.render_as_string())

    def ask(self, question: str) -> str:
        config = {
            "configurable": {"thread_id": self.thread_id},
            "recursion_limit": self.recursion_limit,
        }
        result = self.agent.invoke({"messages": [{"role": "user", "content": question}]}, config)
        final = result["messages"][-1]
        content = final.content
        if isinstance(content, list):  # some providers return content blocks
            content = "".join(b.get("text", "") if isinstance(b, dict) else str(b) for b in content)
        return content

    def ask_with_trace(self, question: str, thread_id: str | None = None) -> tuple[str, list[dict]]:
        """Answer a question in the given conversation thread and return the tool calls made."""
        config = {
            "configurable": {"thread_id": thread_id or self.thread_id},
            "recursion_limit": self.recursion_limit,
        }
        result = self.agent.invoke({"messages": [{"role": "user", "content": question}]}, config)
        msgs = result["messages"]
        start = max(i for i, m in enumerate(msgs) if m.type == "human")
        steps = [{"tool": tc["name"], "args": tc["args"]}
                 for m in msgs[start + 1:] for tc in (getattr(m, "tool_calls", None) or [])]
        content = msgs[-1].content
        if isinstance(content, list):
            content = "".join(b.get("text", "") if isinstance(b, dict) else str(b) for b in content)
        return content, steps

    def reset_conversation(self) -> None:
        self.thread_id = str(uuid.uuid4())
        logger.info("Conversation history reset")

    def close(self) -> None:
        get_engine().dispose()
        logger.info("Agent closed")


# =========================================================================== #
# HTTP API for the React UI (FastAPI)
# =========================================================================== #
#   GET  /api/health
#   GET  /api/overview                       book-level KPIs for the home page
#   GET  /api/customers/search?q=wang        customer search by name or customer number
#   GET  /api/customers/{id}/dashboard       everything the customer dashboard shows (no LLM)
#   GET  /api/shortcuts                      predefined analytics
#   GET  /api/shortcuts/{shortcut_id}        run one predefined analytic (fixed SQL, no LLM)
#   POST /api/chat                           ask the agent: {"message", "thread_id", "customer_id"}
# Dashboards and shortcuts read the analytics layer directly; only /api/chat calls the LLM.

api_logger = logging.getLogger("customer360_api")
app = FastAPI(title="Customer360 Advisor API", version="1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("C360_CORS_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

def _clean(v: Any) -> Any:
    if isinstance(v, decimal.Decimal):
        return float(v)
    if isinstance(v, (dt.datetime, dt.date)):
        return v.isoformat()
    if isinstance(v, list):
        return [_clean(x) for x in v]
    return v


def query(sql: str, **params) -> list[dict]:
    with get_engine().connect() as conn:
        res = conn.execute(text(sql), params)
        cols = list(res.keys())
        rows = [{c: _clean(v) for c, v in zip(cols, r)} for r in res.fetchall()]
        conn.rollback()
    return rows


def query_table(sql: str, **params) -> dict:
    with get_engine().connect() as conn:
        res = conn.execute(text(sql), params)
        cols = list(res.keys())
        rows = [[_clean(v) for v in r] for r in res.fetchall()]
        conn.rollback()
    return {"columns": cols, "rows": rows}


def fmt_sgd(v: float | None) -> str:
    if v is None:
        return "n/a"
    a = abs(v)
    s = f"{a / 1e6:,.2f}m" if a >= 1e6 else f"{a / 1e3:,.0f}k" if a >= 1e3 else f"{a:,.0f}"
    return ("-" if v < 0 else "") + "SGD " + s


# --------------------------------------------------------------------------- #
# Basic endpoints
# --------------------------------------------------------------------------- #

@app.get("/api/health")
def health() -> dict:
    row = query("SELECT max(refreshed_at) AS refreshed_at, count(*) AS customers FROM mv_customer_360")[0]
    return {"status": "ok", "analytics_refreshed_at": row["refreshed_at"], "customers": row["customers"],
            "chat_enabled": bool(os.getenv("OPENAI_API_KEY")) or os.getenv("C360_MODEL", "").split(":")[0] not in ("", "openai")}


@app.get("/api/overview")
def overview() -> dict:
    kpi = query("""
        SELECT count(*) FILTER (WHERE status = 'ACTIVE')                       AS active_customers,
               round(sum(gross_assets_sgd) FILTER (WHERE status = 'ACTIVE'))  AS total_aum_sgd,
               round(sum(net_impact_plus25bp_sgd) FILTER (WHERE status = 'ACTIVE')) AS book_impact_plus25bp_sgd,
               count(*) FILTER (WHERE cardinality(suitability_flags) > 0)      AS customers_with_flags,
               coalesce(sum(ml_anomalies_90d), 0)                              AS unusual_transactions_90d,
               round(sum(fd_maturing_90d_sgd))                                 AS fd_maturing_90d_sgd,
               max(refreshed_at)                                               AS refreshed_at
        FROM mv_customer_360""")[0]
    flags = query("""SELECT f AS flag, count(*) AS customers FROM mv_customer_360, unnest(suitability_flags) f
                     GROUP BY f ORDER BY 2 DESC""")
    news = query("""SELECT research_id, published_at::date AS published, source, title, sentiment, url
                    FROM news_research WHERE url IS NOT NULL ORDER BY published_at DESC LIMIT 5""")
    return {"kpis": kpi, "flags": flags, "latest_news": news}


@app.get("/api/customers/search")
def search_customers(q: str = Query(..., min_length=1), limit: int = 10) -> list[dict]:
    return query("""
        SELECT customer_id, customer_number, full_name, age, nationality, customer_segment, status,
               round(gross_assets_sgd) AS aum_sgd, ml_segment
        FROM mv_customer_360
        WHERE full_name ILIKE :p OR customer_number ILIKE :p
        ORDER BY (full_name ILIKE :prefix) DESC, full_name
        LIMIT :limit""", p=f"%{q.strip()}%", prefix=f"{q.strip()}%", limit=max(1, min(limit, 25)))


# --------------------------------------------------------------------------- #
# Customer dashboard
# --------------------------------------------------------------------------- #

# Isolation Forest scores at or above this are shown as critical; tune on your own data.
ANOMALY_CRITICAL_SCORE = float(os.getenv("C360_ANOMALY_CRITICAL_SCORE", "0.67"))


def key_insights(c: dict, gaps: list[dict], news: list[dict], fds: list[dict], anomalies: list[dict],
                 n_active: int) -> list[dict]:
    """Deterministic, ranked headline insights (severity: critical/serious/warning/info/good)."""
    out: list[dict] = []
    flags = set(c.get("suitability_flags") or [])

    if "COMPLEX_PRODUCT_AGE_65_PLUS" in flags:
        out.append({"severity": "critical", "title": "Complex product held at age {}".format(c["age"]),
                    "detail": f"Holds {c['complex_product_count']} complex product(s) worth {fmt_sgd(c['complex_product_value_sgd'])}, "
                              f"highest risk rating {c['max_product_risk_rating']}/5. Suitability review recommended."})
    if c.get("status") != "ACTIVE":
        out.append({"severity": "serious", "title": f"Account status: {c['status']}",
                    "detail": f"Last transaction {c.get('days_since_last_transaction') or 'n/a'} days ago. "
                              "Check any new activity before acting on this relationship."})
    if anomalies:
        a = anomalies[0]
        sev = "critical" if a["anomaly_score"] >= ANOMALY_CRITICAL_SCORE else "warning"
        out.append({"severity": sev, "title": f"{len(anomalies)} unusual transaction(s) flagged by the ML model",
                    "detail": f"{a['transaction_type']} of {a['currency']} {abs(a['amount']):,.0f} on {a['transaction_date'][:10]}: {a['reasons']}."})
    if "LEVERAGED" in flags:
        out.append({"severity": "serious", "title": f"Leveraged {c['leverage_ratio']:.1f}x",
                    "detail": f"Margin loan {fmt_sgd(c['margin_loan_sgd'])}; gross market exposure is {c['leverage_ratio']:.1f}x net value."})
    rank = c.get("rate_hike_impact_rank")
    if rank and c.get("status") == "ACTIVE" and (c.get("net_impact_plus25bp_pct") or 0) < -0.1:
        out.append({"severity": "serious", "title": f"Rate-hike sensitive: #{rank} of {n_active}",
                    "detail": f"A further +25bp is estimated at {fmt_sgd(c['net_impact_plus25bp_sgd'])} "
                              f"({c['net_impact_plus25bp_pct']:.2f}% of net value) over 12 months."})
    elif (c.get("net_impact_plus25bp_sgd") or 0) > 0:
        out.append({"severity": "good", "title": "Benefits from higher rates",
                    "detail": f"+25bp adds about {fmt_sgd(c['net_impact_plus25bp_sgd'])} a year, mainly from cash and repricing deposits."})
    if (c.get("largest_position_pct") or 0) > 25:
        out.append({"severity": "warning", "title": f"Concentrated in {c['largest_position_name']}",
                    "detail": f"Largest position is {c['largest_position_pct']:.0f}% of AUM."})
    big = [g for g in gaps if g["gap_status"] != "IN_RANGE"]
    if big:
        g = max(big, key=lambda x: abs(x["gap_pct"]))
        out.append({"severity": "warning", "title": f"{g['bucket'].replace('_', ' ').title()} {g['gap_status'].lower()} vs {g['model_name'].replace('_', ' ').lower()} model",
                    "detail": f"{g['actual_pct']:.0f}% actual vs {g['target_pct']:.0f}% target ({g['gap_pct']:+.0f} points)."})
    soon = [f for f in fds if f["days_to_maturity"] is not None and f["days_to_maturity"] <= 90]
    if soon:
        tot = sum(f["market_value_sgd"] for f in soon)
        out.append({"severity": "info", "title": f"{fmt_sgd(tot)} in deposits maturing within 90 days",
                    "detail": "Next: " + ", ".join(f"{f['position_name']} in {f['days_to_maturity']} days" for f in soon[:2]) + ". Reinvestment conversation due."})
    real_news = [n for n in news if not n["is_synthetic"]]
    if real_news:
        n = real_news[0]
        out.append({"severity": "info", "title": "Most relevant news: " + n["title"],
                    "detail": f"{n['source']}, {n['published']}. Matters because of {n['matched_on']} "
                              f"({n['exposure_pct_of_aum'] or 0:.0f}% of AUM)."})
    order = {"critical": 0, "serious": 1, "warning": 2, "info": 3, "good": 4}
    return sorted(out, key=lambda x: order[x["severity"]])[:6]


@app.get("/api/customers/{customer_id}/dashboard")
def customer_dashboard(customer_id: int) -> dict:
    rows = query("SELECT * FROM mv_customer_360 WHERE customer_id = :id", id=customer_id)
    if not rows:
        raise HTTPException(404, "Customer not found")
    c = rows[0]
    gaps = query("""SELECT model_name, bucket, actual_pct, target_pct, gap_pct, gap_status
                    FROM vw_customer_model_gap WHERE customer_id = :id ORDER BY sort_order""", id=customer_id)
    model = query("""SELECT DISTINCT m.model_name, m.description FROM ref_model_portfolio m
                     JOIN vw_customer_model_gap g USING (model_name)
                     WHERE g.customer_id = :id AND m.description IS NOT NULL""", id=customer_id)
    positions = query("""
        SELECT position_source, COALESCE(symbol, position_name) AS name, position_name, instrument_type, asset_class,
               exposure_class, sector, country, currency, quantity, market_value_sgd, economic_exposure_sgd,
               unrealised_pnl_sgd, is_complex_product, product_risk_rating, maturity_date,
               round(100 * market_value_sgd / NULLIF(CAST(:gross AS numeric), 0), 2) AS pct_of_aum
        FROM mv_position_sgd
        WHERE customer_id = :id AND position_source IN ('HOLDING', 'FUND', 'FIXED_DEPOSIT')
        ORDER BY abs(market_value_sgd) DESC LIMIT 12""", id=customer_id, gross=c["gross_assets_sgd"] or 0)
    fds = query("""
        SELECT position_name, market_value_sgd, currency, interest_rate_pct, maturity_date,
               (maturity_date - current_date) AS days_to_maturity,
               interest_rate_pct < (SELECT rate_pct FROM ref_market_rate r WHERE r.currency = p.currency
                                    AND r.product = 'DEPOSIT_12M') AS below_market
        FROM mv_position_sgd p WHERE customer_id = :id AND exposure_class = 'DEPOSIT'
        ORDER BY maturity_date""", id=customer_id)
    complex_products = query("""
        SELECT COALESCE(p.symbol, p.position_name) AS name, p.position_name, p.instrument_type,
               p.product_risk_rating, p.market_value_sgd, p.economic_exposure_sgd, p.maturity_date,
               dc.barrier_level_pct, dc.coupon_rate_pct, dc.capital_protection_pct, dc.description
        FROM mv_position_sgd p LEFT JOIN derivative_contract dc ON dc.security_id = p.security_id
        WHERE p.customer_id = :id AND p.is_complex_product
        ORDER BY p.product_risk_rating DESC NULLS LAST, abs(p.market_value_sgd) DESC""", id=customer_id)
    news = query("""
        SELECT research_id, published, source, title, summary, sentiment, url, is_synthetic, match_type,
               matched_on, exposure_sgd, exposure_pct_of_aum, relevance_score
        FROM vw_customer_news_relevance WHERE customer_id = :id
        ORDER BY relevance_score DESC LIMIT 8""", id=customer_id)
    anomalies = query("""
        SELECT a.transaction_date, t.transaction_type, t.amount, t.currency, t.description, a.anomaly_score, a.reasons
        FROM ml_transaction_anomaly a JOIN customer_transaction t USING (transaction_id)
        WHERE a.customer_id = :id AND a.transaction_date >= now() - interval '90 days'
        ORDER BY a.anomaly_score DESC LIMIT 5""", id=customer_id)
    segment = query("""SELECT p.segment_name, p.description, p.n_customers FROM ml_customer_segment s
                       JOIN ml_segment_profile p USING (segment_id) WHERE s.customer_id = :id""", id=customer_id)
    notes = query("""SELECT insight_type, insight, confidence FROM customer_insight
                     WHERE customer_id = :id ORDER BY confidence DESC""", id=customer_id)
    n_active = query("SELECT count(*) AS n FROM mv_customer_360 WHERE status = 'ACTIVE'")[0]["n"]
    return {
        "customer": c,
        "insights": key_insights(c, gaps, news, fds, anomalies, n_active),
        "model": {"name": gaps[0]["model_name"] if gaps else None,
                  "description": model[0]["description"] if model else None, "buckets": gaps},
        "positions": positions,
        "fixed_deposits": fds,
        "complex_products": complex_products,
        "news": news,
        "anomalies": anomalies,
        "segment": segment[0] if segment else None,
        "rm_notes": notes,
        "active_customers": n_active,
    }


# --------------------------------------------------------------------------- #
# Predefined analytics shortcuts
# --------------------------------------------------------------------------- #

SHORTCUTS: dict[str, dict] = {
    "rate_hike_impact": {
        "title": "Most hit by the Fed hike", "category": "Rates",
        "description": "Estimated 12-month impact of a further +25bp on each customer.",
        "ask": "Who is most impacted by the recent Fed rate hike, and why? Use the pre-computed rate sensitivity and cite relevant news.",
        "sql": """SELECT c.customer_id, c.full_name AS customer, c.age, round(c.net_value_sgd) AS net_value_sgd,
                         round(c.net_impact_plus25bp_sgd) AS impact_plus25bp_sgd, c.net_impact_plus25bp_pct AS impact_pct,
                         round(c.bond_pnl_plus100bp_sgd) AS bond_pnl_plus100bp_sgd, round(c.margin_loan_sgd) AS margin_loan_sgd
                  FROM mv_customer_360 c WHERE c.status = 'ACTIVE' ORDER BY c.net_impact_plus25bp_sgd LIMIT 10"""},
    "fd_maturing": {
        "title": "Deposits maturing in 90 days", "category": "Opportunities",
        "description": "Fixed deposits coming up for renewal, with rate vs today's market.",
        "ask": "Which fixed deposits mature in the next 90 days, and what reinvestment conversations should we have given current rates?",
        "sql": """SELECT c.customer_id, c.full_name AS customer, c.age, p.position_name AS deposit, round(p.market_value_sgd) AS value_sgd,
                         p.interest_rate_pct AS rate_pct, p.maturity_date, (p.maturity_date - current_date) AS days_left
                  FROM mv_position_sgd p JOIN mv_customer_360 c USING (customer_id)
                  WHERE p.exposure_class = 'DEPOSIT' AND p.maturity_date <= current_date + 90 ORDER BY p.maturity_date"""},
    "complex_elderly": {
        "title": "Complex products, age 65+", "category": "Suitability",
        "description": "Customers aged 65+ holding products rated 4-5 or complex funds.",
        "ask": "Which elderly customers hold high-risk complex products, and what are the suitability concerns?",
        "sql": """SELECT c.customer_id, c.full_name AS customer, c.age, p.position_name AS product, p.instrument_type AS type,
                         p.product_risk_rating AS risk_rating, round(p.market_value_sgd) AS value_sgd
                  FROM mv_customer_360 c JOIN mv_position_sgd p USING (customer_id)
                  WHERE c.age >= 65 AND p.is_complex_product AND p.product_risk_rating >= 4 ORDER BY c.age DESC"""},
    "best_for_age": {
        "title": "Best portfolio for age", "category": "Performance",
        "description": "Top customer in each age band by return and wealth percentile.",
        "ask": "Who has the best wealth portfolio according to his or her age? Explain the method.",
        "sql": """SELECT DISTINCT ON (c.age_band) c.customer_id, c.age_band, c.full_name AS customer, c.age,
                         round(c.net_value_sgd) AS net_value_sgd, c.unrealised_return_pct AS return_pct,
                         c.return_percentile_in_age_band AS return_pctile, c.wealth_percentile_in_age_band AS wealth_pctile,
                         c.growth_vs_age_target_pct AS growth_vs_target
                  FROM mv_customer_360 c WHERE c.status = 'ACTIVE'
                  ORDER BY c.age_band, c.return_percentile_in_age_band DESC, c.wealth_percentile_in_age_band DESC"""},
    "model_drift": {
        "title": "Furthest from model", "category": "Portfolio",
        "description": "Customers whose allocation deviates most from their life-stage model.",
        "ask": "Which customers' portfolios deviate most from their model portfolio, and how should they rebalance?",
        "sql": """SELECT g.customer_id, g.full_name AS customer, g.age, g.model_name AS model,
                         round(sum(abs(g.gap_pct)) / 2, 1) AS total_drift_pts,
                         string_agg(g.bucket || ' ' || to_char(g.gap_pct, 'SG990'), ', ' ORDER BY abs(g.gap_pct) DESC)
                             FILTER (WHERE g.gap_status <> 'IN_RANGE') AS main_gaps
                  FROM vw_customer_model_gap g WHERE g.status = 'ACTIVE'
                  GROUP BY 1, 2, 3, 4 ORDER BY total_drift_pts DESC LIMIT 10"""},
    "concentration_leverage": {
        "title": "Leverage & concentration", "category": "Risk",
        "description": "Customers with margin loans, high leverage or one dominant position.",
        "ask": "Which customers are most leveraged or concentrated, and what risks does that create?",
        "sql": """SELECT c.customer_id, c.full_name AS customer, c.age, c.leverage_ratio, round(c.margin_loan_sgd) AS margin_loan_sgd,
                         c.largest_position_name AS largest_position, c.largest_position_pct AS largest_pct
                  FROM mv_customer_360 c WHERE c.status = 'ACTIVE'
                  ORDER BY greatest(c.leverage_ratio, c.largest_position_pct / 30.0) DESC LIMIT 10"""},
    "unusual_activity": {
        "title": "Unusual activity (ML)", "category": "Risk",
        "description": "Transactions in the last 30 days flagged by the anomaly model.",
        "ask": "Which customers have unusual recent activity according to the anomaly model? Summarise what looks concerning.",
        "sql": """SELECT a.customer_id, c.full_name AS customer, c.age, a.transaction_date::date AS date, t.transaction_type AS type,
                         t.amount, t.currency, a.anomaly_score AS score, a.reasons
                  FROM ml_transaction_anomaly a JOIN customer_transaction t USING (transaction_id)
                  JOIN mv_customer_360 c ON c.customer_id = a.customer_id
                  WHERE a.transaction_date >= now() - interval '30 days' ORDER BY a.anomaly_score DESC LIMIT 15"""},
    "news_impact": {
        "title": "News that matters", "category": "Market",
        "description": "Real news items ranked by relevance to customers' exposures.",
        "ask": "Which recent news items matter most to our customers, and who is affected?",
        "sql": """SELECT r.customer_id, c.full_name AS customer, r.published, r.source, r.title, r.match_type,
                         r.exposure_pct_of_aum AS pct_of_aum, r.relevance_score AS relevance
                  FROM vw_customer_news_relevance r JOIN mv_customer_360 c USING (customer_id)
                  WHERE NOT r.is_synthetic ORDER BY r.relevance_score DESC LIMIT 15"""},
    "segments": {
        "title": "Customer segments (ML)", "category": "Portfolio",
        "description": "K-Means segments with their members.",
        "ask": "Describe our customer segments and what each needs from its relationship manager.",
        "sql": """SELECT p.segment_name AS segment, p.n_customers AS customers, p.description,
                         string_agg(c.full_name, ', ' ORDER BY c.full_name) AS members
                  FROM ml_segment_profile p JOIN ml_customer_segment s USING (segment_id)
                  JOIN mv_customer_360 c USING (customer_id)
                  GROUP BY 1, 2, 3 ORDER BY 2 DESC"""},
    "top_aum": {
        "title": "Largest relationships", "category": "Portfolio",
        "description": "Top 10 customers by assets under management.",
        "ask": "Summarise our ten largest relationships and their key risks.",
        "sql": """SELECT c.customer_id, c.full_name AS customer, c.age, c.nationality, round(c.gross_assets_sgd) AS aum_sgd,
                         c.investor_type, c.ml_segment AS segment, cardinality(c.suitability_flags) AS flags
                  FROM mv_customer_360 c WHERE c.status = 'ACTIVE' ORDER BY c.gross_assets_sgd DESC LIMIT 10"""},
}


@app.get("/api/shortcuts")
def list_shortcuts() -> list[dict]:
    return [{"id": k, **{f: v[f] for f in ("title", "category", "description", "ask")}} for k, v in SHORTCUTS.items()]


@app.get("/api/shortcuts/{shortcut_id}")
def run_shortcut(shortcut_id: str) -> dict:
    sc = SHORTCUTS.get(shortcut_id)
    if not sc:
        raise HTTPException(404, "Unknown shortcut")
    return {"id": shortcut_id, "title": sc["title"], "description": sc["description"], "ask": sc["ask"],
            **query_table(sc["sql"])}


# --------------------------------------------------------------------------- #
# Chat
# --------------------------------------------------------------------------- #

_agent: Customer360SQLAgent | None = None
_agent_lock = threading.Lock()


def get_agent() -> Customer360SQLAgent:
    global _agent
    with _agent_lock:
        if _agent is None:
            try:
                _agent = Customer360SQLAgent()
            except ValueError as e:   # e.g. missing OPENAI_API_KEY
                raise HTTPException(503, str(e)) from e
        return _agent


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    thread_id: str | None = None
    customer_id: int | None = None


@app.post("/api/chat")
def chat(req: ChatRequest) -> dict:   # sync: FastAPI runs it in a worker thread
    agent = get_agent()
    thread_id = req.thread_id or str(uuid.uuid4())
    message = req.message
    if req.customer_id is not None:
        rows = query("SELECT full_name FROM mv_customer_360 WHERE customer_id = :id", id=req.customer_id)
        if rows:
            message = (f"[Context: the user is looking at the dashboard of {rows[0]['full_name']} "
                       f"(customer_id {req.customer_id}). 'This customer', 'he' or 'she' refers to them.]\n{message}")
    try:
        answer, steps = agent.ask_with_trace(message, thread_id)
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        api_logger.exception("chat failed")
        raise HTTPException(500, f"The agent failed: {type(e).__name__}: {e}") from e
    return {"answer": answer, "thread_id": thread_id, "steps": steps}


# --------------------------------------------------------------------------- #
# Serve the built React app (frontend/dist) if present
# --------------------------------------------------------------------------- #

DIST = Path(os.getenv("C360_FRONTEND_DIST", Path(__file__).resolve().parent / "frontend" / "dist"))
if DIST.exists():
    app.mount("/", StaticFiles(directory=DIST, html=True), name="ui")


# =========================================================================== #
# Entry point: HTTP server (default) or terminal chat
# =========================================================================== #

def run_cli() -> None:
    print("\n" + "=" * 80)
    print("CUSTOMER360 SQL AGENT - ask any wealth / investment question")
    print("=" * 80)
    print("Examples:")
    print("  - What kind of investor is Rajiv Sharma?")
    print("  - Who has the best wealth portfolio for his or her age?")
    print("  - Who is the most impacted customer by the recent Fed rate hike?")
    print("Type 'exit' to quit, 'reset' to clear history\n")
    agent = None
    try:
        try:
            agent = Customer360SQLAgent()
        except ValueError as e:        # e.g. OPENAI_API_KEY not set
            print(f"Cannot start the agent: {e}")
            return
        while True:
            try:
                user_input = input("You: ").strip()
            except (EOFError, KeyboardInterrupt):
                print("\nGoodbye!")
                break
            if not user_input:
                continue
            if user_input.lower() in {"exit", "quit"}:
                print("\nGoodbye!")
                break
            if user_input.lower() == "reset":
                agent.reset_conversation()
                print("Conversation history cleared.\n")
                continue
            try:
                print(f"\nAgent: {agent.ask(user_input)}\n")
            except Exception as e:  # keep the REPL alive on a single failure
                logger.exception("Question failed")
                print(f"\nAgent error: {e}\n")
            print("-" * 80)
    finally:
        if agent:
            agent.close()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Customer360 agent: HTTP API for the React UI, or terminal chat.")
    parser.add_argument("mode", nargs="?", choices=["serve", "cli"], default="serve",
                        help="serve = start the HTTP API (default); cli = chat in the terminal")
    parser.add_argument("--host", default=os.getenv("C360_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.getenv("C360_PORT", "8000")))
    parser.add_argument("--reload", action="store_true", help="auto-reload on code changes (development)")
    args = parser.parse_args()

    if args.mode == "cli":
        run_cli()
    else:
        import uvicorn
        print(f"Customer360 agent API on http://{args.host}:{args.port}  (docs: /docs)")
        if args.reload:
            uvicorn.run("customer360_sql_agent:app", host=args.host, port=args.port, reload=True)
        else:
            uvicorn.run(app, host=args.host, port=args.port)
