--
-- PostgreSQL database dump
--


-- Dumped from database version 18.6 (Postgres.app)
-- Dumped by pg_dump version 18.6 (Postgres.app)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


--
-- Name: refresh_analytics(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_analytics() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_position_sgd;
    REFRESH MATERIALIZED VIEW mv_customer_exposure;
    REFRESH MATERIALIZED VIEW mv_customer_rate_sensitivity;
    REFRESH MATERIALIZED VIEW mv_customer_income;
    REFRESH MATERIALIZED VIEW mv_customer_behaviour;
    REFRESH MATERIALIZED VIEW mv_customer_360;
    RETURN 'analytics refreshed at ' || now();
END $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account (
    account_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    account_number character varying(30) NOT NULL,
    account_type character varying(50),
    currency character(3),
    balance numeric(18,2),
    opened_date date,
    status character varying(30) DEFAULT 'ACTIVE'::character varying
);


--
-- Name: account_account_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_account_id_seq OWNED BY public.account.account_id;


--
-- Name: channel_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.channel_activity (
    activity_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    activity_time timestamp without time zone NOT NULL,
    channel character varying(30) NOT NULL,
    activity_type character varying(100) NOT NULL,
    amount numeric(18,2),
    currency character(3),
    branch_code character varying(30),
    account_id bigint,
    device character varying(50),
    status character varying(30),
    description text
);


--
-- Name: channel_activity_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.channel_activity_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: channel_activity_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.channel_activity_activity_id_seq OWNED BY public.channel_activity.activity_id;


--
-- Name: customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer (
    customer_id bigint NOT NULL,
    customer_number character varying(20) NOT NULL,
    customer_segment character varying(50),
    customer_since date,
    status character varying(30) DEFAULT 'ACTIVE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_customer_id_seq OWNED BY public.customer.customer_id;


--
-- Name: customer_insight; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_insight (
    insight_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    insight_type character varying(100),
    insight text,
    confidence numeric(5,4),
    evidence text,
    calculated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: customer_insight_insight_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_insight_insight_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_insight_insight_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_insight_insight_id_seq OWNED BY public.customer_insight.insight_id;


--
-- Name: customer_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_profile (
    customer_id bigint NOT NULL,
    full_name character varying(200) NOT NULL,
    date_of_birth date,
    gender character varying(20),
    marital_status character varying(30),
    nationality character varying(50),
    tax_residency character varying(100),
    address_line1 character varying(200),
    address_line2 character varying(200),
    city character varying(100),
    postal_code character varying(20),
    country character varying(50),
    preferred_language character varying(50),
    email character varying(200),
    mobile_number character varying(50),
    occupation character varying(100),
    employer character varying(200),
    annual_income numeric(18,2),
    net_worth numeric(18,2)
);


--
-- Name: customer_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_transaction (
    transaction_id bigint NOT NULL,
    account_id bigint NOT NULL,
    transaction_date timestamp without time zone NOT NULL,
    transaction_type character varying(50),
    amount numeric(18,2) NOT NULL,
    currency character(3),
    merchant character varying(200),
    category character varying(100),
    channel character varying(30),
    description text,
    product_type character varying(30),
    security_id bigint,
    quantity numeric(18,4),
    unit_price numeric(18,6),
    data_source character varying(40)
);


--
-- Name: customer_transaction_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_transaction_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_transaction_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_transaction_transaction_id_seq OWNED BY public.customer_transaction.transaction_id;


--
-- Name: derivative_contract; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.derivative_contract (
    security_id bigint NOT NULL,
    instrument_type character varying(30) NOT NULL,
    underlying_symbol character varying(30),
    underlying_name character varying(200),
    option_type character varying(4),
    strike_price numeric(18,6),
    expiry_date date,
    contract_multiplier numeric(18,4) DEFAULT 1 NOT NULL,
    notional_amount numeric(18,2),
    notional_currency character(3),
    barrier_level_pct numeric(6,2),
    coupon_rate_pct numeric(6,3),
    capital_protection_pct numeric(6,2),
    participation_rate_pct numeric(6,2),
    delta numeric(8,4),
    implied_volatility numeric(8,4),
    settlement_type character varying(20),
    exchange character varying(30),
    product_risk_rating smallint,
    is_complex_product boolean DEFAULT true NOT NULL,
    description text,
    conversion_ratio numeric(12,6) DEFAULT 1 NOT NULL,
    CONSTRAINT derivative_contract_product_risk_rating_check CHECK (((product_risk_rating >= 1) AND (product_risk_rating <= 5)))
);


--
-- Name: example_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.example_queries (
    example_id integer NOT NULL,
    question text NOT NULL,
    sql text NOT NULL,
    notes text
);


--
-- Name: TABLE example_queries; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.example_queries IS 'Worked question-to-SQL examples for the agent, showing the expected objects and phrasing.';


--
-- Name: example_queries_example_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.example_queries_example_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: example_queries_example_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.example_queries_example_id_seq OWNED BY public.example_queries.example_id;


--
-- Name: fixed_deposit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fixed_deposit (
    fd_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    principal numeric(18,2),
    currency character(3),
    interest_rate numeric(6,3),
    start_date date,
    maturity_date date,
    status character varying(30)
);


--
-- Name: fixed_deposit_fd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fixed_deposit_fd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fixed_deposit_fd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fixed_deposit_fd_id_seq OWNED BY public.fixed_deposit.fd_id;


--
-- Name: fund_investment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fund_investment (
    investment_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    fund_name character varying(200),
    fund_category character varying(100),
    currency character(3),
    units numeric(18,4),
    nav numeric(18,4),
    invested_amount numeric(18,2),
    market_value numeric(18,2),
    unrealised_pnl numeric(18,2),
    investment_date date,
    as_of_date date
);


--
-- Name: fund_investment_investment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fund_investment_investment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fund_investment_investment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fund_investment_investment_id_seq OWNED BY public.fund_investment.investment_id;


--
-- Name: holding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holding (
    holding_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    security_id bigint NOT NULL,
    quantity numeric(18,4),
    average_cost numeric(18,4),
    market_price numeric(18,4),
    market_value numeric(18,2),
    unrealised_pnl numeric(18,2),
    as_of_date date
);


--
-- Name: holding_holding_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holding_holding_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holding_holding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holding_holding_id_seq OWNED BY public.holding.holding_id;


--
-- Name: metric_catalog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metric_catalog (
    metric_name character varying(100) NOT NULL,
    object_name character varying(100) NOT NULL,
    column_name text,
    description text NOT NULL,
    unit character varying(30),
    formula text,
    caveats text
);


--
-- Name: TABLE metric_catalog; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.metric_catalog IS 'Data dictionary for the semantic layer: what each column means, how it is computed and where it must not be trusted. Keyed on (object_name, metric_name); column_name lists the columns a metric covers. Maintained in metric_catalog.sql.';


--
-- Name: ml_customer_segment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ml_customer_segment (
    customer_id bigint NOT NULL,
    segment_id integer,
    segment_name text,
    distance_to_centre numeric(10,4),
    model_version text,
    trained_at timestamp without time zone
);


--
-- Name: TABLE ml_customer_segment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ml_customer_segment IS 'K-Means segment per customer, from ml_customer_models.py. Retrained on demand.';


--
-- Name: COLUMN ml_customer_segment.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_customer_segment.customer_id IS 'K-Means cluster of customers by allocation, risk and behaviour; cluster descriptions are in ml_segment_profile Caveat: Retrained on demand; segment names are derived from cluster centres and can change meaning between training runs';


--
-- Name: COLUMN ml_customer_segment.segment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_customer_segment.segment_id IS 'K-Means cluster of customers by allocation, risk and behaviour; cluster descriptions are in ml_segment_profile Caveat: Retrained on demand; segment names are derived from cluster centres and can change meaning between training runs';


--
-- Name: COLUMN ml_customer_segment.segment_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_customer_segment.segment_name IS 'K-Means cluster of customers by allocation, risk and behaviour; cluster descriptions are in ml_segment_profile Caveat: Retrained on demand; segment names are derived from cluster centres and can change meaning between training runs';


--
-- Name: COLUMN ml_customer_segment.distance_to_centre; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_customer_segment.distance_to_centre IS 'How far the customer sits from their cluster centre in the scaled feature space Unit: distance. Caveat: A large distance means the customer fits their segment poorly -- treat the label with caution';


--
-- Name: COLUMN ml_customer_segment.model_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_customer_segment.model_version IS 'Which training run produced this assignment Caveat: Compare with mv_customer_360.refreshed_at: segments can be older than the analytics around them';


--
-- Name: COLUMN ml_customer_segment.trained_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_customer_segment.trained_at IS 'Which training run produced this assignment Caveat: Compare with mv_customer_360.refreshed_at: segments can be older than the analytics around them';


--
-- Name: ml_segment_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ml_segment_profile (
    segment_id integer NOT NULL,
    segment_name text NOT NULL,
    description text,
    n_customers integer,
    centroid jsonb,
    model_version text,
    trained_at timestamp without time zone
);


--
-- Name: TABLE ml_segment_profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ml_segment_profile IS 'Description and centre of each ML segment.';


--
-- Name: COLUMN ml_segment_profile.segment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_segment_profile.segment_id IS 'What each cluster represents and how many customers fall in it Caveat: Descriptions are generated from the cluster centres, not written by a person';


--
-- Name: COLUMN ml_segment_profile.segment_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_segment_profile.segment_name IS 'What each cluster represents and how many customers fall in it Caveat: Descriptions are generated from the cluster centres, not written by a person';


--
-- Name: COLUMN ml_segment_profile.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_segment_profile.description IS 'What each cluster represents and how many customers fall in it Caveat: Descriptions are generated from the cluster centres, not written by a person';


--
-- Name: COLUMN ml_segment_profile.n_customers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_segment_profile.n_customers IS 'What each cluster represents and how many customers fall in it Caveat: Descriptions are generated from the cluster centres, not written by a person';


--
-- Name: COLUMN ml_segment_profile.centroid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_segment_profile.centroid IS 'Cluster centre as JSON, feature by feature Unit: jsonb. Caveat: Values are standardised, not in natural units, so they are only meaningful relative to other segments';


--
-- Name: COLUMN ml_segment_profile.model_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_segment_profile.model_version IS 'Which training run produced this profile';


--
-- Name: COLUMN ml_segment_profile.trained_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_segment_profile.trained_at IS 'Which training run produced this profile';


--
-- Name: ml_transaction_anomaly; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ml_transaction_anomaly (
    transaction_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    transaction_date timestamp without time zone,
    anomaly_score numeric(10,4),
    reasons text,
    model_version text,
    scored_at timestamp without time zone
);


--
-- Name: TABLE ml_transaction_anomaly; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ml_transaction_anomaly IS 'Transactions flagged unusual by the Isolation Forest model. Only flagged rows are stored.';


--
-- Name: COLUMN ml_transaction_anomaly.transaction_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_transaction_anomaly.transaction_id IS 'One row per transaction the model flagged as unusual Caveat: Only flagged transactions are stored, so this table cannot be used to compute a rate over all transactions';


--
-- Name: COLUMN ml_transaction_anomaly.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_transaction_anomaly.customer_id IS 'One row per transaction the model flagged as unusual Caveat: Only flagged transactions are stored, so this table cannot be used to compute a rate over all transactions';


--
-- Name: COLUMN ml_transaction_anomaly.transaction_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_transaction_anomaly.transaction_date IS 'One row per transaction the model flagged as unusual Caveat: Only flagged transactions are stored, so this table cannot be used to compute a rate over all transactions';


--
-- Name: COLUMN ml_transaction_anomaly.anomaly_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_transaction_anomaly.anomaly_score IS 'Isolation Forest score of how unusual a transaction is for that customer, with the contributing features Unit: score. Caveat: Roughly the top 1% are flagged. A prompt for review, not evidence of wrongdoing, and not a financial crime control';


--
-- Name: COLUMN ml_transaction_anomaly.reasons; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_transaction_anomaly.reasons IS 'Isolation Forest score of how unusual a transaction is for that customer, with the contributing features Unit: score. Caveat: Roughly the top 1% are flagged. A prompt for review, not evidence of wrongdoing, and not a financial crime control';


--
-- Name: COLUMN ml_transaction_anomaly.model_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_transaction_anomaly.model_version IS 'Which model run scored the transaction';


--
-- Name: COLUMN ml_transaction_anomaly.scored_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ml_transaction_anomaly.scored_at IS 'Which model run scored the transaction';


--
-- Name: ref_duration_assumption; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_duration_assumption (
    match_kind character varying(20) NOT NULL,
    match_value character varying(200) NOT NULL,
    duration_years numeric(6,2) NOT NULL,
    note text
);


--
-- Name: TABLE ref_duration_assumption; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ref_duration_assumption IS 'Interest-rate duration by symbol, fund name or fund category. The only input behind every duration and rate-shock metric.';


--
-- Name: COLUMN ref_duration_assumption.match_kind; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_duration_assumption.match_kind IS 'Interest-rate duration assigned by symbol, fund name or fund category Unit: years. Caveat: The single input behind every duration, DV01 and rate-shock number in the layer. Anything with no match gets duration 0 and is treated as rate-insensitive';


--
-- Name: COLUMN ref_duration_assumption.match_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_duration_assumption.match_value IS 'Interest-rate duration assigned by symbol, fund name or fund category Unit: years. Caveat: The single input behind every duration, DV01 and rate-shock number in the layer. Anything with no match gets duration 0 and is treated as rate-insensitive';


--
-- Name: COLUMN ref_duration_assumption.duration_years; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_duration_assumption.duration_years IS 'Interest-rate duration assigned by symbol, fund name or fund category Unit: years. Caveat: The single input behind every duration, DV01 and rate-shock number in the layer. Anything with no match gets duration 0 and is treated as rate-insensitive';


--
-- Name: COLUMN ref_duration_assumption.note; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_duration_assumption.note IS 'Interest-rate duration assigned by symbol, fund name or fund category Unit: years. Caveat: The single input behind every duration, DV01 and rate-shock number in the layer. Anything with no match gets duration 0 and is treated as rate-insensitive';


--
-- Name: ref_fx_rate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_fx_rate (
    currency character(3) NOT NULL,
    as_of_date date NOT NULL,
    units_per_usd numeric(18,6) NOT NULL,
    rate_to_sgd numeric(18,8) NOT NULL,
    source text
);


--
-- Name: TABLE ref_fx_rate; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ref_fx_rate IS 'Dated FX rates to SGD. Every amount in the mv_* objects is converted with these.';


--
-- Name: COLUMN ref_fx_rate.currency; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_fx_rate.currency IS 'Exchange rates used to convert every amount in the mv_* objects into SGD Unit: rate. Caveat: Dated snapshots, not a live feed. vw_fx_latest picks the newest row per currency however old it is, so always check as_of_date before quoting converted totals';


--
-- Name: COLUMN ref_fx_rate.as_of_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_fx_rate.as_of_date IS 'Exchange rates used to convert every amount in the mv_* objects into SGD Unit: rate. Caveat: Dated snapshots, not a live feed. vw_fx_latest picks the newest row per currency however old it is, so always check as_of_date before quoting converted totals';


--
-- Name: COLUMN ref_fx_rate.units_per_usd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_fx_rate.units_per_usd IS 'Exchange rates used to convert every amount in the mv_* objects into SGD Unit: rate. Caveat: Dated snapshots, not a live feed. vw_fx_latest picks the newest row per currency however old it is, so always check as_of_date before quoting converted totals';


--
-- Name: COLUMN ref_fx_rate.rate_to_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_fx_rate.rate_to_sgd IS 'Exchange rates used to convert every amount in the mv_* objects into SGD Unit: rate. Caveat: Dated snapshots, not a live feed. vw_fx_latest picks the newest row per currency however old it is, so always check as_of_date before quoting converted totals';


--
-- Name: COLUMN ref_fx_rate.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_fx_rate.source IS 'Exchange rates used to convert every amount in the mv_* objects into SGD Unit: rate. Caveat: Dated snapshots, not a live feed. vw_fx_latest picks the newest row per currency however old it is, so always check as_of_date before quoting converted totals';


--
-- Name: ref_underlying_level; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_underlying_level (
    underlying_symbol character varying(30) NOT NULL,
    level numeric(18,6) NOT NULL,
    as_of_date date,
    note text
);


--
-- Name: TABLE ref_underlying_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ref_underlying_level IS 'Spot level per derivative underlying, used to size delta-adjusted exposure.';


--
-- Name: COLUMN ref_underlying_level.underlying_symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_underlying_level.underlying_symbol IS 'Spot level of a derivative underlying, used to size delta-adjusted exposure Unit: price. Caveat: When a symbol is missing the calculation falls back to the highest market price of any holding in that symbol, which may be stale or from another customer';


--
-- Name: COLUMN ref_underlying_level.level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_underlying_level.level IS 'Spot level of a derivative underlying, used to size delta-adjusted exposure Unit: price. Caveat: When a symbol is missing the calculation falls back to the highest market price of any holding in that symbol, which may be stale or from another customer';


--
-- Name: COLUMN ref_underlying_level.as_of_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_underlying_level.as_of_date IS 'Spot level of a derivative underlying, used to size delta-adjusted exposure Unit: price. Caveat: When a symbol is missing the calculation falls back to the highest market price of any holding in that symbol, which may be stale or from another customer';


--
-- Name: COLUMN ref_underlying_level.note; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_underlying_level.note IS 'Spot level of a derivative underlying, used to size delta-adjusted exposure Unit: price. Caveat: When a symbol is missing the calculation falls back to the highest market price of any holding in that symbol, which may be stale or from another customer';


--
-- Name: security; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security (
    security_id bigint NOT NULL,
    symbol character varying(30),
    security_name character varying(200),
    asset_class character varying(50),
    country character varying(50),
    sector character varying(100),
    currency character(3)
);


--
-- Name: vw_fx_latest; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_fx_latest AS
 SELECT DISTINCT ON (currency) currency,
    rate_to_sgd,
    as_of_date
   FROM public.ref_fx_rate
  ORDER BY currency, as_of_date DESC;


--
-- Name: VIEW vw_fx_latest; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_fx_latest IS 'Newest FX rate per currency from ref_fx_rate. The single conversion source for the analytics layer. No staleness guard: an old rate is served without warning.';


--
-- Name: COLUMN vw_fx_latest.currency; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fx_latest.currency IS 'The most recent rate per currency, the single conversion source for the analytics layer Unit: rate. Caveat: No staleness guard: an old rate is served silently. A currency missing here is converted at 1.0 and flagged by mv_position_sgd.fx_rate_missing';


--
-- Name: COLUMN vw_fx_latest.rate_to_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fx_latest.rate_to_sgd IS 'The most recent rate per currency, the single conversion source for the analytics layer Unit: rate. Caveat: No staleness guard: an old rate is served silently. A currency missing here is converted at 1.0 and flagged by mv_position_sgd.fx_rate_missing';


--
-- Name: COLUMN vw_fx_latest.as_of_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fx_latest.as_of_date IS 'The most recent rate per currency, the single conversion source for the analytics layer Unit: rate. Caveat: No staleness guard: an old rate is served silently. A currency missing here is converted at 1.0 and flagged by mv_position_sgd.fx_rate_missing';


--
-- Name: mv_position_sgd; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_position_sgd AS
 WITH fx AS (
         SELECT vw_fx_latest.currency,
            vw_fx_latest.rate_to_sgd
           FROM public.vw_fx_latest
        ), holdings AS (
         SELECT h.customer_id,
            'HOLDING'::text AS position_source,
            h.holding_id AS source_id,
            s.security_id,
            s.symbol,
            s.security_name AS position_name,
            s.asset_class,
            dc.instrument_type,
            s.sector,
            s.country,
            s.currency,
            h.quantity,
            h.market_price,
            h.market_value AS market_value_ccy,
            h.unrealised_pnl AS unrealised_pnl_ccy,
                CASE
                    WHEN ((dc.instrument_type)::text = ANY ((ARRAY['CALL_OPTION'::character varying, 'PUT_OPTION'::character varying, 'WARRANT'::character varying])::text[])) THEN ((((h.quantity * dc.contract_multiplier) * dc.conversion_ratio) * COALESCE(dc.delta, (0)::numeric)) * COALESCE(up.px, rl.level, (0)::numeric))
                    WHEN ((dc.instrument_type)::text = 'FUTURE'::text) THEN ((h.quantity * dc.contract_multiplier) * h.market_price)
                    WHEN ((dc.instrument_type)::text = 'FX_OPTION'::text) THEN ((h.quantity * dc.contract_multiplier) * abs(COALESCE(dc.delta, (0)::numeric)))
                    WHEN ((dc.instrument_type)::text = 'FX_FORWARD'::text) THEN dc.notional_amount
                    WHEN ((dc.instrument_type)::text = 'ACCUMULATOR'::text) THEN dc.notional_amount
                    ELSE h.market_value
                END AS economic_exposure_ccy,
                CASE
                    WHEN ((s.asset_class)::text = 'FX_DERIVATIVE'::text) THEN 'FX'::text
                    WHEN (((s.asset_class)::text = 'STRUCTURED_PRODUCT'::text) AND ((dc.instrument_type)::text = 'ACCUMULATOR'::text)) THEN 'EQUITY'::text
                    WHEN ((s.asset_class)::text = 'STRUCTURED_PRODUCT'::text) THEN 'STRUCTURED'::text
                    WHEN ((s.sector)::text = 'Government Bonds'::text) THEN 'FIXED_INCOME'::text
                    WHEN (((s.sector)::text = ANY ((ARRAY['Commodities'::character varying, 'Energy'::character varying])::text[])) AND ((s.asset_class)::text = ANY ((ARRAY['ETF'::character varying, 'FUTURE'::character varying])::text[]))) THEN 'COMMODITY'::text
                    ELSE 'EQUITY'::text
                END AS exposure_class,
            (dc.security_id IS NOT NULL) AS is_complex_product,
            dc.product_risk_rating,
            dc.expiry_date AS maturity_date,
            NULL::numeric AS interest_rate_pct,
            COALESCE(d_sym.duration_years, (0)::numeric) AS duration_years
           FROM (((((public.holding h
             JOIN public.security s USING (security_id))
             LEFT JOIN public.derivative_contract dc USING (security_id))
             LEFT JOIN LATERAL ( SELECT max(h2.market_price) AS px
                   FROM (public.holding h2
                     JOIN public.security s2 USING (security_id))
                  WHERE ((s2.symbol)::text = (dc.underlying_symbol)::text)) up ON ((dc.security_id IS NOT NULL)))
             LEFT JOIN public.ref_underlying_level rl ON (((rl.underlying_symbol)::text = (dc.underlying_symbol)::text)))
             LEFT JOIN public.ref_duration_assumption d_sym ON ((((d_sym.match_kind)::text = 'SYMBOL'::text) AND ((d_sym.match_value)::text = (s.symbol)::text))))
        ), funds AS (
         SELECT f.customer_id,
            'FUND'::text AS "?column?",
            f.investment_id,
            NULL::bigint AS int8,
            NULL::character varying AS "varchar",
            f.fund_name,
            'FUND'::character varying AS "varchar",
            (f.fund_category)::character varying AS fund_category,
            NULL::character varying AS "varchar",
            NULL::character varying AS "varchar",
            f.currency,
            f.units,
            f.nav,
            f.market_value,
            f.unrealised_pnl,
            f.market_value,
                CASE f.fund_category
                    WHEN 'FIXED_INCOME'::text THEN 'FIXED_INCOME'::text
                    WHEN 'MONEY_MARKET'::text THEN 'CASH'::text
                    WHEN 'BALANCED'::text THEN 'MULTI_ASSET'::text
                    WHEN 'PRIVATE_EQUITY'::text THEN 'ALTERNATIVES'::text
                    WHEN 'HEDGE_FUND'::text THEN 'ALTERNATIVES'::text
                    ELSE 'EQUITY'::text
                END AS "case",
            ((f.fund_category)::text = ANY ((ARRAY['PRIVATE_EQUITY'::character varying, 'HEDGE_FUND'::character varying])::text[])) AS "?column?",
            (
                CASE f.fund_category
                    WHEN 'PRIVATE_EQUITY'::text THEN 5
                    WHEN 'HEDGE_FUND'::text THEN 5
                    WHEN 'EQUITY'::text THEN 4
                    WHEN 'EQUITY_INCOME'::text THEN 3
                    WHEN 'BALANCED'::text THEN 3
                    WHEN 'FIXED_INCOME'::text THEN 2
                    ELSE 1
                END)::smallint AS int2,
            NULL::date AS date,
            NULL::numeric AS "numeric",
            COALESCE(dn.duration_years, dcat.duration_years, (0)::numeric) AS "coalesce"
           FROM ((public.fund_investment f
             LEFT JOIN public.ref_duration_assumption dn ON ((((dn.match_kind)::text = 'FUND_NAME'::text) AND ((dn.match_value)::text = (f.fund_name)::text))))
             LEFT JOIN public.ref_duration_assumption dcat ON ((((dcat.match_kind)::text = 'FUND_CATEGORY'::text) AND ((dcat.match_value)::text = (f.fund_category)::text))))
        ), deposits AS (
         SELECT fd.customer_id,
            'FIXED_DEPOSIT'::text AS "?column?",
            fd.fd_id,
            NULL::bigint AS int8,
            NULL::character varying AS "varchar",
            format('FD %s %s%% to %s'::text, fd.currency, fd.interest_rate, fd.maturity_date) AS format,
            'DEPOSIT'::character varying AS "varchar",
            (fd.status)::character varying AS status,
            NULL::character varying AS "varchar",
            NULL::character varying AS "varchar",
            fd.currency,
            NULL::numeric AS "numeric",
            NULL::numeric AS "numeric",
            fd.principal,
            (0)::numeric AS "numeric",
            fd.principal,
            'DEPOSIT'::text AS "?column?",
            false AS "?column?",
            (1)::smallint AS int2,
            fd.maturity_date,
            fd.interest_rate,
            ((GREATEST((fd.maturity_date - CURRENT_DATE), 0))::numeric / 365.25) AS "?column?"
           FROM public.fixed_deposit fd
          WHERE ((fd.status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'MATURING'::character varying])::text[]))
        ), cash AS (
         SELECT a.customer_id,
            'ACCOUNT'::text AS "?column?",
            a.account_id,
            NULL::bigint AS int8,
            NULL::character varying AS "varchar",
            format('%s account %s'::text, a.account_type, a.account_number) AS format,
            'CASH'::character varying AS "varchar",
            (a.account_type)::character varying AS account_type,
            NULL::character varying AS "varchar",
            NULL::character varying AS "varchar",
            a.currency,
            NULL::numeric AS "numeric",
            NULL::numeric AS "numeric",
            a.balance,
            (0)::numeric AS "numeric",
            a.balance,
                CASE
                    WHEN (((a.account_type)::text = 'MARGIN'::text) AND (a.balance < (0)::numeric)) THEN 'MARGIN_LOAN'::text
                    ELSE 'CASH'::text
                END AS "case",
            false AS "?column?",
            (1)::smallint AS int2,
            NULL::date AS date,
            NULL::numeric AS "numeric",
            (0)::numeric AS "numeric"
           FROM public.account a
          WHERE ((a.status)::text = 'ACTIVE'::text)
        ), allpos AS (
         SELECT holdings.customer_id,
            holdings.position_source,
            holdings.source_id,
            holdings.security_id,
            holdings.symbol,
            holdings.position_name,
            holdings.asset_class,
            holdings.instrument_type,
            holdings.sector,
            holdings.country,
            holdings.currency,
            holdings.quantity,
            holdings.market_price,
            holdings.market_value_ccy,
            holdings.unrealised_pnl_ccy,
            holdings.economic_exposure_ccy,
            holdings.exposure_class,
            holdings.is_complex_product,
            holdings.product_risk_rating,
            holdings.maturity_date,
            holdings.interest_rate_pct,
            holdings.duration_years
           FROM holdings
        UNION ALL
         SELECT funds.customer_id,
            funds."?column?",
            funds.investment_id,
            funds.int8,
            funds."varchar",
            funds.fund_name,
            funds.varchar_1 AS "varchar",
            funds.fund_category,
            funds.varchar_2 AS "varchar",
            funds.varchar_3 AS "varchar",
            funds.currency,
            funds.units,
            funds.nav,
            funds.market_value,
            funds.unrealised_pnl,
            funds.market_value_1 AS market_value,
            funds."case",
            funds."?column?_1" AS "?column?",
            funds.int2,
            funds.date,
            funds."numeric",
            funds."coalesce"
           FROM funds funds(customer_id, "?column?", investment_id, int8, "varchar", fund_name, varchar_1, fund_category, varchar_2, varchar_3, currency, units, nav, market_value, unrealised_pnl, market_value_1, "case", "?column?_1", int2, date, "numeric", "coalesce")
        UNION ALL
         SELECT deposits.customer_id,
            deposits."?column?",
            deposits.fd_id,
            deposits.int8,
            deposits."varchar",
            deposits.format,
            deposits.varchar_1 AS "varchar",
            deposits.status,
            deposits.varchar_2 AS "varchar",
            deposits.varchar_3 AS "varchar",
            deposits.currency,
            deposits."numeric",
            deposits.numeric_1 AS "numeric",
            deposits.principal,
            deposits.numeric_2 AS "numeric",
            deposits.principal_1 AS principal,
            deposits."?column?_1" AS "?column?",
            deposits."?column?_2" AS "?column?",
            deposits.int2,
            deposits.maturity_date,
            deposits.interest_rate,
            deposits."?column?_3" AS "?column?"
           FROM deposits deposits(customer_id, "?column?", fd_id, int8, "varchar", format, varchar_1, status, varchar_2, varchar_3, currency, "numeric", numeric_1, principal, numeric_2, principal_1, "?column?_1", "?column?_2", int2, maturity_date, interest_rate, "?column?_3")
        UNION ALL
         SELECT cash.customer_id,
            cash."?column?",
            cash.account_id,
            cash.int8,
            cash."varchar",
            cash.format,
            cash.varchar_1 AS "varchar",
            cash.account_type,
            cash.varchar_2 AS "varchar",
            cash.varchar_3 AS "varchar",
            cash.currency,
            cash."numeric",
            cash.numeric_1 AS "numeric",
            cash.balance,
            cash.numeric_2 AS "numeric",
            cash.balance_1 AS balance,
            cash."case",
            cash."?column?_1" AS "?column?",
            cash.int2,
            cash.date,
            cash.numeric_3 AS "numeric",
            cash.numeric_4 AS "numeric"
           FROM cash cash(customer_id, "?column?", account_id, int8, "varchar", format, varchar_1, account_type, varchar_2, varchar_3, currency, "numeric", numeric_1, balance, numeric_2, balance_1, "case", "?column?_1", int2, date, numeric_3, numeric_4)
        )
 SELECT row_number() OVER (ORDER BY p.customer_id, p.position_source, p.source_id) AS position_id,
    p.customer_id,
    p.position_source,
    p.source_id,
    p.security_id,
    p.symbol,
    p.position_name,
    p.asset_class,
    p.instrument_type,
    p.sector,
    p.country,
    p.currency,
    p.quantity,
    p.market_price,
    p.exposure_class,
    p.is_complex_product,
    p.product_risk_rating,
    p.maturity_date,
    p.interest_rate_pct,
    round(p.duration_years, 2) AS duration_years,
    round(p.market_value_ccy, 2) AS market_value_ccy,
    round((p.market_value_ccy * COALESCE(fx.rate_to_sgd, (1)::numeric)), 2) AS market_value_sgd,
    round((p.unrealised_pnl_ccy * COALESCE(fx.rate_to_sgd, (1)::numeric)), 2) AS unrealised_pnl_sgd,
    round((p.economic_exposure_ccy * COALESCE(fx.rate_to_sgd, (1)::numeric)), 2) AS economic_exposure_sgd,
    (fx.rate_to_sgd IS NULL) AS fx_rate_missing
   FROM (allpos p
     LEFT JOIN fx ON ((fx.currency = p.currency)))
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW mv_position_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.mv_position_sgd IS 'Every position (holding, fund, fixed deposit, account) in SGD with economic exposure, duration and complexity. One row per position; the stable key is (position_source, source_id), not position_id.';


--
-- Name: COLUMN mv_position_sgd.position_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.position_id IS 'One row per position. position_source is HOLDING, FUND, FIXED_DEPOSIT or ACCOUNT; source_id is the primary key in that source table Caveat: position_id is a ROW_NUMBER() regenerated on every refresh -- never store or reference it across refreshes. The stable identifier is (position_source, source_id)';


--
-- Name: COLUMN mv_position_sgd.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.customer_id IS 'One row per position. position_source is HOLDING, FUND, FIXED_DEPOSIT or ACCOUNT; source_id is the primary key in that source table Caveat: position_id is a ROW_NUMBER() regenerated on every refresh -- never store or reference it across refreshes. The stable identifier is (position_source, source_id)';


--
-- Name: COLUMN mv_position_sgd.position_source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.position_source IS 'One row per position. position_source is HOLDING, FUND, FIXED_DEPOSIT or ACCOUNT; source_id is the primary key in that source table Caveat: position_id is a ROW_NUMBER() regenerated on every refresh -- never store or reference it across refreshes. The stable identifier is (position_source, source_id)';


--
-- Name: COLUMN mv_position_sgd.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.source_id IS 'One row per position. position_source is HOLDING, FUND, FIXED_DEPOSIT or ACCOUNT; source_id is the primary key in that source table Caveat: position_id is a ROW_NUMBER() regenerated on every refresh -- never store or reference it across refreshes. The stable identifier is (position_source, source_id)';


--
-- Name: COLUMN mv_position_sgd.security_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.security_id IS 'What the position is in. position_name is always populated; for deposits and accounts it is a generated description Caveat: security_id and symbol are NULL for funds, fixed deposits and cash accounts -- only HOLDING rows reference the security table';


--
-- Name: COLUMN mv_position_sgd.symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.symbol IS 'What the position is in. position_name is always populated; for deposits and accounts it is a generated description Caveat: security_id and symbol are NULL for funds, fixed deposits and cash accounts -- only HOLDING rows reference the security table';


--
-- Name: COLUMN mv_position_sgd.position_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.position_name IS 'What the position is in. position_name is always populated; for deposits and accounts it is a generated description Caveat: security_id and symbol are NULL for funds, fixed deposits and cash accounts -- only HOLDING rows reference the security table';


--
-- Name: COLUMN mv_position_sgd.asset_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.asset_class IS 'What kind of product the position is Caveat: OVERLOADED COLUMNS: instrument_type carries four unrelated domains depending on position_source, and for FIXED_DEPOSIT rows it holds a status (ACTIVE, MATURING) rather than a product type. Never filter or group on instrument_type without also constraining position_source. instrument_type is NULL for plain (non-derivative) security holdings';


--
-- Name: COLUMN mv_position_sgd.instrument_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.instrument_type IS 'What kind of product the position is Caveat: OVERLOADED COLUMNS: instrument_type carries four unrelated domains depending on position_source, and for FIXED_DEPOSIT rows it holds a status (ACTIVE, MATURING) rather than a product type. Never filter or group on instrument_type without also constraining position_source. instrument_type is NULL for plain (non-derivative) security holdings';


--
-- Name: COLUMN mv_position_sgd.sector; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.sector IS 'Sector and country of the security Caveat: NULL for funds, deposits and cash, so any sector or country aggregate silently omits fund holdings';


--
-- Name: COLUMN mv_position_sgd.country; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.country IS 'Sector and country of the security Caveat: NULL for funds, deposits and cash, so any sector or country aggregate silently omits fund holdings';


--
-- Name: COLUMN mv_position_sgd.currency; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.currency IS 'Currency the position is denominated in, and whether an FX rate was found for it Caveat: When fx_rate_missing is true a rate of 1.0 was used, so the SGD columns on that row are wrong. vw_fx_latest takes the newest rate regardless of how old it is and does not flag staleness -- check ref_fx_rate.as_of_date';


--
-- Name: COLUMN mv_position_sgd.quantity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.quantity IS 'Units held and the price per unit in the position currency Caveat: NULL for deposits and cash. Negative quantity means a short or written position';


--
-- Name: COLUMN mv_position_sgd.market_price; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.market_price IS 'Units held and the price per unit in the position currency Caveat: NULL for deposits and cash. Negative quantity means a short or written position';


--
-- Name: COLUMN mv_position_sgd.exposure_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.exposure_class IS 'The risk bucket the position is assigned to: EQUITY, FIXED_INCOME, CASH, DEPOSIT, MARGIN_LOAN, MULTI_ASSET, ALTERNATIVES, COMMODITY, STRUCTURED, FX Caveat: Corporate bonds have no dedicated rule -- a bond that is not in the Government Bonds sector lands in EQUITY. This is the single field every allocation percentage is built on';


--
-- Name: COLUMN mv_position_sgd.is_complex_product; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.is_complex_product IS 'Whether the position is a complex product and its risk rating from 1 (low) to 5 (high) Unit: boolean / 1-5. Caveat: Derived from the existence of a derivative_contract row rather than from derivative_contract.is_complex_product, which is never read. Fund ratings are assigned by category, not by any product governance process';


--
-- Name: COLUMN mv_position_sgd.product_risk_rating; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.product_risk_rating IS 'Whether the position is a complex product and its risk rating from 1 (low) to 5 (high) Unit: boolean / 1-5. Caveat: Derived from the existence of a derivative_contract row rather than from derivative_contract.is_complex_product, which is never read. Fund ratings are assigned by category, not by any product governance process';


--
-- Name: COLUMN mv_position_sgd.maturity_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.maturity_date IS 'Maturity, contractual rate and interest-rate duration Unit: date / % / years. Caveat: duration_years is 0 for anything with no duration assumption, including every equity, which is correct for rate risk but means a zero does not distinguish "no rate risk" from "not modelled"';


--
-- Name: COLUMN mv_position_sgd.interest_rate_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.interest_rate_pct IS 'Maturity, contractual rate and interest-rate duration Unit: date / % / years. Caveat: duration_years is 0 for anything with no duration assumption, including every equity, which is correct for rate risk but means a zero does not distinguish "no rate risk" from "not modelled"';


--
-- Name: COLUMN mv_position_sgd.duration_years; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.duration_years IS 'Maturity, contractual rate and interest-rate duration Unit: date / % / years. Caveat: duration_years is 0 for anything with no duration assumption, including every equity, which is correct for rate risk but means a zero does not distinguish "no rate risk" from "not modelled"';


--
-- Name: COLUMN mv_position_sgd.market_value_ccy; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.market_value_ccy IS 'Position value in its own currency and converted to SGD Unit: SGD. Caveat: For futures, FX forwards and accumulators the stored market value is mark-to-market P&L only, not size -- use economic_exposure_sgd to describe how big the position is';


--
-- Name: COLUMN mv_position_sgd.market_value_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.market_value_sgd IS 'Position value in its own currency and converted to SGD Unit: SGD. Caveat: For futures, FX forwards and accumulators the stored market value is mark-to-market P&L only, not size -- use economic_exposure_sgd to describe how big the position is';


--
-- Name: COLUMN mv_position_sgd.unrealised_pnl_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.unrealised_pnl_sgd IS 'Mark-to-market gain or loss on the position, converted to SGD Unit: SGD. Caveat: Zero by construction for deposits and cash';


--
-- Name: COLUMN mv_position_sgd.economic_exposure_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.economic_exposure_sgd IS 'How much market exposure the position really carries, as opposed to what it is worth Unit: SGD. Caveat: Deltas are static values on derivative_contract. The underlying level comes from ref_underlying_level, falling back to the highest market price of any holding in that symbol, so it is only as current as the position data';


--
-- Name: COLUMN mv_position_sgd.fx_rate_missing; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_position_sgd.fx_rate_missing IS 'Currency the position is denominated in, and whether an FX rate was found for it Caveat: When fx_rate_missing is true a rate of 1.0 was used, so the SGD columns on that row are wrong. vw_fx_latest takes the newest rate regardless of how old it is and does not flag staleness -- check ref_fx_rate.as_of_date';


--
-- Name: mv_customer_exposure; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_customer_exposure AS
 WITH p AS (
         SELECT mv_position_sgd.position_id,
            mv_position_sgd.customer_id,
            mv_position_sgd.position_source,
            mv_position_sgd.source_id,
            mv_position_sgd.security_id,
            mv_position_sgd.symbol,
            mv_position_sgd.position_name,
            mv_position_sgd.asset_class,
            mv_position_sgd.instrument_type,
            mv_position_sgd.sector,
            mv_position_sgd.country,
            mv_position_sgd.currency,
            mv_position_sgd.quantity,
            mv_position_sgd.market_price,
            mv_position_sgd.exposure_class,
            mv_position_sgd.is_complex_product,
            mv_position_sgd.product_risk_rating,
            mv_position_sgd.maturity_date,
            mv_position_sgd.interest_rate_pct,
            mv_position_sgd.duration_years,
            mv_position_sgd.market_value_ccy,
            mv_position_sgd.market_value_sgd,
            mv_position_sgd.unrealised_pnl_sgd,
            mv_position_sgd.economic_exposure_sgd,
            mv_position_sgd.fx_rate_missing
           FROM public.mv_position_sgd
        ), agg AS (
         SELECT p.customer_id,
            sum(p.market_value_sgd) AS net_value_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.market_value_sgd > (0)::numeric)) AS gross_assets_sgd,
            (- COALESCE(sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'MARGIN_LOAN'::text)), (0)::numeric)) AS margin_loan_sgd,
            sum(p.market_value_sgd) FILTER (WHERE ((p.exposure_class = 'CASH'::text) AND (p.market_value_sgd > (0)::numeric))) AS cash_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'DEPOSIT'::text)) AS deposits_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'EQUITY'::text)) AS equity_value_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'FIXED_INCOME'::text)) AS fixed_income_value_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'MULTI_ASSET'::text)) AS multi_asset_value_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'ALTERNATIVES'::text)) AS alternatives_value_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'COMMODITY'::text)) AS commodity_value_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'STRUCTURED'::text)) AS structured_value_sgd,
            sum(p.economic_exposure_sgd) FILTER (WHERE (p.exposure_class = 'EQUITY'::text)) AS equity_economic_exposure_sgd,
            sum(abs(p.economic_exposure_sgd)) FILTER (WHERE (p.exposure_class <> ALL (ARRAY['CASH'::text, 'DEPOSIT'::text, 'MARGIN_LOAN'::text]))) AS gross_risk_exposure_sgd,
            sum(abs(p.economic_exposure_sgd)) FILTER (WHERE (p.exposure_class = 'FX'::text)) AS fx_derivative_notional_sgd,
            sum(p.market_value_sgd) FILTER (WHERE ((p.currency <> 'SGD'::bpchar) AND (p.market_value_sgd > (0)::numeric))) AS foreign_ccy_assets_sgd,
            max(p.market_value_sgd) FILTER (WHERE (p.position_source = ANY (ARRAY['HOLDING'::text, 'FUND'::text]))) AS largest_position_sgd,
            count(*) FILTER (WHERE (p.position_source = ANY (ARRAY['HOLDING'::text, 'FUND'::text]))) AS num_positions,
            count(*) FILTER (WHERE p.is_complex_product) AS complex_product_count,
            COALESCE(sum(abs(p.market_value_sgd)) FILTER (WHERE p.is_complex_product), (0)::numeric) AS complex_product_value_sgd,
            max(p.product_risk_rating) AS max_product_risk_rating,
            sum(p.unrealised_pnl_sgd) AS unrealised_pnl_sgd
           FROM p
          GROUP BY p.customer_id
        ), hhi AS (
         SELECT p.customer_id,
            sum(power((p.market_value_sgd / NULLIF(a_1.gross_assets_sgd, (0)::numeric)), (2)::numeric)) AS hhi
           FROM (p
             JOIN agg a_1 USING (customer_id))
          WHERE (p.market_value_sgd > (0)::numeric)
          GROUP BY p.customer_id
        ), top AS (
         SELECT DISTINCT ON (p.customer_id) p.customer_id,
            COALESCE(p.symbol, p.position_name) AS largest_position_name
           FROM p
          WHERE (p.position_source = ANY (ARRAY['HOLDING'::text, 'FUND'::text]))
          ORDER BY p.customer_id, p.market_value_sgd DESC
        )
 SELECT a.customer_id,
    round(a.net_value_sgd, 2) AS net_value_sgd,
    round(a.gross_assets_sgd, 2) AS gross_assets_sgd,
    round(a.margin_loan_sgd, 2) AS margin_loan_sgd,
    round(COALESCE(a.cash_sgd, (0)::numeric), 2) AS cash_sgd,
    round(COALESCE(a.deposits_sgd, (0)::numeric), 2) AS deposits_sgd,
    round((((100)::numeric * COALESCE(a.equity_value_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS equity_pct,
    round((((100)::numeric * COALESCE(a.fixed_income_value_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS fixed_income_pct,
    round((((100)::numeric * (COALESCE(a.deposits_sgd, (0)::numeric) + COALESCE(a.cash_sgd, (0)::numeric))) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS cash_and_deposits_pct,
    round((((100)::numeric * COALESCE(a.multi_asset_value_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS multi_asset_pct,
    round((((100)::numeric * COALESCE(a.alternatives_value_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS alternatives_pct,
    round((((100)::numeric * COALESCE(a.commodity_value_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS commodity_pct,
    round((((100)::numeric * COALESCE(a.structured_value_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS structured_pct,
    round(COALESCE(a.equity_economic_exposure_sgd, (0)::numeric), 2) AS equity_economic_exposure_sgd,
    round((COALESCE(a.gross_risk_exposure_sgd, (0)::numeric) / NULLIF(a.net_value_sgd, (0)::numeric)), 2) AS leverage_ratio,
    round(COALESCE(a.fx_derivative_notional_sgd, (0)::numeric), 2) AS fx_derivative_notional_sgd,
    round((((100)::numeric * COALESCE(a.foreign_ccy_assets_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS foreign_currency_pct,
    t.largest_position_name,
    round((((100)::numeric * a.largest_position_sgd) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS largest_position_pct,
    round(hhi.hhi, 4) AS concentration_hhi,
    a.num_positions,
    a.complex_product_count,
    round(a.complex_product_value_sgd, 2) AS complex_product_value_sgd,
    a.max_product_risk_rating,
    round(a.unrealised_pnl_sgd, 2) AS unrealised_pnl_sgd
   FROM ((agg a
     LEFT JOIN hhi USING (customer_id))
     LEFT JOIN top t USING (customer_id))
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW mv_customer_exposure; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.mv_customer_exposure IS 'Per-customer allocation (% of gross assets), leverage, concentration and complex products, aggregated from mv_position_sgd. SGD.';


--
-- Name: COLUMN mv_customer_exposure.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.customer_id IS 'One row per customer that holds at least one position, aggregated from mv_position_sgd Caveat: A customer with no positions at all is absent here, though still present in mv_customer_360 via a left join';


--
-- Name: COLUMN mv_customer_exposure.net_value_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.net_value_sgd IS 'Total of all positions, and total of the positive positions Unit: SGD. Caveat: gross_assets_sgd is the denominator for every percentage in this view';


--
-- Name: COLUMN mv_customer_exposure.gross_assets_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.gross_assets_sgd IS 'Total of all positions, and total of the positive positions Unit: SGD. Caveat: gross_assets_sgd is the denominator for every percentage in this view';


--
-- Name: COLUMN mv_customer_exposure.margin_loan_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.margin_loan_sgd IS 'Debit balance on MARGIN accounts, reported positive Unit: SGD.';


--
-- Name: COLUMN mv_customer_exposure.cash_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.cash_sgd IS 'Positive account balances and fixed deposit principal Unit: SGD. Caveat: Deposits at principal, no accrued interest';


--
-- Name: COLUMN mv_customer_exposure.deposits_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.deposits_sgd IS 'Positive account balances and fixed deposit principal Unit: SGD. Caveat: Deposits at principal, no accrued interest';


--
-- Name: COLUMN mv_customer_exposure.equity_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.equity_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Market value, not economic exposure. The FX class has no percentage column, so these do not always sum to 100';


--
-- Name: COLUMN mv_customer_exposure.fixed_income_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.fixed_income_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Market value, not economic exposure. The FX class has no percentage column, so these do not always sum to 100';


--
-- Name: COLUMN mv_customer_exposure.cash_and_deposits_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.cash_and_deposits_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Market value, not economic exposure. The FX class has no percentage column, so these do not always sum to 100';


--
-- Name: COLUMN mv_customer_exposure.multi_asset_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.multi_asset_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Market value, not economic exposure. The FX class has no percentage column, so these do not always sum to 100';


--
-- Name: COLUMN mv_customer_exposure.alternatives_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.alternatives_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Market value, not economic exposure. The FX class has no percentage column, so these do not always sum to 100';


--
-- Name: COLUMN mv_customer_exposure.commodity_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.commodity_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Market value, not economic exposure. The FX class has no percentage column, so these do not always sum to 100';


--
-- Name: COLUMN mv_customer_exposure.structured_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.structured_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Market value, not economic exposure. The FX class has no percentage column, so these do not always sum to 100';


--
-- Name: COLUMN mv_customer_exposure.equity_economic_exposure_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.equity_economic_exposure_sgd IS 'Equity exposure with derivatives measured at economic size Unit: SGD. Caveat: Compare with equity_pct to see how much of the equity risk is derivative rather than outright';


--
-- Name: COLUMN mv_customer_exposure.leverage_ratio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.leverage_ratio IS 'Gross risk exposure against net value Unit: x. Caveat: Economic, not borrowed, leverage -- derivative notionals alone can push it above 1.5 with no loan outstanding';


--
-- Name: COLUMN mv_customer_exposure.fx_derivative_notional_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.fx_derivative_notional_sgd IS 'Total absolute notional of FX forwards and FX options Unit: SGD. Caveat: Notional, not risk: it says nothing about the direction or the hedge ratio against the customer foreign-currency assets';


--
-- Name: COLUMN mv_customer_exposure.foreign_currency_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.foreign_currency_pct IS 'Share of gross assets not denominated in SGD Unit: %. Caveat: Does not net off the FX hedges captured in fx_derivative_notional_sgd';


--
-- Name: COLUMN mv_customer_exposure.largest_position_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.largest_position_name IS 'Largest single holding or fund, and the Herfindahl index of position weights Unit: % / 0-1. Caveat: Position-level rather than issuer-level. HHI includes cash and deposits as positions, which drags it down for cash-heavy customers';


--
-- Name: COLUMN mv_customer_exposure.largest_position_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.largest_position_pct IS 'Largest single holding or fund, and the Herfindahl index of position weights Unit: % / 0-1. Caveat: Position-level rather than issuer-level. HHI includes cash and deposits as positions, which drags it down for cash-heavy customers';


--
-- Name: COLUMN mv_customer_exposure.concentration_hhi; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.concentration_hhi IS 'Largest single holding or fund, and the Herfindahl index of position weights Unit: % / 0-1. Caveat: Position-level rather than issuer-level. HHI includes cash and deposits as positions, which drags it down for cash-heavy customers';


--
-- Name: COLUMN mv_customer_exposure.num_positions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.num_positions IS 'Number of security holdings and fund investments Unit: count.';


--
-- Name: COLUMN mv_customer_exposure.complex_product_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.complex_product_count IS 'Count and absolute value of complex positions, and the highest product risk rating held Unit: count / SGD / 1-5. Caveat: Value uses absolute market value, so a written option adds to the total rather than subtracting from it';


--
-- Name: COLUMN mv_customer_exposure.complex_product_value_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.complex_product_value_sgd IS 'Count and absolute value of complex positions, and the highest product risk rating held Unit: count / SGD / 1-5. Caveat: Value uses absolute market value, so a written option adds to the total rather than subtracting from it';


--
-- Name: COLUMN mv_customer_exposure.max_product_risk_rating; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.max_product_risk_rating IS 'Count and absolute value of complex positions, and the highest product risk rating held Unit: count / SGD / 1-5. Caveat: Value uses absolute market value, so a written option adds to the total rather than subtracting from it';


--
-- Name: COLUMN mv_customer_exposure.unrealised_pnl_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_exposure.unrealised_pnl_sgd IS 'Mark-to-market gain or loss across all positions Unit: SGD. Caveat: Open positions only; realised P&L is not tracked anywhere in this database';


--
-- Name: mv_customer_behaviour; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_customer_behaviour AS
 WITH t AS (
         SELECT a_1.customer_id,
            ct.transaction_type,
            ct.product_type,
            ct.transaction_date,
            (ct.amount * COALESCE(fx.rate_to_sgd, (1)::numeric)) AS amount_sgd,
            ((ct.transaction_type)::text = ANY ((ARRAY['SECURITIES_BUY'::character varying, 'SECURITIES_SELL'::character varying, 'OPTION_BUY_TO_OPEN'::character varying, 'OPTION_SELL_TO_CLOSE'::character varying, 'OPTION_SELL_TO_OPEN'::character varying, 'OPTION_BUY_TO_CLOSE'::character varying, 'WARRANT_BUY'::character varying, 'WARRANT_SELL'::character varying, 'FUND_SUBSCRIPTION'::character varying, 'FUND_REDEMPTION'::character varying])::text[])) AS is_trade
           FROM ((public.customer_transaction ct
             JOIN public.account a_1 USING (account_id))
             LEFT JOIN public.vw_fx_latest fx ON ((fx.currency = ct.currency)))
        ), last12 AS (
         SELECT t.customer_id,
            t.transaction_type,
            t.product_type,
            t.transaction_date,
            t.amount_sgd,
            t.is_trade
           FROM t
          WHERE (t.transaction_date >= (now() - '1 year'::interval))
        ), agg AS (
         SELECT last12.customer_id,
            count(*) AS transactions_12m,
            count(*) FILTER (WHERE last12.is_trade) AS trades_12m,
            count(*) FILTER (WHERE (last12.is_trade AND ((last12.product_type)::text = 'OPTION'::text))) AS option_trades_12m,
            count(*) FILTER (WHERE (last12.is_trade AND ((last12.product_type)::text = ANY ((ARRAY['OPTION'::character varying, 'WARRANT'::character varying])::text[])))) AS leveraged_trades_12m,
            count(*) FILTER (WHERE ((last12.transaction_type)::text = 'FUTURES_VARIATION_MARGIN'::text)) AS futures_margin_events_12m,
            sum(abs(last12.amount_sgd)) FILTER (WHERE last12.is_trade) AS traded_value_12m_sgd,
            avg(abs(last12.amount_sgd)) FILTER (WHERE last12.is_trade) AS avg_trade_size_sgd,
            sum(last12.amount_sgd) FILTER (WHERE ((last12.transaction_type)::text = ANY ((ARRAY['OPTION_BUY_TO_OPEN'::character varying, 'OPTION_SELL_TO_CLOSE'::character varying, 'OPTION_SELL_TO_OPEN'::character varying, 'OPTION_BUY_TO_CLOSE'::character varying])::text[]))) AS net_option_premium_12m_sgd,
            sum(last12.amount_sgd) FILTER (WHERE ((last12.transaction_type)::text = ANY ((ARRAY['FUNDS_TRANSFER_IN'::character varying, 'FUNDS_TRANSFER_OUT'::character varying])::text[]))) AS net_transfers_12m_sgd,
            count(DISTINCT date_trunc('month'::text, last12.transaction_date)) AS active_months_12m
           FROM last12
          GROUP BY last12.customer_id
        ), lastseen AS (
         SELECT t.customer_id,
            max(t.transaction_date) AS last_transaction_at
           FROM t
          GROUP BY t.customer_id
        )
 SELECT c.customer_id,
    COALESCE(a.transactions_12m, (0)::bigint) AS transactions_12m,
    COALESCE(a.trades_12m, (0)::bigint) AS trades_12m,
    round(((COALESCE(a.trades_12m, (0)::bigint))::numeric / 12.0), 2) AS trades_per_month,
    round(((100.0 * (COALESCE(a.option_trades_12m, (0)::bigint))::numeric) / (NULLIF(a.trades_12m, 0))::numeric), 2) AS option_trade_share_pct,
    round(((100.0 * (COALESCE(a.leveraged_trades_12m, (0)::bigint))::numeric) / (NULLIF(a.trades_12m, 0))::numeric), 2) AS leveraged_trade_share_pct,
    COALESCE(a.futures_margin_events_12m, (0)::bigint) AS futures_margin_events_12m,
    round(COALESCE(a.traded_value_12m_sgd, (0)::numeric), 2) AS traded_value_12m_sgd,
    round((COALESCE(a.traded_value_12m_sgd, (0)::numeric) / NULLIF(e.gross_assets_sgd, (0)::numeric)), 2) AS turnover_ratio,
    round(COALESCE(a.avg_trade_size_sgd, (0)::numeric), 2) AS avg_trade_size_sgd,
    round(COALESCE(a.net_option_premium_12m_sgd, (0)::numeric), 2) AS net_option_premium_12m_sgd,
    round(COALESCE(a.net_transfers_12m_sgd, (0)::numeric), 2) AS net_transfers_12m_sgd,
    COALESCE(a.active_months_12m, (0)::bigint) AS active_months_12m,
    ls.last_transaction_at,
    (CURRENT_DATE - (ls.last_transaction_at)::date) AS days_since_last_transaction
   FROM (((public.customer c
     LEFT JOIN agg a USING (customer_id))
     LEFT JOIN lastseen ls USING (customer_id))
     LEFT JOIN public.mv_customer_exposure e USING (customer_id))
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW mv_customer_behaviour; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.mv_customer_behaviour IS 'Trailing-12-month trading behaviour from transactions. SGD. Rates are divided by a fixed 12 months regardless of relationship length.';


--
-- Name: COLUMN mv_customer_behaviour.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.customer_id IS 'One row per customer, covering the trailing 12 months of transactions Caveat: Every customer appears, with zeros rather than NULLs when there was no activity';


--
-- Name: COLUMN mv_customer_behaviour.transactions_12m; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.transactions_12m IS 'All transactions in the last 12 months, and the subset that are trades Unit: count. Caveat: transactions_12m includes salary credits, card payments and transfers, so it is a banking activity count and not a trading one';


--
-- Name: COLUMN mv_customer_behaviour.trades_12m; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.trades_12m IS 'All transactions in the last 12 months, and the subset that are trades Unit: count. Caveat: transactions_12m includes salary credits, card payments and transfers, so it is a banking activity count and not a trading one';


--
-- Name: COLUMN mv_customer_behaviour.trades_per_month; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.trades_per_month IS 'How often and how heavily the customer trades, and traded value against gross assets Unit: count / SGD / x. Caveat: Always divided by a fixed 12 months regardless of how long the customer has been active. turnover_ratio is NULL when gross assets are zero';


--
-- Name: COLUMN mv_customer_behaviour.option_trade_share_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.option_trade_share_pct IS 'Share of trades in options, and in options or warrants together Unit: %. Caveat: NULL, not zero, when the customer made no trades at all in the period';


--
-- Name: COLUMN mv_customer_behaviour.leveraged_trade_share_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.leveraged_trade_share_pct IS 'Share of trades in options, and in options or warrants together Unit: %. Caveat: NULL, not zero, when the customer made no trades at all in the period';


--
-- Name: COLUMN mv_customer_behaviour.futures_margin_events_12m; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.futures_margin_events_12m IS 'Count of FUTURES_VARIATION_MARGIN transactions in the last 12 months Unit: count. Caveat: A proxy for how actively futures positions are being marked and funded, not for their size';


--
-- Name: COLUMN mv_customer_behaviour.traded_value_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.traded_value_12m_sgd IS 'How often and how heavily the customer trades, and traded value against gross assets Unit: count / SGD / x. Caveat: Always divided by a fixed 12 months regardless of how long the customer has been active. turnover_ratio is NULL when gross assets are zero';


--
-- Name: COLUMN mv_customer_behaviour.turnover_ratio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.turnover_ratio IS 'How often and how heavily the customer trades, and traded value against gross assets Unit: count / SGD / x. Caveat: Always divided by a fixed 12 months regardless of how long the customer has been active. turnover_ratio is NULL when gross assets are zero';


--
-- Name: COLUMN mv_customer_behaviour.avg_trade_size_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.avg_trade_size_sgd IS 'How often and how heavily the customer trades, and traded value against gross assets Unit: count / SGD / x. Caveat: Always divided by a fixed 12 months regardless of how long the customer has been active. turnover_ratio is NULL when gross assets are zero';


--
-- Name: COLUMN mv_customer_behaviour.net_option_premium_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.net_option_premium_12m_sgd IS 'Net cash from option activity: premium received less premium paid Unit: SGD. Caveat: Positive usually means the customer is a net writer of options';


--
-- Name: COLUMN mv_customer_behaviour.net_transfers_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.net_transfers_12m_sgd IS 'Money moved in less money moved out over 12 months Unit: SGD. Caveat: Sustained negative values are the closest thing here to an outflow or attrition signal';


--
-- Name: COLUMN mv_customer_behaviour.active_months_12m; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.active_months_12m IS 'Distinct calendar months with at least one transaction in the last 12 months Unit: count. Caveat: Bounded at 12 by construction. Do not read a value of 12 as unusually active -- most customers with any regular banking reach it';


--
-- Name: COLUMN mv_customer_behaviour.last_transaction_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.last_transaction_at IS 'The most recent transaction and how long ago it was Unit: timestamp / days. Caveat: Measured over all history, not just the trailing 12 months, so it is populated even when every other column here is zero';


--
-- Name: COLUMN mv_customer_behaviour.days_since_last_transaction; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_behaviour.days_since_last_transaction IS 'The most recent transaction and how long ago it was Unit: timestamp / days. Caveat: Measured over all history, not just the trailing 12 months, so it is populated even when every other column here is zero';


--
-- Name: mv_customer_income; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_customer_income AS
 WITH t AS (
         SELECT a.customer_id,
            ct.transaction_type,
            ct.transaction_date,
            (ct.amount * COALESCE(fx.rate_to_sgd, (1)::numeric)) AS amount_sgd
           FROM ((public.customer_transaction ct
             JOIN public.account a USING (account_id))
             LEFT JOIN public.vw_fx_latest fx ON ((fx.currency = ct.currency)))
          WHERE (ct.transaction_date >= (now() - '1 year'::interval))
        ), inc AS (
         SELECT t.customer_id,
            sum(t.amount_sgd) FILTER (WHERE ((t.transaction_type)::text = 'DIVIDEND'::text)) AS dividends_12m_sgd,
            sum(t.amount_sgd) FILTER (WHERE ((t.transaction_type)::text = 'FD_INTEREST'::text)) AS fd_interest_12m_sgd,
            sum(t.amount_sgd) FILTER (WHERE ((t.transaction_type)::text = 'NOTE_COUPON'::text)) AS note_coupons_12m_sgd,
            sum(t.amount_sgd) FILTER (WHERE ((t.transaction_type)::text = 'FUND_DISTRIBUTION'::text)) AS fund_distributions_12m_sgd,
            sum(t.amount_sgd) FILTER (WHERE ((t.transaction_type)::text = ANY ((ARRAY['SALARY_CREDIT'::character varying, 'PENSION_CREDIT'::character varying, 'ALLOWANCE_CREDIT'::character varying])::text[]))) AS earned_income_12m_sgd,
            (- sum(t.amount_sgd) FILTER (WHERE ((t.transaction_type)::text = ANY ((ARRAY['CARD_PAYMENT'::character varying, 'BILL_PAYMENT'::character varying, 'ATM_WITHDRAWAL'::character varying])::text[])))) AS spending_12m_sgd
           FROM t
          GROUP BY t.customer_id
        ), ladder AS (
         SELECT mv_position_sgd.customer_id,
            sum(mv_position_sgd.market_value_sgd) FILTER (WHERE (mv_position_sgd.maturity_date <= (CURRENT_DATE + 30))) AS fd_maturing_30d_sgd,
            sum(mv_position_sgd.market_value_sgd) FILTER (WHERE (mv_position_sgd.maturity_date <= (CURRENT_DATE + 90))) AS fd_maturing_90d_sgd,
            sum(mv_position_sgd.market_value_sgd) FILTER (WHERE (mv_position_sgd.maturity_date <= (CURRENT_DATE + 180))) AS fd_maturing_180d_sgd,
            min(mv_position_sgd.maturity_date) AS next_fd_maturity_date
           FROM public.mv_position_sgd
          WHERE (mv_position_sgd.exposure_class = 'DEPOSIT'::text)
          GROUP BY mv_position_sgd.customer_id
        )
 SELECT c.customer_id,
    round(COALESCE(i.dividends_12m_sgd, (0)::numeric), 2) AS dividends_12m_sgd,
    round(COALESCE(i.fd_interest_12m_sgd, (0)::numeric), 2) AS fd_interest_12m_sgd,
    round(COALESCE(i.note_coupons_12m_sgd, (0)::numeric), 2) AS note_coupons_12m_sgd,
    round(COALESCE(i.fund_distributions_12m_sgd, (0)::numeric), 2) AS fund_distributions_12m_sgd,
    round((((COALESCE(i.dividends_12m_sgd, (0)::numeric) + COALESCE(i.fd_interest_12m_sgd, (0)::numeric)) + COALESCE(i.note_coupons_12m_sgd, (0)::numeric)) + COALESCE(i.fund_distributions_12m_sgd, (0)::numeric)), 2) AS investment_income_12m_sgd,
    round(COALESCE(i.earned_income_12m_sgd, (0)::numeric), 2) AS earned_income_12m_sgd,
    round(COALESCE(i.spending_12m_sgd, (0)::numeric), 2) AS spending_12m_sgd,
    round((COALESCE(i.spending_12m_sgd, (0)::numeric) / (12)::numeric), 2) AS avg_monthly_spending_sgd,
    round(COALESCE(l.fd_maturing_30d_sgd, (0)::numeric), 2) AS fd_maturing_30d_sgd,
    round(COALESCE(l.fd_maturing_90d_sgd, (0)::numeric), 2) AS fd_maturing_90d_sgd,
    round(COALESCE(l.fd_maturing_180d_sgd, (0)::numeric), 2) AS fd_maturing_180d_sgd,
    l.next_fd_maturity_date
   FROM ((public.customer c
     LEFT JOIN inc i USING (customer_id))
     LEFT JOIN ladder l USING (customer_id))
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW mv_customer_income; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.mv_customer_income IS 'Trailing-12-month income and spending from transactions, plus the fixed deposit maturity ladder. SGD. Cash received, not accrued.';


--
-- Name: COLUMN mv_customer_income.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.customer_id IS 'One row per customer, covering the trailing 12 months Caveat: Every customer appears, with zeros when there was no activity';


--
-- Name: COLUMN mv_customer_income.dividends_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.dividends_12m_sgd IS 'Investment income by source over the last 12 months Unit: SGD. Caveat: Cash actually received, so accrued but unpaid income is missing. Reinvested distributions may never appear as a transaction';


--
-- Name: COLUMN mv_customer_income.fd_interest_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.fd_interest_12m_sgd IS 'Investment income by source over the last 12 months Unit: SGD. Caveat: Cash actually received, so accrued but unpaid income is missing. Reinvested distributions may never appear as a transaction';


--
-- Name: COLUMN mv_customer_income.note_coupons_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.note_coupons_12m_sgd IS 'Investment income by source over the last 12 months Unit: SGD. Caveat: Cash actually received, so accrued but unpaid income is missing. Reinvested distributions may never appear as a transaction';


--
-- Name: COLUMN mv_customer_income.fund_distributions_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.fund_distributions_12m_sgd IS 'Investment income by source over the last 12 months Unit: SGD. Caveat: Cash actually received, so accrued but unpaid income is missing. Reinvested distributions may never appear as a transaction';


--
-- Name: COLUMN mv_customer_income.investment_income_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.investment_income_12m_sgd IS 'All four investment income components added together Unit: SGD. Caveat: Trailing actuals, not a forward yield. Dividing by gross assets gives a realised yield, not an expected one';


--
-- Name: COLUMN mv_customer_income.earned_income_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.earned_income_12m_sgd IS 'Salary, pension and allowance credits over 12 months Unit: SGD. Caveat: Only income paid into accounts held here, so it is a floor on what the customer actually earns';


--
-- Name: COLUMN mv_customer_income.spending_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.spending_12m_sgd IS 'Card payments, bill payments and ATM withdrawals over 12 months, and the monthly average Unit: SGD. Caveat: Only spending routed through accounts held here. Always divided by 12 even for a shorter relationship';


--
-- Name: COLUMN mv_customer_income.avg_monthly_spending_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.avg_monthly_spending_sgd IS 'Card payments, bill payments and ATM withdrawals over 12 months, and the monthly average Unit: SGD. Caveat: Only spending routed through accounts held here. Always divided by 12 even for a shorter relationship';


--
-- Name: COLUMN mv_customer_income.fd_maturing_30d_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.fd_maturing_30d_sgd IS 'Deposit principal maturing within 30, 90 and 180 days, and the next maturity date Unit: SGD / date. Caveat: Cumulative buckets. Note this view ladders to 180 days while mv_customer_rate_sensitivity ladders to 12 months';


--
-- Name: COLUMN mv_customer_income.fd_maturing_90d_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.fd_maturing_90d_sgd IS 'Deposit principal maturing within 30, 90 and 180 days, and the next maturity date Unit: SGD / date. Caveat: Cumulative buckets. Note this view ladders to 180 days while mv_customer_rate_sensitivity ladders to 12 months';


--
-- Name: COLUMN mv_customer_income.fd_maturing_180d_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.fd_maturing_180d_sgd IS 'Deposit principal maturing within 30, 90 and 180 days, and the next maturity date Unit: SGD / date. Caveat: Cumulative buckets. Note this view ladders to 180 days while mv_customer_rate_sensitivity ladders to 12 months';


--
-- Name: COLUMN mv_customer_income.next_fd_maturity_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_income.next_fd_maturity_date IS 'Deposit principal maturing within 30, 90 and 180 days, and the next maturity date Unit: SGD / date. Caveat: Cumulative buckets. Note this view ladders to 180 days while mv_customer_rate_sensitivity ladders to 12 months';


--
-- Name: ref_market_rate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_market_rate (
    currency character(3) NOT NULL,
    product character varying(30) NOT NULL,
    rate_pct numeric(6,3) NOT NULL,
    as_of_date date NOT NULL,
    source text
);


--
-- Name: TABLE ref_market_rate; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ref_market_rate IS 'Assumed current market rates by currency and product; DEPOSIT_12M drives the fixed deposit below-market comparison.';


--
-- Name: COLUMN ref_market_rate.currency; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_market_rate.currency IS 'Current market rates that customer deposit rates are compared against Unit: %. Caveat: House assumptions rather than a market feed. They drive fd_below_market_sgd and fd_opportunity_cost_12m_sgd, so changing a row here changes those metrics for every customer';


--
-- Name: COLUMN ref_market_rate.product; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_market_rate.product IS 'Current market rates that customer deposit rates are compared against Unit: %. Caveat: House assumptions rather than a market feed. They drive fd_below_market_sgd and fd_opportunity_cost_12m_sgd, so changing a row here changes those metrics for every customer';


--
-- Name: COLUMN ref_market_rate.rate_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_market_rate.rate_pct IS 'Current market rates that customer deposit rates are compared against Unit: %. Caveat: House assumptions rather than a market feed. They drive fd_below_market_sgd and fd_opportunity_cost_12m_sgd, so changing a row here changes those metrics for every customer';


--
-- Name: COLUMN ref_market_rate.as_of_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_market_rate.as_of_date IS 'Current market rates that customer deposit rates are compared against Unit: %. Caveat: House assumptions rather than a market feed. They drive fd_below_market_sgd and fd_opportunity_cost_12m_sgd, so changing a row here changes those metrics for every customer';


--
-- Name: COLUMN ref_market_rate.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_market_rate.source IS 'Current market rates that customer deposit rates are compared against Unit: %. Caveat: House assumptions rather than a market feed. They drive fd_below_market_sgd and fd_opportunity_cost_12m_sgd, so changing a row here changes those metrics for every customer';


--
-- Name: mv_customer_rate_sensitivity; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_customer_rate_sensitivity AS
 WITH p AS (
         SELECT mv_position_sgd.position_id,
            mv_position_sgd.customer_id,
            mv_position_sgd.position_source,
            mv_position_sgd.source_id,
            mv_position_sgd.security_id,
            mv_position_sgd.symbol,
            mv_position_sgd.position_name,
            mv_position_sgd.asset_class,
            mv_position_sgd.instrument_type,
            mv_position_sgd.sector,
            mv_position_sgd.country,
            mv_position_sgd.currency,
            mv_position_sgd.quantity,
            mv_position_sgd.market_price,
            mv_position_sgd.exposure_class,
            mv_position_sgd.is_complex_product,
            mv_position_sgd.product_risk_rating,
            mv_position_sgd.maturity_date,
            mv_position_sgd.interest_rate_pct,
            mv_position_sgd.duration_years,
            mv_position_sgd.market_value_ccy,
            mv_position_sgd.market_value_sgd,
            mv_position_sgd.unrealised_pnl_sgd,
            mv_position_sgd.economic_exposure_sgd,
            mv_position_sgd.fx_rate_missing
           FROM public.mv_position_sgd
        ), mkt AS (
         SELECT ref_market_rate.currency,
            ref_market_rate.rate_pct
           FROM public.ref_market_rate
          WHERE ((ref_market_rate.product)::text = 'DEPOSIT_12M'::text)
        ), agg AS (
         SELECT p.customer_id,
            sum(p.market_value_sgd) FILTER (WHERE ((p.duration_years > (0)::numeric) AND (p.exposure_class <> 'DEPOSIT'::text))) AS bond_like_value_sgd,
            sum((p.market_value_sgd * p.duration_years)) FILTER (WHERE (p.exposure_class <> 'DEPOSIT'::text)) AS dollar_duration,
            sum(p.market_value_sgd) FILTER (WHERE ((p.exposure_class = 'CASH'::text) AND (p.market_value_sgd > (0)::numeric))) AS floating_cash_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'DEPOSIT'::text)) AS fd_total_sgd,
            sum(p.market_value_sgd) FILTER (WHERE ((p.exposure_class = 'DEPOSIT'::text) AND (p.maturity_date <= (CURRENT_DATE + 90)))) AS fd_maturing_90d_sgd,
            sum(p.market_value_sgd) FILTER (WHERE ((p.exposure_class = 'DEPOSIT'::text) AND (p.maturity_date <= (CURRENT_DATE + 365)))) AS fd_maturing_12m_sgd,
            sum((p.market_value_sgd * GREATEST((0)::numeric, ((1)::numeric - p.duration_years)))) FILTER (WHERE (p.exposure_class = 'DEPOSIT'::text)) AS fd_repricing_weighted_sgd,
            (sum((p.market_value_sgd * p.interest_rate_pct)) FILTER (WHERE (p.exposure_class = 'DEPOSIT'::text)) / NULLIF(sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'DEPOSIT'::text)), (0)::numeric)) AS fd_weighted_rate_pct,
            sum(p.market_value_sgd) FILTER (WHERE ((p.exposure_class = 'DEPOSIT'::text) AND (p.interest_rate_pct < m.rate_pct))) AS fd_below_market_sgd,
            sum((((p.market_value_sgd * (m.rate_pct - p.interest_rate_pct)) / (100)::numeric) * LEAST(p.duration_years, (1)::numeric))) FILTER (WHERE ((p.exposure_class = 'DEPOSIT'::text) AND (p.interest_rate_pct < m.rate_pct))) AS fd_opportunity_cost_12m_sgd,
            (- sum(p.market_value_sgd) FILTER (WHERE (p.exposure_class = 'MARGIN_LOAN'::text))) AS margin_loan_sgd,
            sum(p.economic_exposure_sgd) FILTER (WHERE ((p.exposure_class = 'EQUITY'::text) AND ((p.sector)::text = 'Technology'::text))) AS tech_equity_exposure_sgd,
            sum(p.market_value_sgd) FILTER (WHERE ((p.exposure_class = 'EQUITY'::text) AND ((p.sector)::text = 'Financials'::text))) AS bank_equity_value_sgd,
            sum(p.market_value_sgd) FILTER (WHERE (p.market_value_sgd > (0)::numeric)) AS gross_assets_sgd,
            sum(p.market_value_sgd) AS net_value_sgd
           FROM (p
             LEFT JOIN mkt m ON ((m.currency = p.currency)))
          GROUP BY p.customer_id
        ), mm AS (
         SELECT mv_position_sgd.customer_id,
            sum(mv_position_sgd.market_value_sgd) AS mm_sgd
           FROM public.mv_position_sgd
          WHERE ((mv_position_sgd.position_source = 'FUND'::text) AND ((mv_position_sgd.instrument_type)::text = 'MONEY_MARKET'::text))
          GROUP BY mv_position_sgd.customer_id
        )
 SELECT a.customer_id,
    round(COALESCE(a.bond_like_value_sgd, (0)::numeric), 2) AS bond_like_value_sgd,
    round((COALESCE(a.dollar_duration, (0)::numeric) / NULLIF(a.bond_like_value_sgd, (0)::numeric)), 2) AS bond_weighted_duration,
    round((COALESCE(a.dollar_duration, (0)::numeric) * 0.0001), 2) AS dv01_sgd,
    round(((- COALESCE(a.dollar_duration, (0)::numeric)) * 0.0025), 2) AS bond_pnl_plus25bp_sgd,
    round(((- COALESCE(a.dollar_duration, (0)::numeric)) * 0.0100), 2) AS bond_pnl_plus100bp_sgd,
    round((COALESCE(a.floating_cash_sgd, (0)::numeric) + COALESCE(mm.mm_sgd, (0)::numeric)), 2) AS floating_cash_sgd,
    round(COALESCE(a.fd_total_sgd, (0)::numeric), 2) AS fd_total_sgd,
    round(COALESCE(a.fd_maturing_90d_sgd, (0)::numeric), 2) AS fd_maturing_90d_sgd,
    round(COALESCE(a.fd_maturing_12m_sgd, (0)::numeric), 2) AS fd_maturing_12m_sgd,
    round(a.fd_weighted_rate_pct, 3) AS fd_weighted_rate_pct,
    round(COALESCE(a.fd_below_market_sgd, (0)::numeric), 2) AS fd_below_market_sgd,
    round(COALESCE(a.fd_opportunity_cost_12m_sgd, (0)::numeric), 2) AS fd_opportunity_cost_12m_sgd,
    round((((COALESCE(a.floating_cash_sgd, (0)::numeric) + COALESCE(mm.mm_sgd, (0)::numeric)) + COALESCE(a.fd_repricing_weighted_sgd, (0)::numeric)) * 0.0025), 2) AS income_gain_plus25bp_12m_sgd,
    round(((- COALESCE(a.margin_loan_sgd, (0)::numeric)) * 0.0025), 2) AS margin_cost_plus25bp_12m_sgd,
    round(COALESCE(a.tech_equity_exposure_sgd, (0)::numeric), 2) AS tech_equity_exposure_sgd,
    round(COALESCE(a.bank_equity_value_sgd, (0)::numeric), 2) AS bank_equity_value_sgd,
    round(((((- COALESCE(a.dollar_duration, (0)::numeric)) * 0.0025) + (((COALESCE(a.floating_cash_sgd, (0)::numeric) + COALESCE(mm.mm_sgd, (0)::numeric)) + COALESCE(a.fd_repricing_weighted_sgd, (0)::numeric)) * 0.0025)) - (COALESCE(a.margin_loan_sgd, (0)::numeric) * 0.0025)), 2) AS net_impact_plus25bp_sgd,
    round((((100)::numeric * ((((- COALESCE(a.dollar_duration, (0)::numeric)) * 0.0025) + (((COALESCE(a.floating_cash_sgd, (0)::numeric) + COALESCE(mm.mm_sgd, (0)::numeric)) + COALESCE(a.fd_repricing_weighted_sgd, (0)::numeric)) * 0.0025)) - (COALESCE(a.margin_loan_sgd, (0)::numeric) * 0.0025))) / NULLIF(a.net_value_sgd, (0)::numeric)), 3) AS net_impact_plus25bp_pct,
    round((((100)::numeric * COALESCE(a.tech_equity_exposure_sgd, (0)::numeric)) / NULLIF(a.gross_assets_sgd, (0)::numeric)), 2) AS tech_equity_exposure_pct
   FROM (agg a
     LEFT JOIN mm USING (customer_id))
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW mv_customer_rate_sensitivity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.mv_customer_rate_sensitivity IS 'Per-customer interest-rate sensitivity: bond duration, DV01, +25bp/+100bp impact, deposit repricing and opportunity cost. SGD. Durations are assumptions from ref_duration_assumption; equity and credit effects are not modelled.';


--
-- Name: COLUMN mv_customer_rate_sensitivity.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.customer_id IS 'One row per customer holding positions, measuring interest-rate sensitivity';


--
-- Name: COLUMN mv_customer_rate_sensitivity.bond_like_value_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.bond_like_value_sgd IS 'Value of positions carrying interest-rate duration, and their value-weighted average duration Unit: SGD / years. Caveat: Bond-like means "has a duration assumption in ref_duration_assumption", which includes bond funds and bond ETFs. Fixed deposits are deliberately excluded and handled through the repricing columns instead';


--
-- Name: COLUMN mv_customer_rate_sensitivity.bond_weighted_duration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.bond_weighted_duration IS 'Value of positions carrying interest-rate duration, and their value-weighted average duration Unit: SGD / years. Caveat: Bond-like means "has a duration assumption in ref_duration_assumption", which includes bond funds and bond ETFs. Fixed deposits are deliberately excluded and handled through the repricing columns instead';


--
-- Name: COLUMN mv_customer_rate_sensitivity.dv01_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.dv01_sgd IS 'Change in bond-like value for a 1bp move in yields Unit: SGD. Caveat: Reported as a positive size; a yield rise is a loss of this amount';


--
-- Name: COLUMN mv_customer_rate_sensitivity.bond_pnl_plus25bp_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.bond_pnl_plus25bp_sgd IS 'Estimated mark-to-market change on bond-like holdings for a 25bp and a 100bp rise in yields Unit: SGD. Caveat: First-order duration approximation with no convexity, so it overstates the loss on a large move. Assumes a parallel shift across all currencies and credits';


--
-- Name: COLUMN mv_customer_rate_sensitivity.bond_pnl_plus100bp_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.bond_pnl_plus100bp_sgd IS 'Estimated mark-to-market change on bond-like holdings for a 25bp and a 100bp rise in yields Unit: SGD. Caveat: First-order duration approximation with no convexity, so it overstates the loss on a large move. Assumes a parallel shift across all currencies and credits';


--
-- Name: COLUMN mv_customer_rate_sensitivity.floating_cash_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.floating_cash_sgd IS 'Cash and money-market fund balances that reprice immediately when rates move Unit: SGD. Caveat: Money-market funds are identified by instrument_type = ''MONEY_MARKET'', which only works because that column carries fund_category for fund rows -- see the Product classification entry on mv_position_sgd';


--
-- Name: COLUMN mv_customer_rate_sensitivity.fd_total_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.fd_total_sgd IS 'Total deposit principal, and how much of it matures and can be reinvested within 90 days and 12 months Unit: SGD. Caveat: Cumulative. The shorter the ladder, the faster the customer benefits from a rate rise';


--
-- Name: COLUMN mv_customer_rate_sensitivity.fd_maturing_90d_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.fd_maturing_90d_sgd IS 'Total deposit principal, and how much of it matures and can be reinvested within 90 days and 12 months Unit: SGD. Caveat: Cumulative. The shorter the ladder, the faster the customer benefits from a rate rise';


--
-- Name: COLUMN mv_customer_rate_sensitivity.fd_maturing_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.fd_maturing_12m_sgd IS 'Total deposit principal, and how much of it matures and can be reinvested within 90 days and 12 months Unit: SGD. Caveat: Cumulative. The shorter the ladder, the faster the customer benefits from a rate rise';


--
-- Name: COLUMN mv_customer_rate_sensitivity.fd_weighted_rate_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.fd_weighted_rate_pct IS 'Principal-weighted average contractual rate across the customer fixed deposits Unit: %. Caveat: Blends currencies, so an SGD and a USD deposit are averaged together despite facing different rate curves';


--
-- Name: COLUMN mv_customer_rate_sensitivity.fd_below_market_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.fd_below_market_sgd IS 'Deposits locked below the current market rate, and the interest forgone over the next 12 months Unit: SGD. Caveat: Market rates live in ref_market_rate and the USD rate is a house assumption. Ignores any break cost, so it is the gross prize, not the net one';


--
-- Name: COLUMN mv_customer_rate_sensitivity.fd_opportunity_cost_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.fd_opportunity_cost_12m_sgd IS 'Deposits locked below the current market rate, and the interest forgone over the next 12 months Unit: SGD. Caveat: Market rates live in ref_market_rate and the USD rate is a house assumption. Ignores any break cost, so it is the gross prize, not the net one';


--
-- Name: COLUMN mv_customer_rate_sensitivity.income_gain_plus25bp_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.income_gain_plus25bp_12m_sgd IS 'Extra interest over 12 months from a 25bp rise, on cash, money-market funds and deposits that reprice within the year Unit: SGD. Caveat: Assumes the full 25bp is passed through to deposit rates immediately, which is generous';


--
-- Name: COLUMN mv_customer_rate_sensitivity.margin_cost_plus25bp_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.margin_cost_plus25bp_12m_sgd IS 'Extra margin interest over 12 months from a 25bp rise Unit: SGD. Caveat: Assumes the loan balance stays constant for the full year';


--
-- Name: COLUMN mv_customer_rate_sensitivity.tech_equity_exposure_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.tech_equity_exposure_sgd IS 'Delta-adjusted equity exposure to the Technology sector, in SGD and as a share of gross assets Unit: SGD / %. Caveat: Carried here as the rate-sensitive equity proxy: long-duration growth equity tends to fall when yields rise, but that link is not modelled numerically anywhere. Technology held inside funds is not counted';


--
-- Name: COLUMN mv_customer_rate_sensitivity.bank_equity_value_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.bank_equity_value_sgd IS 'Market value of equity holdings in the Financials sector Unit: SGD. Caveat: The counterweight to tech exposure: banks often gain from higher rates. Market value, not delta-adjusted';


--
-- Name: COLUMN mv_customer_rate_sensitivity.net_impact_plus25bp_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.net_impact_plus25bp_sgd IS 'Bond mark-to-market change plus extra interest income minus extra margin cost, for a 25bp rise, in SGD and as a share of net value Unit: SGD / %. Caveat: Negative means the customer is hurt. Mixes a one-off mark-to-market change with a 12-month income flow, so read it as a direction and a rough size rather than a P&L. Equity and credit effects are not modelled';


--
-- Name: COLUMN mv_customer_rate_sensitivity.net_impact_plus25bp_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.net_impact_plus25bp_pct IS 'Bond mark-to-market change plus extra interest income minus extra margin cost, for a 25bp rise, in SGD and as a share of net value Unit: SGD / %. Caveat: Negative means the customer is hurt. Mixes a one-off mark-to-market change with a 12-month income flow, so read it as a direction and a rough size rather than a P&L. Equity and credit effects are not modelled';


--
-- Name: COLUMN mv_customer_rate_sensitivity.tech_equity_exposure_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_rate_sensitivity.tech_equity_exposure_pct IS 'Delta-adjusted equity exposure to the Technology sector, in SGD and as a share of gross assets Unit: SGD / %. Caveat: Carried here as the rate-sensitive equity proxy: long-duration growth equity tends to fall when yields rise, but that link is not modelled numerically anywhere. Technology held inside funds is not counted';


--
-- Name: vw_dim_customer; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_dim_customer AS
 SELECT c.customer_id,
    c.customer_number,
    c.customer_segment,
    c.customer_since,
    c.status,
    cp.full_name,
    cp.date_of_birth,
    cp.gender,
    cp.marital_status,
    cp.occupation,
    cp.employer,
    cp.annual_income,
    cp.net_worth,
    cp.nationality,
    cp.tax_residency,
    cp.country,
    cp.email,
    cp.mobile_number,
    cp.preferred_language,
    EXTRACT(year FROM age((cp.date_of_birth)::timestamp with time zone)) AS age,
    EXTRACT(year FROM age((c.customer_since)::timestamp with time zone)) AS years_as_customer,
    c.created_at
   FROM (public.customer c
     LEFT JOIN public.customer_profile cp ON ((c.customer_id = cp.customer_id)));


--
-- Name: VIEW vw_dim_customer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_dim_customer IS 'Customer profile and demographics. Carries no derived amounts, so unlike the other vw_* views it has no currency problem.';


--
-- Name: COLUMN vw_dim_customer.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.customer_id IS 'Customer record and relationship status Caveat: The only object in the layer that carries no derived amounts, so it has none of the currency problems of the other vw_fact_* views';


--
-- Name: COLUMN vw_dim_customer.customer_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.customer_number IS 'Customer record and relationship status Caveat: The only object in the layer that carries no derived amounts, so it has none of the currency problems of the other vw_fact_* views';


--
-- Name: COLUMN vw_dim_customer.customer_segment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.customer_segment IS 'Customer record and relationship status Caveat: The only object in the layer that carries no derived amounts, so it has none of the currency problems of the other vw_fact_* views';


--
-- Name: COLUMN vw_dim_customer.customer_since; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.customer_since IS 'Customer record and relationship status Caveat: The only object in the layer that carries no derived amounts, so it has none of the currency problems of the other vw_fact_* views';


--
-- Name: COLUMN vw_dim_customer.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.status IS 'Customer record and relationship status Caveat: The only object in the layer that carries no derived amounts, so it has none of the currency problems of the other vw_fact_* views';


--
-- Name: COLUMN vw_dim_customer.full_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.full_name IS 'Identity and residency attributes, including tax residency for compliance questions';


--
-- Name: COLUMN vw_dim_customer.date_of_birth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.date_of_birth IS 'Age and relationship length in completed years Unit: years.';


--
-- Name: COLUMN vw_dim_customer.gender; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.gender IS 'Identity and residency attributes, including tax residency for compliance questions';


--
-- Name: COLUMN vw_dim_customer.marital_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.marital_status IS 'Identity and residency attributes, including tax residency for compliance questions';


--
-- Name: COLUMN vw_dim_customer.occupation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.occupation IS 'Employment and self-declared financial standing Unit: SGD. Caveat: Declared at onboarding and never revalued';


--
-- Name: COLUMN vw_dim_customer.employer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.employer IS 'Employment and self-declared financial standing Unit: SGD. Caveat: Declared at onboarding and never revalued';


--
-- Name: COLUMN vw_dim_customer.annual_income; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.annual_income IS 'Employment and self-declared financial standing Unit: SGD. Caveat: Declared at onboarding and never revalued';


--
-- Name: COLUMN vw_dim_customer.net_worth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.net_worth IS 'Employment and self-declared financial standing Unit: SGD. Caveat: Declared at onboarding and never revalued';


--
-- Name: COLUMN vw_dim_customer.nationality; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.nationality IS 'Identity and residency attributes, including tax residency for compliance questions';


--
-- Name: COLUMN vw_dim_customer.tax_residency; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.tax_residency IS 'Identity and residency attributes, including tax residency for compliance questions';


--
-- Name: COLUMN vw_dim_customer.country; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.country IS 'Identity and residency attributes, including tax residency for compliance questions';


--
-- Name: COLUMN vw_dim_customer.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.email IS 'How the customer is contacted Caveat: Personal contact data: use for servicing questions, not for analysis, and do not include in aggregate output';


--
-- Name: COLUMN vw_dim_customer.mobile_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.mobile_number IS 'How the customer is contacted Caveat: Personal contact data: use for servicing questions, not for analysis, and do not include in aggregate output';


--
-- Name: COLUMN vw_dim_customer.preferred_language; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.preferred_language IS 'How the customer is contacted Caveat: Personal contact data: use for servicing questions, not for analysis, and do not include in aggregate output';


--
-- Name: COLUMN vw_dim_customer.age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.age IS 'Age and relationship length in completed years Unit: years.';


--
-- Name: COLUMN vw_dim_customer.years_as_customer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.years_as_customer IS 'Age and relationship length in completed years Unit: years.';


--
-- Name: COLUMN vw_dim_customer.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_dim_customer.created_at IS 'Customer record and relationship status Caveat: The only object in the layer that carries no derived amounts, so it has none of the currency problems of the other vw_fact_* views';


--
-- Name: vw_fact_customer_wealth; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_fact_customer_wealth AS
 WITH holdings_value AS (
         SELECT holding.customer_id,
            sum(holding.market_value) AS equity_value,
            count(DISTINCT holding.security_id) AS num_equity_holdings,
            max(holding.as_of_date) AS as_of_date
           FROM public.holding
          WHERE (holding.market_value IS NOT NULL)
          GROUP BY holding.customer_id
        ), funds_value AS (
         SELECT fund_investment.customer_id,
            sum(fund_investment.market_value) AS fund_value,
            count(DISTINCT fund_investment.fund_name) AS num_funds,
            max(fund_investment.as_of_date) AS as_of_date
           FROM public.fund_investment
          WHERE (fund_investment.market_value IS NOT NULL)
          GROUP BY fund_investment.customer_id
        ), deposits_value AS (
         SELECT fixed_deposit.customer_id,
            sum(fixed_deposit.principal) AS fixed_deposit_value,
            count(*) AS num_fixed_deposits,
            max(fixed_deposit.maturity_date) AS latest_fd_maturity
           FROM public.fixed_deposit
          WHERE ((fixed_deposit.status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'MATURING'::character varying])::text[]))
          GROUP BY fixed_deposit.customer_id
        ), cash_balance AS (
         SELECT account.customer_id,
            sum(account.balance) AS cash_balance,
            count(*) AS num_accounts,
            max(account.opened_date) AS latest_account_opened
           FROM public.account
          WHERE ((account.status)::text = 'ACTIVE'::text)
          GROUP BY account.customer_id
        )
 SELECT c.customer_id,
    c.customer_number,
    c.customer_segment,
    COALESCE(cb.cash_balance, (0)::numeric) AS cash_balance,
    COALESCE(hv.equity_value, (0)::numeric) AS equity_value,
    COALESCE(fv.fund_value, (0)::numeric) AS fund_value,
    COALESCE(dv.fixed_deposit_value, (0)::numeric) AS fixed_deposit_value,
    (((COALESCE(cb.cash_balance, (0)::numeric) + COALESCE(hv.equity_value, (0)::numeric)) + COALESCE(fv.fund_value, (0)::numeric)) + COALESCE(dv.fixed_deposit_value, (0)::numeric)) AS total_portfolio_value,
    COALESCE(hv.num_equity_holdings, (0)::bigint) AS num_equity_holdings,
    COALESCE(fv.num_funds, (0)::bigint) AS num_funds,
    COALESCE(dv.num_fixed_deposits, (0)::bigint) AS num_fixed_deposits,
    COALESCE(cb.num_accounts, (0)::bigint) AS num_accounts,
    round(
        CASE
            WHEN ((((COALESCE(cb.cash_balance, (0)::numeric) + COALESCE(hv.equity_value, (0)::numeric)) + COALESCE(fv.fund_value, (0)::numeric)) + COALESCE(dv.fixed_deposit_value, (0)::numeric)) > (0)::numeric) THEN ((100.0 * COALESCE(cb.cash_balance, (0)::numeric)) / (((COALESCE(cb.cash_balance, (0)::numeric) + COALESCE(hv.equity_value, (0)::numeric)) + COALESCE(fv.fund_value, (0)::numeric)) + COALESCE(dv.fixed_deposit_value, (0)::numeric)))
            ELSE (0)::numeric
        END, 2) AS liquidity_ratio,
    COALESCE(cp.net_worth, (0)::numeric) AS net_worth_profile,
    COALESCE(cp.annual_income, (0)::numeric) AS annual_income,
    GREATEST(hv.as_of_date, fv.as_of_date, dv.latest_fd_maturity, cb.latest_account_opened) AS last_updated
   FROM (((((public.customer c
     LEFT JOIN cash_balance cb ON ((c.customer_id = cb.customer_id)))
     LEFT JOIN holdings_value hv ON ((c.customer_id = hv.customer_id)))
     LEFT JOIN funds_value fv ON ((c.customer_id = fv.customer_id)))
     LEFT JOIN deposits_value dv ON ((c.customer_id = dv.customer_id)))
     LEFT JOIN public.customer_profile cp ON ((c.customer_id = cp.customer_id)))
  WHERE ((c.status)::text = 'ACTIVE'::text);


--
-- Name: VIEW vw_fact_customer_wealth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_fact_customer_wealth IS 'LEGACY. Portfolio totals per ACTIVE customer. Adds SGD and USD without conversion, folds negative margin balances into cash_balance, and counts every security holding as equity. Totals understate mv_customer_360.gross_assets_sgd by 4-40%. Use mv_customer_360.';


--
-- Name: COLUMN vw_fact_customer_wealth.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.customer_id IS 'Customer keys carried from the customer table Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_fact_customer_wealth.customer_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.customer_number IS 'Customer keys carried from the customer table Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_fact_customer_wealth.customer_segment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.customer_segment IS 'Customer keys carried from the customer table Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_fact_customer_wealth.cash_balance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.cash_balance IS 'Legacy portfolio totals by product type Unit: mixed SGD and USD. Caveat: DO NOT USE FOR TOTALS. Three faults: SGD and USD amounts are added without conversion, understating totals by 4% to 40% against mv_customer_360.gross_assets_sgd; negative MARGIN account balances are folded into cash_balance, which can make it negative; and equity_value is every security holding, including options, futures, warrants, structured products and bond ETFs. fixed_deposit_value covers deposits only and misses bond funds and bond ETFs entirely. Use mv_customer_360 instead';


--
-- Name: COLUMN vw_fact_customer_wealth.equity_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.equity_value IS 'Legacy portfolio totals by product type Unit: mixed SGD and USD. Caveat: DO NOT USE FOR TOTALS. Three faults: SGD and USD amounts are added without conversion, understating totals by 4% to 40% against mv_customer_360.gross_assets_sgd; negative MARGIN account balances are folded into cash_balance, which can make it negative; and equity_value is every security holding, including options, futures, warrants, structured products and bond ETFs. fixed_deposit_value covers deposits only and misses bond funds and bond ETFs entirely. Use mv_customer_360 instead';


--
-- Name: COLUMN vw_fact_customer_wealth.fund_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.fund_value IS 'Legacy portfolio totals by product type Unit: mixed SGD and USD. Caveat: DO NOT USE FOR TOTALS. Three faults: SGD and USD amounts are added without conversion, understating totals by 4% to 40% against mv_customer_360.gross_assets_sgd; negative MARGIN account balances are folded into cash_balance, which can make it negative; and equity_value is every security holding, including options, futures, warrants, structured products and bond ETFs. fixed_deposit_value covers deposits only and misses bond funds and bond ETFs entirely. Use mv_customer_360 instead';


--
-- Name: COLUMN vw_fact_customer_wealth.fixed_deposit_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.fixed_deposit_value IS 'Legacy portfolio totals by product type Unit: mixed SGD and USD. Caveat: DO NOT USE FOR TOTALS. Three faults: SGD and USD amounts are added without conversion, understating totals by 4% to 40% against mv_customer_360.gross_assets_sgd; negative MARGIN account balances are folded into cash_balance, which can make it negative; and equity_value is every security holding, including options, futures, warrants, structured products and bond ETFs. fixed_deposit_value covers deposits only and misses bond funds and bond ETFs entirely. Use mv_customer_360 instead';


--
-- Name: COLUMN vw_fact_customer_wealth.total_portfolio_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.total_portfolio_value IS 'Legacy portfolio totals by product type Unit: mixed SGD and USD. Caveat: DO NOT USE FOR TOTALS. Three faults: SGD and USD amounts are added without conversion, understating totals by 4% to 40% against mv_customer_360.gross_assets_sgd; negative MARGIN account balances are folded into cash_balance, which can make it negative; and equity_value is every security holding, including options, futures, warrants, structured products and bond ETFs. fixed_deposit_value covers deposits only and misses bond funds and bond ETFs entirely. Use mv_customer_360 instead';


--
-- Name: COLUMN vw_fact_customer_wealth.num_equity_holdings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.num_equity_holdings IS 'Number of positions by product type Unit: count. Caveat: Counts are unaffected by the currency problem and are safe to use';


--
-- Name: COLUMN vw_fact_customer_wealth.num_funds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.num_funds IS 'Number of positions by product type Unit: count. Caveat: Counts are unaffected by the currency problem and are safe to use';


--
-- Name: COLUMN vw_fact_customer_wealth.num_fixed_deposits; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.num_fixed_deposits IS 'Number of positions by product type Unit: count. Caveat: Counts are unaffected by the currency problem and are safe to use';


--
-- Name: COLUMN vw_fact_customer_wealth.num_accounts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.num_accounts IS 'Number of positions by product type Unit: count. Caveat: Counts are unaffected by the currency problem and are safe to use';


--
-- Name: COLUMN vw_fact_customer_wealth.liquidity_ratio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.liquidity_ratio IS 'Cash as a percentage of the legacy portfolio total Unit: %. Caveat: Inherits both faults above: it goes negative for customers with a margin loan, and the denominator mixes currencies';


--
-- Name: COLUMN vw_fact_customer_wealth.net_worth_profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.net_worth_profile IS 'Self-declared net worth and income copied from customer_profile Unit: SGD. Caveat: Declared values, unrelated to the computed portfolio columns beside them';


--
-- Name: COLUMN vw_fact_customer_wealth.annual_income; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.annual_income IS 'Self-declared net worth and income copied from customer_profile Unit: SGD. Caveat: Declared values, unrelated to the computed portfolio columns beside them';


--
-- Name: COLUMN vw_fact_customer_wealth.last_updated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_customer_wealth.last_updated IS 'Latest of the source as-of dates behind the row Unit: date. Caveat: Mixes a price as-of date with an FD maturity date and an account opening date, so it is not a meaningful freshness stamp';


--
-- Name: vw_fact_risk_profile; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_fact_risk_profile AS
 WITH h AS (
         SELECT holding.customer_id,
            sum(holding.market_value) AS equity_value,
            max(holding.market_value) AS largest_position,
            count(DISTINCT holding.security_id) AS n_securities,
            sum(holding.unrealised_pnl) AS pnl
           FROM public.holding
          GROUP BY holding.customer_id
        ), f AS (
         SELECT fund_investment.customer_id,
            sum(fund_investment.market_value) AS fund_value,
            count(DISTINCT fund_investment.fund_name) AS n_funds,
            sum(fund_investment.unrealised_pnl) AS pnl
           FROM public.fund_investment
          GROUP BY fund_investment.customer_id
        ), fd AS (
         SELECT fixed_deposit.customer_id,
            sum(fixed_deposit.principal) AS fd_value
           FROM public.fixed_deposit
          WHERE ((fixed_deposit.status)::text = ANY (ARRAY['ACTIVE'::text, 'MATURING'::text]))
          GROUP BY fixed_deposit.customer_id
        ), a AS (
         SELECT account.customer_id,
            sum(account.balance) AS cash_value
           FROM public.account
          WHERE ((account.status)::text = 'ACTIVE'::text)
          GROUP BY account.customer_id
        ), portfolio_composition AS (
         SELECT c_1.customer_id,
            COALESCE(h.equity_value, (0)::numeric) AS equity_value,
            COALESCE(f.fund_value, (0)::numeric) AS fund_value,
            COALESCE(fd.fd_value, (0)::numeric) AS fd_value,
            NULLIF((((COALESCE(h.equity_value, (0)::numeric) + COALESCE(f.fund_value, (0)::numeric)) + COALESCE(fd.fd_value, (0)::numeric)) + COALESCE(a.cash_value, (0)::numeric)), (0)::numeric) AS total_value,
            COALESCE(h.largest_position, (0)::numeric) AS largest_position,
            (COALESCE(h.n_securities, (0)::bigint) + COALESCE(f.n_funds, (0)::bigint)) AS total_holdings,
            round((COALESCE(h.pnl, (0)::numeric) + COALESCE(f.pnl, (0)::numeric)), 2) AS unrealised_pnl
           FROM ((((public.customer c_1
             LEFT JOIN h ON ((h.customer_id = c_1.customer_id)))
             LEFT JOIN f ON ((f.customer_id = c_1.customer_id)))
             LEFT JOIN fd ON ((fd.customer_id = c_1.customer_id)))
             LEFT JOIN a ON ((a.customer_id = c_1.customer_id)))
          WHERE ((c_1.status)::text = 'ACTIVE'::text)
        ), pct AS (
         SELECT portfolio_composition.customer_id,
            round(((100.0 * portfolio_composition.equity_value) / portfolio_composition.total_value), 2) AS equity_pct,
            round(((100.0 * portfolio_composition.fund_value) / portfolio_composition.total_value), 2) AS fund_pct,
            round(((100.0 * portfolio_composition.fd_value) / portfolio_composition.total_value), 2) AS fixed_income_pct,
            round(((100.0 * portfolio_composition.largest_position) / portfolio_composition.total_value), 2) AS concentration_pct,
            portfolio_composition.total_holdings,
            portfolio_composition.unrealised_pnl
           FROM portfolio_composition
        )
 SELECT c.customer_id,
    c.customer_number,
    pc.equity_pct,
    pc.fund_pct,
    pc.fixed_income_pct,
    pc.concentration_pct,
    pc.total_holdings,
    pc.unrealised_pnl,
        CASE
            WHEN (pc.equity_pct > (70)::numeric) THEN 'AGGRESSIVE'::text
            WHEN ((pc.equity_pct >= (40)::numeric) AND (pc.equity_pct <= (70)::numeric)) THEN 'MODERATE'::text
            WHEN (pc.equity_pct < (40)::numeric) THEN 'CONSERVATIVE'::text
            ELSE 'UNKNOWN'::text
        END AS risk_profile,
        CASE
            WHEN (pc.concentration_pct > (25)::numeric) THEN 'HIGH'::text
            WHEN (pc.concentration_pct > (15)::numeric) THEN 'MEDIUM'::text
            ELSE 'LOW'::text
        END AS concentration_risk,
    round((
        CASE
            WHEN (pc.total_holdings >= 20) THEN (100)::bigint
            WHEN (pc.total_holdings >= 10) THEN (80)::bigint
            WHEN (pc.total_holdings >= 5) THEN (60)::bigint
            ELSE GREATEST((pc.total_holdings * 10), (0)::bigint)
        END)::numeric, 0) AS diversification_score
   FROM (public.customer c
     LEFT JOIN pct pc ON ((pc.customer_id = c.customer_id)))
  WHERE ((c.status)::text = 'ACTIVE'::text);


--
-- Name: VIEW vw_fact_risk_profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_fact_risk_profile IS 'LEGACY. Risk labels computed on unconverted amounts with derivatives counted as equity; its equity_pct is not mv_customer_360.equity_pct and concentration ignores funds. Source of risk_profile and concentration_risk in mv_customer_360.';


--
-- Name: COLUMN vw_fact_risk_profile.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.customer_id IS 'Customer keys Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_fact_risk_profile.customer_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.customer_number IS 'Customer keys Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_fact_risk_profile.equity_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.equity_pct IS 'Legacy allocation percentages Unit: %. Caveat: Computed on unconverted amounts and counts every security holding as equity, so these differ materially from mv_customer_360.equity_pct -- by more than 40 points for some customers. fixed_income_pct is deposits only. Use mv_customer_360';


--
-- Name: COLUMN vw_fact_risk_profile.fund_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.fund_pct IS 'Legacy allocation percentages Unit: %. Caveat: Computed on unconverted amounts and counts every security holding as equity, so these differ materially from mv_customer_360.equity_pct -- by more than 40 points for some customers. fixed_income_pct is deposits only. Use mv_customer_360';


--
-- Name: COLUMN vw_fact_risk_profile.fixed_income_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.fixed_income_pct IS 'Legacy allocation percentages Unit: %. Caveat: Computed on unconverted amounts and counts every security holding as equity, so these differ materially from mv_customer_360.equity_pct -- by more than 40 points for some customers. fixed_income_pct is deposits only. Use mv_customer_360';


--
-- Name: COLUMN vw_fact_risk_profile.concentration_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.concentration_pct IS 'Largest security holding as a share of the legacy total Unit: %. Caveat: Ignores fund investments, so a customer whose biggest position is a fund is understated. Use mv_customer_360.largest_position_pct';


--
-- Name: COLUMN vw_fact_risk_profile.total_holdings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.total_holdings IS 'Number of positions and a 0-100 score derived from it Unit: count / 0-100. Caveat: Counts positions and ignores their weights entirely, so ten positions with 90% in one of them still scores 80. Use concentration_hhi for a weight-aware measure';


--
-- Name: COLUMN vw_fact_risk_profile.unrealised_pnl; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.unrealised_pnl IS 'Mark-to-market P&L across holdings and funds Unit: mixed SGD and USD. Caveat: Currencies added without conversion. Use mv_customer_360.unrealised_pnl_sgd';


--
-- Name: COLUMN vw_fact_risk_profile.risk_profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.risk_profile IS 'AGGRESSIVE / MODERATE / CONSERVATIVE, and LOW / MEDIUM / HIGH concentration Unit: text. Caveat: The thresholds are reasonable but the inputs are the unconverted percentages above, so the labels are unreliable and are the source of the same columns in mv_customer_360';


--
-- Name: COLUMN vw_fact_risk_profile.concentration_risk; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.concentration_risk IS 'AGGRESSIVE / MODERATE / CONSERVATIVE, and LOW / MEDIUM / HIGH concentration Unit: text. Caveat: The thresholds are reasonable but the inputs are the unconverted percentages above, so the labels are unreliable and are the source of the same columns in mv_customer_360';


--
-- Name: COLUMN vw_fact_risk_profile.diversification_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_risk_profile.diversification_score IS 'Number of positions and a 0-100 score derived from it Unit: count / 0-100. Caveat: Counts positions and ignores their weights entirely, so ten positions with 90% in one of them still scores 80. Use concentration_hhi for a weight-aware measure';


--
-- Name: vw_investor_profile; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_investor_profile AS
 WITH activity_metrics AS (
         SELECT c_1.customer_id,
            (count(DISTINCT date_trunc('month'::text, ct.transaction_date)) FILTER (WHERE (ct.transaction_date >= (date_trunc('month'::text, now()) - '11 mons'::interval))))::numeric AS avg_active_months_per_year,
            (count(ct.transaction_id))::integer AS total_trade_transactions
           FROM ((public.customer c_1
             LEFT JOIN public.account a ON ((c_1.customer_id = a.customer_id)))
             LEFT JOIN public.customer_transaction ct ON ((a.account_id = ct.account_id)))
          WHERE ((c_1.status)::text = 'ACTIVE'::text)
          GROUP BY c_1.customer_id
        ), holding_metrics AS (
         SELECT h.customer_id,
            (count(*))::integer AS num_holdings,
            (avg(EXTRACT(day FROM (now() - (( SELECT min(a2.opened_date) AS min
                   FROM public.account a2
                  WHERE (a2.customer_id = h.customer_id)))::timestamp with time zone))))::integer AS avg_holding_days,
            ((((sum(
                CASE
                    WHEN (h.unrealised_pnl > (0)::numeric) THEN 1
                    ELSE 0
                END))::numeric / NULLIF((count(*))::numeric, (0)::numeric)) * (100)::numeric))::numeric(6,2) AS win_rate_pct,
            (((sum(h.unrealised_pnl) / NULLIF(sum(h.market_value), (0)::numeric)) * (100)::numeric))::numeric(8,2) AS pnl_percentage
           FROM public.holding h
          GROUP BY h.customer_id
        )
 SELECT c.customer_id,
    c.customer_number,
    c.customer_segment,
    dc.full_name,
    dc.age,
    dc.years_as_customer,
    w.total_portfolio_value,
    w.equity_value,
    w.fund_value,
    w.fixed_deposit_value,
    w.cash_balance,
    (((100.0 * w.equity_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) AS equity_pct,
    (((100.0 * w.fund_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) AS fund_pct,
    (((100.0 * w.fixed_deposit_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) AS fixed_income_pct,
    hm.num_holdings,
    hm.avg_holding_days,
    hm.win_rate_pct,
    hm.pnl_percentage,
    (am.avg_active_months_per_year)::numeric(6,2) AS avg_active_months_per_year,
    rp.risk_profile,
    rp.concentration_risk,
    rp.diversification_score,
        CASE
            WHEN (((((100.0 * w.equity_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) > (70)::numeric) AND (am.avg_active_months_per_year >= (8)::numeric) AND (hm.num_holdings < 10)) THEN 'ACTIVE_TRADER'::text
            WHEN (((((100.0 * w.equity_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) > (70)::numeric) AND (COALESCE(hm.avg_holding_days, 0) > 1825)) THEN 'GROWTH_INVESTOR'::text
            WHEN (((((100.0 * w.fixed_deposit_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) > (40)::numeric) AND (COALESCE(hm.win_rate_pct, (0)::numeric) > (70)::numeric)) THEN 'INCOME_INVESTOR'::text
            WHEN ((((100.0 * w.equity_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) < (30)::numeric) THEN 'CONSERVATIVE_INVESTOR'::text
            WHEN (((((100.0 * w.equity_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) >= (30)::numeric) AND ((((100.0 * w.equity_value) / NULLIF(w.total_portfolio_value, (0)::numeric)))::numeric(6,2) <= (70)::numeric)) THEN 'BALANCED_INVESTOR'::text
            ELSE 'UNCLASSIFIED'::text
        END AS investor_type,
    (LEAST(1.0, ((((COALESCE(hm.num_holdings, 1))::numeric / (15)::numeric) * (LEAST(COALESCE(am.avg_active_months_per_year, (0)::numeric), (12)::numeric) / (12)::numeric)) *
        CASE
            WHEN (w.total_portfolio_value > (100000)::numeric) THEN 1.0
            ELSE 0.5
        END)))::numeric(3,2) AS classification_confidence
   FROM (((((public.customer c
     LEFT JOIN public.vw_dim_customer dc ON ((c.customer_id = dc.customer_id)))
     LEFT JOIN public.vw_fact_customer_wealth w ON ((c.customer_id = w.customer_id)))
     LEFT JOIN public.vw_fact_risk_profile rp ON ((c.customer_id = rp.customer_id)))
     LEFT JOIN holding_metrics hm ON ((c.customer_id = hm.customer_id)))
     LEFT JOIN activity_metrics am ON ((c.customer_id = am.customer_id)))
  WHERE ((c.status)::text = 'ACTIVE'::text);


--
-- Name: VIEW vw_investor_profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_investor_profile IS 'LEGACY. Rule-based investor_type. avg_holding_days is the age of the oldest account rather than a holding period, avg_active_months_per_year is 12.00 for every customer, and the allocation inputs are unconverted. Source of investor_type in mv_customer_360.';


--
-- Name: COLUMN vw_investor_profile.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.customer_id IS 'Customer keys and profile attributes joined in from vw_dim_customer Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_investor_profile.customer_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.customer_number IS 'Customer keys and profile attributes joined in from vw_dim_customer Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_investor_profile.customer_segment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.customer_segment IS 'Customer keys and profile attributes joined in from vw_dim_customer Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_investor_profile.full_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.full_name IS 'Customer keys and profile attributes joined in from vw_dim_customer Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_investor_profile.age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.age IS 'Customer keys and profile attributes joined in from vw_dim_customer Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_investor_profile.years_as_customer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.years_as_customer IS 'Customer keys and profile attributes joined in from vw_dim_customer Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_investor_profile.total_portfolio_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.total_portfolio_value IS 'Portfolio totals carried in from vw_fact_customer_wealth Unit: mixed SGD and USD. Caveat: Inherits the currency and margin faults of that view. Use mv_customer_360';


--
-- Name: COLUMN vw_investor_profile.equity_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.equity_value IS 'Portfolio totals carried in from vw_fact_customer_wealth Unit: mixed SGD and USD. Caveat: Inherits the currency and margin faults of that view. Use mv_customer_360';


--
-- Name: COLUMN vw_investor_profile.fund_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.fund_value IS 'Portfolio totals carried in from vw_fact_customer_wealth Unit: mixed SGD and USD. Caveat: Inherits the currency and margin faults of that view. Use mv_customer_360';


--
-- Name: COLUMN vw_investor_profile.fixed_deposit_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.fixed_deposit_value IS 'Portfolio totals carried in from vw_fact_customer_wealth Unit: mixed SGD and USD. Caveat: Inherits the currency and margin faults of that view. Use mv_customer_360';


--
-- Name: COLUMN vw_investor_profile.cash_balance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.cash_balance IS 'Portfolio totals carried in from vw_fact_customer_wealth Unit: mixed SGD and USD. Caveat: Inherits the currency and margin faults of that view. Use mv_customer_360';


--
-- Name: COLUMN vw_investor_profile.equity_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.equity_pct IS 'Allocation percentages recomputed from the legacy totals Unit: %. Caveat: Same basis as vw_fact_risk_profile and materially different from mv_customer_360.equity_pct';


--
-- Name: COLUMN vw_investor_profile.fund_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.fund_pct IS 'Allocation percentages recomputed from the legacy totals Unit: %. Caveat: Same basis as vw_fact_risk_profile and materially different from mv_customer_360.equity_pct';


--
-- Name: COLUMN vw_investor_profile.fixed_income_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.fixed_income_pct IS 'Allocation percentages recomputed from the legacy totals Unit: %. Caveat: Same basis as vw_fact_risk_profile and materially different from mv_customer_360.equity_pct';


--
-- Name: COLUMN vw_investor_profile.num_holdings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.num_holdings IS 'Number of security holdings Unit: count. Caveat: Security holdings only -- fund investments are not counted, although fund_value is in the totals above';


--
-- Name: COLUMN vw_investor_profile.avg_holding_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.avg_holding_days IS 'Intended as how long the customer holds positions Unit: days. Caveat: DOES NOT MEASURE WHAT THE NAME SAYS. There is no purchase date on holding, so this is the age of the customer oldest account and is identical for every position they hold, reaching 30 years for long-standing customers. It drives the GROWTH_INVESTOR rule, whose 1825-day threshold is therefore met by almost anyone. Do not quote it';


--
-- Name: COLUMN vw_investor_profile.win_rate_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.win_rate_pct IS 'Share of holdings showing a gain, and P&L as a percentage of market value Unit: %. Caveat: Open positions only and unweighted by size. pnl_percentage divides by market value rather than cost, so it differs from mv_customer_360.unrealised_return_pct';


--
-- Name: COLUMN vw_investor_profile.pnl_percentage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.pnl_percentage IS 'Share of holdings showing a gain, and P&L as a percentage of market value Unit: %. Caveat: Open positions only and unweighted by size. pnl_percentage divides by market value rather than cost, so it differs from mv_customer_360.unrealised_return_pct';


--
-- Name: COLUMN vw_investor_profile.avg_active_months_per_year; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.avg_active_months_per_year IS 'Intended as how many months a year the customer is active Unit: count. Caveat: DEGENERATE: it evaluates to 12.00 for every customer in the database, so the ACTIVE_TRADER rule that requires at least 8 is always satisfied and investor_type is decided by allocation and holding count alone. Use mv_customer_behaviour.active_months_12m';


--
-- Name: COLUMN vw_investor_profile.risk_profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.risk_profile IS 'Risk labels joined in from vw_fact_risk_profile Unit: text / 0-100. Caveat: Carries the same limitations as the source view';


--
-- Name: COLUMN vw_investor_profile.concentration_risk; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.concentration_risk IS 'Risk labels joined in from vw_fact_risk_profile Unit: text / 0-100. Caveat: Carries the same limitations as the source view';


--
-- Name: COLUMN vw_investor_profile.diversification_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.diversification_score IS 'Risk labels joined in from vw_fact_risk_profile Unit: text / 0-100. Caveat: Carries the same limitations as the source view';


--
-- Name: COLUMN vw_investor_profile.investor_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.investor_type IS 'Rule-based classification: ACTIVE_TRADER (equity above 70% with at least 8 active months and fewer than 10 holdings), GROWTH_INVESTOR (equity above 70% held over 5 years), INCOME_INVESTOR (deposits above 40% with a win rate over 70%), CONSERVATIVE_INVESTOR (equity below 30%), BALANCED_INVESTOR (equity 30-70%), or UNCLASSIFIED Unit: text / 0-1. Caveat: Every input is compromised: equity percentage is unconverted and counts derivatives, the activity term is always 12, and the holding period is the account age. Observed confidence runs from 0.07 to 0.60, so the > 0.7 filter suggested in SEMANTIC_LAYER_SUMMARY.md returns nothing. Treat the label as a weak hint and state the underlying numbers instead';


--
-- Name: COLUMN vw_investor_profile.classification_confidence; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_investor_profile.classification_confidence IS 'Rule-based classification: ACTIVE_TRADER (equity above 70% with at least 8 active months and fewer than 10 holdings), GROWTH_INVESTOR (equity above 70% held over 5 years), INCOME_INVESTOR (deposits above 40% with a win rate over 70%), CONSERVATIVE_INVESTOR (equity below 30%), BALANCED_INVESTOR (equity 30-70%), or UNCLASSIFIED Unit: text / 0-1. Caveat: Every input is compromised: equity percentage is unconverted and counts derivatives, the activity term is always 12, and the holding period is the account age. Observed confidence runs from 0.07 to 0.60, so the > 0.7 filter suggested in SEMANTIC_LAYER_SUMMARY.md returns nothing. Treat the label as a weak hint and state the underlying numbers instead';


--
-- Name: mv_customer_360; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_customer_360 AS
 WITH base AS (
         SELECT d.customer_id,
            d.customer_number,
            d.full_name,
            d.status,
            d.customer_segment,
            (d.age)::integer AS age,
            d.gender,
            d.marital_status,
            d.nationality,
            d.country AS residence_country,
            d.occupation,
            d.employer,
            (d.years_as_customer)::integer AS years_as_customer,
            cp.annual_income,
            cp.net_worth AS declared_net_worth,
                CASE
                    WHEN (d.age < (30)::numeric) THEN 'UNDER_30'::text
                    WHEN (d.age < (40)::numeric) THEN '30-39'::text
                    WHEN (d.age < (50)::numeric) THEN '40-49'::text
                    WHEN (d.age < (60)::numeric) THEN '50-59'::text
                    WHEN (d.age < (70)::numeric) THEN '60-69'::text
                    ELSE '70_PLUS'::text
                END AS age_band
           FROM (public.vw_dim_customer d
             JOIN public.customer_profile cp USING (customer_id))
        ), j AS (
         SELECT b.customer_id,
            b.customer_number,
            b.full_name,
            b.status,
            b.customer_segment,
            b.age,
            b.gender,
            b.marital_status,
            b.nationality,
            b.residence_country,
            b.occupation,
            b.employer,
            b.years_as_customer,
            b.annual_income,
            b.declared_net_worth,
            b.age_band,
            e.net_value_sgd,
            e.gross_assets_sgd,
            e.margin_loan_sgd,
            e.cash_sgd,
            e.deposits_sgd,
            e.equity_pct,
            e.fixed_income_pct,
            e.cash_and_deposits_pct,
            e.multi_asset_pct,
            e.alternatives_pct,
            e.commodity_pct,
            e.structured_pct,
            e.equity_economic_exposure_sgd,
            e.leverage_ratio,
            e.foreign_currency_pct,
            e.largest_position_name,
            e.largest_position_pct,
            e.concentration_hhi,
            e.num_positions,
            e.complex_product_count,
            e.complex_product_value_sgd,
            e.max_product_risk_rating,
            e.unrealised_pnl_sgd,
            round((((100)::numeric * e.unrealised_pnl_sgd) / NULLIF((e.gross_assets_sgd - e.unrealised_pnl_sgd), (0)::numeric)), 2) AS unrealised_return_pct,
            r.bond_weighted_duration,
            r.dv01_sgd,
            r.bond_pnl_plus100bp_sgd,
            r.fd_maturing_12m_sgd,
            r.fd_below_market_sgd,
            r.income_gain_plus25bp_12m_sgd,
            r.net_impact_plus25bp_sgd,
            r.net_impact_plus25bp_pct,
            r.tech_equity_exposure_pct,
            i.investment_income_12m_sgd,
            i.earned_income_12m_sgd,
            i.avg_monthly_spending_sgd,
            i.fd_maturing_30d_sgd,
            i.fd_maturing_90d_sgd,
            i.next_fd_maturity_date,
            bh.trades_per_month,
            bh.option_trade_share_pct,
            bh.turnover_ratio,
            bh.net_option_premium_12m_sgd,
            bh.days_since_last_transaction,
            ip.investor_type,
            ip.classification_confidence,
            rp.risk_profile,
            rp.concentration_risk,
            GREATEST(0, LEAST(100, (110 - b.age))) AS target_growth_pct,
            seg.segment_name AS ml_segment,
            COALESCE(an.anomaly_count_90d, (0)::bigint) AS ml_anomalies_90d
           FROM ((((((((base b
             LEFT JOIN public.mv_customer_exposure e USING (customer_id))
             LEFT JOIN public.mv_customer_rate_sensitivity r USING (customer_id))
             LEFT JOIN public.mv_customer_income i USING (customer_id))
             LEFT JOIN public.mv_customer_behaviour bh USING (customer_id))
             LEFT JOIN public.vw_investor_profile ip USING (customer_id))
             LEFT JOIN public.vw_fact_risk_profile rp USING (customer_id))
             LEFT JOIN public.ml_customer_segment seg USING (customer_id))
             LEFT JOIN ( SELECT ml_transaction_anomaly.customer_id,
                    count(*) AS anomaly_count_90d
                   FROM public.ml_transaction_anomaly
                  WHERE (ml_transaction_anomaly.transaction_date >= (now() - '90 days'::interval))
                  GROUP BY ml_transaction_anomaly.customer_id) an USING (customer_id))
        )
 SELECT customer_id,
    customer_number,
    full_name,
    status,
    customer_segment,
    age,
    gender,
    marital_status,
    nationality,
    residence_country,
    occupation,
    employer,
    years_as_customer,
    annual_income,
    declared_net_worth,
    age_band,
    net_value_sgd,
    gross_assets_sgd,
    margin_loan_sgd,
    cash_sgd,
    deposits_sgd,
    equity_pct,
    fixed_income_pct,
    cash_and_deposits_pct,
    multi_asset_pct,
    alternatives_pct,
    commodity_pct,
    structured_pct,
    equity_economic_exposure_sgd,
    leverage_ratio,
    foreign_currency_pct,
    largest_position_name,
    largest_position_pct,
    concentration_hhi,
    num_positions,
    complex_product_count,
    complex_product_value_sgd,
    max_product_risk_rating,
    unrealised_pnl_sgd,
    unrealised_return_pct,
    bond_weighted_duration,
    dv01_sgd,
    bond_pnl_plus100bp_sgd,
    fd_maturing_12m_sgd,
    fd_below_market_sgd,
    income_gain_plus25bp_12m_sgd,
    net_impact_plus25bp_sgd,
    net_impact_plus25bp_pct,
    tech_equity_exposure_pct,
    investment_income_12m_sgd,
    earned_income_12m_sgd,
    avg_monthly_spending_sgd,
    fd_maturing_30d_sgd,
    fd_maturing_90d_sgd,
    next_fd_maturity_date,
    trades_per_month,
    option_trade_share_pct,
    turnover_ratio,
    net_option_premium_12m_sgd,
    days_since_last_transaction,
    investor_type,
    classification_confidence,
    risk_profile,
    concentration_risk,
    target_growth_pct,
    ml_segment,
    ml_anomalies_90d,
    round(((((COALESCE(equity_pct, (0)::numeric) + COALESCE(alternatives_pct, (0)::numeric)) + COALESCE(structured_pct, (0)::numeric)) + (0.5 * COALESCE(multi_asset_pct, (0)::numeric))) - (target_growth_pct)::numeric), 2) AS growth_vs_age_target_pct,
    round(((percent_rank() OVER (PARTITION BY age_band ORDER BY net_value_sgd NULLS FIRST))::numeric * (100)::numeric), 1) AS wealth_percentile_in_age_band,
    round(((percent_rank() OVER (PARTITION BY age_band ORDER BY unrealised_return_pct NULLS FIRST))::numeric * (100)::numeric), 1) AS return_percentile_in_age_band,
    rank() OVER (ORDER BY net_impact_plus25bp_sgd) AS rate_hike_impact_rank,
    array_remove(ARRAY[
        CASE
            WHEN ((age >= 65) AND (max_product_risk_rating >= 4) AND (complex_product_count > 0)) THEN 'COMPLEX_PRODUCT_AGE_65_PLUS'::text
            ELSE NULL::text
        END,
        CASE
            WHEN (largest_position_pct > (25)::numeric) THEN 'SINGLE_POSITION_OVER_25PCT'::text
            ELSE NULL::text
        END,
        CASE
            WHEN ((margin_loan_sgd > (0)::numeric) OR (leverage_ratio > 1.5)) THEN 'LEVERAGED'::text
            ELSE NULL::text
        END,
        CASE
            WHEN ((avg_monthly_spending_sgd > (0)::numeric) AND ((COALESCE(cash_sgd, (0)::numeric) + COALESCE(fd_maturing_90d_sgd, (0)::numeric)) < ((6)::numeric * avg_monthly_spending_sgd))) THEN 'LOW_LIQUIDITY_UNDER_6M_SPEND'::text
            ELSE NULL::text
        END,
        CASE
            WHEN ((age >= 60) AND (COALESCE(equity_pct, (0)::numeric) > ((GREATEST(0, (110 - age)) + 20))::numeric)) THEN 'EQUITY_HEAVY_FOR_AGE'::text
            ELSE NULL::text
        END,
        CASE
            WHEN ((COALESCE(option_trade_share_pct, (0)::numeric) > (40)::numeric) AND (gross_assets_sgd < (250000)::numeric)) THEN 'SPECULATIVE_TRADING_SMALL_PORTFOLIO'::text
            ELSE NULL::text
        END,
        CASE
            WHEN (fd_maturing_30d_sgd > (0)::numeric) THEN 'FD_MATURING_30D'::text
            ELSE NULL::text
        END,
        CASE
            WHEN (net_impact_plus25bp_pct < '-0.10'::numeric) THEN 'RATE_HIKE_SENSITIVE'::text
            ELSE NULL::text
        END,
        CASE
            WHEN ((status)::text <> 'ACTIVE'::text) THEN 'NOT_ACTIVE'::text
            ELSE NULL::text
        END,
        CASE
            WHEN (ml_anomalies_90d > 0) THEN 'ML_UNUSUAL_ACTIVITY'::text
            ELSE NULL::text
        END], NULL::text) AS suitability_flags,
    now() AS refreshed_at
   FROM j
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW mv_customer_360; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.mv_customer_360 IS 'One row per customer (all statuses). Start here. All amounts in SGD using ref_fx_rate. investor_type, classification_confidence, risk_profile and concentration_risk are carried in from the legacy vw_* views and are computed on a different, unconverted basis than the other columns -- see metric_catalog.';


--
-- Name: COLUMN mv_customer_360.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.customer_id IS 'Who the row is about. customer_id is the join key to every other object in the layer Caveat: One row per customer of ANY status, including DORMANT. The vw_fact_* views filter to status = ''ACTIVE'' and therefore return one customer fewer';


--
-- Name: COLUMN mv_customer_360.customer_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.customer_number IS 'Who the row is about. customer_id is the join key to every other object in the layer Caveat: One row per customer of ANY status, including DORMANT. The vw_fact_* views filter to status = ''ACTIVE'' and therefore return one customer fewer';


--
-- Name: COLUMN mv_customer_360.full_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.full_name IS 'Who the row is about. customer_id is the join key to every other object in the layer Caveat: One row per customer of ANY status, including DORMANT. The vw_fact_* views filter to status = ''ACTIVE'' and therefore return one customer fewer';


--
-- Name: COLUMN mv_customer_360.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.status IS 'Who the row is about. customer_id is the join key to every other object in the layer Caveat: One row per customer of ANY status, including DORMANT. The vw_fact_* views filter to status = ''ACTIVE'' and therefore return one customer fewer';


--
-- Name: COLUMN mv_customer_360.customer_segment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.customer_segment IS 'Who the row is about. customer_id is the join key to every other object in the layer Caveat: One row per customer of ANY status, including DORMANT. The vw_fact_* views filter to status = ''ACTIVE'' and therefore return one customer fewer';


--
-- Name: COLUMN mv_customer_360.age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.age IS 'Age in completed years and the age band used for peer comparisons and for matching a life-stage model portfolio Unit: years. Caveat: age_band drives wealth_percentile_in_age_band, return_percentile_in_age_band and vw_customer_model_gap';


--
-- Name: COLUMN mv_customer_360.gender; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.gender IS 'Age in completed years and the age band used for peer comparisons and for matching a life-stage model portfolio Unit: years. Caveat: age_band drives wealth_percentile_in_age_band, return_percentile_in_age_band and vw_customer_model_gap';


--
-- Name: COLUMN mv_customer_360.marital_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.marital_status IS 'Age in completed years and the age band used for peer comparisons and for matching a life-stage model portfolio Unit: years. Caveat: age_band drives wealth_percentile_in_age_band, return_percentile_in_age_band and vw_customer_model_gap';


--
-- Name: COLUMN mv_customer_360.nationality; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.nationality IS 'Age in completed years and the age band used for peer comparisons and for matching a life-stage model portfolio Unit: years. Caveat: age_band drives wealth_percentile_in_age_band, return_percentile_in_age_band and vw_customer_model_gap';


--
-- Name: COLUMN mv_customer_360.residence_country; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.residence_country IS 'Age in completed years and the age band used for peer comparisons and for matching a life-stage model portfolio Unit: years. Caveat: age_band drives wealth_percentile_in_age_band, return_percentile_in_age_band and vw_customer_model_gap';


--
-- Name: COLUMN mv_customer_360.occupation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.occupation IS 'Stated occupation and employer from customer_profile';


--
-- Name: COLUMN mv_customer_360.employer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.employer IS 'Stated occupation and employer from customer_profile';


--
-- Name: COLUMN mv_customer_360.years_as_customer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.years_as_customer IS 'Completed years since the relationship opened Unit: years.';


--
-- Name: COLUMN mv_customer_360.annual_income; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.annual_income IS 'Income and net worth as declared by the customer on the profile record Unit: SGD. Caveat: Self-declared at onboarding, never revalued and not reconciled against holdings. Use net_value_sgd for what the customer actually holds here; declared_net_worth may include assets held elsewhere';


--
-- Name: COLUMN mv_customer_360.declared_net_worth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.declared_net_worth IS 'Income and net worth as declared by the customer on the profile record Unit: SGD. Caveat: Self-declared at onboarding, never revalued and not reconciled against holdings. Use net_value_sgd for what the customer actually holds here; declared_net_worth may include assets held elsewhere';


--
-- Name: COLUMN mv_customer_360.age_band; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.age_band IS 'Age in completed years and the age band used for peer comparisons and for matching a life-stage model portfolio Unit: years. Caveat: age_band drives wealth_percentile_in_age_band, return_percentile_in_age_band and vw_customer_model_gap';


--
-- Name: COLUMN mv_customer_360.net_value_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.net_value_sgd IS 'Everything the customer holds with the bank minus margin borrowing and short option liabilities Unit: SGD. Caveat: USD converted at ref_fx_rate. Can be far below gross_assets_sgd for a leveraged customer';


--
-- Name: COLUMN mv_customer_360.gross_assets_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.gross_assets_sgd IS 'Sum of the positive positions; the denominator of every allocation percentage in this row Unit: SGD. Caveat: Excludes margin loans and short option liabilities, so gross exceeds net whenever the customer borrows';


--
-- Name: COLUMN mv_customer_360.margin_loan_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.margin_loan_sgd IS 'Debit balance on MARGIN accounts, reported as a positive number Unit: SGD. Caveat: Zero for customers with no margin facility. Any non-zero value raises the LEVERAGED suitability flag';


--
-- Name: COLUMN mv_customer_360.cash_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.cash_sgd IS 'Credit balances on bank accounts, and the principal of fixed deposits with status ACTIVE or MATURING Unit: SGD. Caveat: Deposits are stated at principal; accrued interest is not included. Negative margin balances are excluded from cash_sgd and reported in margin_loan_sgd';


--
-- Name: COLUMN mv_customer_360.deposits_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.deposits_sgd IS 'Credit balances on bank accounts, and the principal of fixed deposits with status ACTIVE or MATURING Unit: SGD. Caveat: Deposits are stated at principal; accrued interest is not included. Negative margin balances are excluded from cash_sgd and reported in margin_loan_sgd';


--
-- Name: COLUMN mv_customer_360.equity_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.equity_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Balanced funds sit in MULTI_ASSET and are not split into equity and bonds. Equity here is market value, not delta-adjusted exposure -- see equity_economic_exposure_sgd. Does not sum to 100 when a position falls in the FX class';


--
-- Name: COLUMN mv_customer_360.fixed_income_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.fixed_income_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Balanced funds sit in MULTI_ASSET and are not split into equity and bonds. Equity here is market value, not delta-adjusted exposure -- see equity_economic_exposure_sgd. Does not sum to 100 when a position falls in the FX class';


--
-- Name: COLUMN mv_customer_360.cash_and_deposits_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.cash_and_deposits_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Balanced funds sit in MULTI_ASSET and are not split into equity and bonds. Equity here is market value, not delta-adjusted exposure -- see equity_economic_exposure_sgd. Does not sum to 100 when a position falls in the FX class';


--
-- Name: COLUMN mv_customer_360.multi_asset_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.multi_asset_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Balanced funds sit in MULTI_ASSET and are not split into equity and bonds. Equity here is market value, not delta-adjusted exposure -- see equity_economic_exposure_sgd. Does not sum to 100 when a position falls in the FX class';


--
-- Name: COLUMN mv_customer_360.alternatives_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.alternatives_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Balanced funds sit in MULTI_ASSET and are not split into equity and bonds. Equity here is market value, not delta-adjusted exposure -- see equity_economic_exposure_sgd. Does not sum to 100 when a position falls in the FX class';


--
-- Name: COLUMN mv_customer_360.commodity_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.commodity_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Balanced funds sit in MULTI_ASSET and are not split into equity and bonds. Equity here is market value, not delta-adjusted exposure -- see equity_economic_exposure_sgd. Does not sum to 100 when a position falls in the FX class';


--
-- Name: COLUMN mv_customer_360.structured_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.structured_pct IS 'Share of gross assets by exposure class Unit: %. Caveat: Balanced funds sit in MULTI_ASSET and are not split into equity and bonds. Equity here is market value, not delta-adjusted exposure -- see equity_economic_exposure_sgd. Does not sum to 100 when a position falls in the FX class';


--
-- Name: COLUMN mv_customer_360.equity_economic_exposure_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.equity_economic_exposure_sgd IS 'Equity exposure including derivatives measured at their economic size rather than their market value Unit: SGD. Caveat: Deltas are static values stored on derivative_contract, not recomputed from current market levels';


--
-- Name: COLUMN mv_customer_360.leverage_ratio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.leverage_ratio IS 'How many times net value the customer is exposed to markets Unit: x. Caveat: Above 1 means economic exposure exceeds net assets. This is economic leverage: it can exceed 1.5 from derivative notionals alone, with no borrowing at all. Above 1.5 raises the LEVERAGED flag';


--
-- Name: COLUMN mv_customer_360.foreign_currency_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.foreign_currency_pct IS 'Share of gross assets denominated in a currency other than SGD Unit: %. Caveat: Currency of the instrument, not of the underlying business or revenue';


--
-- Name: COLUMN mv_customer_360.largest_position_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.largest_position_name IS 'The single biggest position and the Herfindahl index of all position weights Unit: % / 0-1. Caveat: Position-level, not issuer-level: two holdings in the same issuer are counted separately. HHI covers positive positions only';


--
-- Name: COLUMN mv_customer_360.largest_position_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.largest_position_pct IS 'The single biggest position and the Herfindahl index of all position weights Unit: % / 0-1. Caveat: Position-level, not issuer-level: two holdings in the same issuer are counted separately. HHI covers positive positions only';


--
-- Name: COLUMN mv_customer_360.concentration_hhi; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.concentration_hhi IS 'The single biggest position and the Herfindahl index of all position weights Unit: % / 0-1. Caveat: Position-level, not issuer-level: two holdings in the same issuer are counted separately. HHI covers positive positions only';


--
-- Name: COLUMN mv_customer_360.num_positions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.num_positions IS 'Number of security holdings and fund investments Unit: count. Caveat: Bank accounts and fixed deposits are not counted as positions';


--
-- Name: COLUMN mv_customer_360.complex_product_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.complex_product_count IS 'Positions in options, futures, FX derivatives, warrants and structured notes, plus private equity and hedge funds, and the highest product risk rating held Unit: count / SGD / 1-5. Caveat: Complexity for securities is inferred from the existence of a derivative_contract row, not read from derivative_contract.is_complex_product. Risk rating runs 1 (low) to 5 (high) and is NULL for plain securities, funds, deposits and cash';


--
-- Name: COLUMN mv_customer_360.complex_product_value_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.complex_product_value_sgd IS 'Positions in options, futures, FX derivatives, warrants and structured notes, plus private equity and hedge funds, and the highest product risk rating held Unit: count / SGD / 1-5. Caveat: Complexity for securities is inferred from the existence of a derivative_contract row, not read from derivative_contract.is_complex_product. Risk rating runs 1 (low) to 5 (high) and is NULL for plain securities, funds, deposits and cash';


--
-- Name: COLUMN mv_customer_360.max_product_risk_rating; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.max_product_risk_rating IS 'Positions in options, futures, FX derivatives, warrants and structured notes, plus private equity and hedge funds, and the highest product risk rating held Unit: count / SGD / 1-5. Caveat: Complexity for securities is inferred from the existence of a derivative_contract row, not read from derivative_contract.is_complex_product. Risk rating runs 1 (low) to 5 (high) and is NULL for plain securities, funds, deposits and cash';


--
-- Name: COLUMN mv_customer_360.unrealised_pnl_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.unrealised_pnl_sgd IS 'Mark-to-market gain or loss on the positions held today, and that gain as a percentage of their cost Unit: SGD / %. Caveat: Not time-weighted and not annualised -- there is no price history in the database. Excludes realised gains, income and fees, so it is not a performance figure';


--
-- Name: COLUMN mv_customer_360.unrealised_return_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.unrealised_return_pct IS 'Mark-to-market gain or loss on the positions held today, and that gain as a percentage of their cost Unit: SGD / %. Caveat: Not time-weighted and not annualised -- there is no price history in the database. Excludes realised gains, income and fees, so it is not a performance figure';


--
-- Name: COLUMN mv_customer_360.bond_weighted_duration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.bond_weighted_duration IS 'Interest-rate duration of bond-like assets, the value change per 1bp of yield, and the estimated mark-to-market hit from a 100bp rise Unit: years / SGD. Caveat: Durations come from ref_duration_assumption by symbol, fund name or fund category -- they are house assumptions, not computed from cash flows. A linear duration approximation, so it overstates losses for large moves. Fixed deposits are excluded because they do not reprice before maturity';


--
-- Name: COLUMN mv_customer_360.dv01_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.dv01_sgd IS 'Interest-rate duration of bond-like assets, the value change per 1bp of yield, and the estimated mark-to-market hit from a 100bp rise Unit: years / SGD. Caveat: Durations come from ref_duration_assumption by symbol, fund name or fund category -- they are house assumptions, not computed from cash flows. A linear duration approximation, so it overstates losses for large moves. Fixed deposits are excluded because they do not reprice before maturity';


--
-- Name: COLUMN mv_customer_360.bond_pnl_plus100bp_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.bond_pnl_plus100bp_sgd IS 'Interest-rate duration of bond-like assets, the value change per 1bp of yield, and the estimated mark-to-market hit from a 100bp rise Unit: years / SGD. Caveat: Durations come from ref_duration_assumption by symbol, fund name or fund category -- they are house assumptions, not computed from cash flows. A linear duration approximation, so it overstates losses for large moves. Fixed deposits are excluded because they do not reprice before maturity';


--
-- Name: COLUMN mv_customer_360.fd_maturing_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.fd_maturing_12m_sgd IS 'Fixed deposit principal maturing within 30, 90 and 365 days, and the date of the next maturity Unit: SGD / date. Caveat: Cumulative, so the 30-day figure is also inside the 90-day and 12-month figures. Principal only, no accrued interest';


--
-- Name: COLUMN mv_customer_360.fd_below_market_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.fd_below_market_sgd IS 'Principal locked in fixed deposits paying less than the current market deposit rate Unit: SGD. Caveat: The opportunity cost in money is in mv_customer_rate_sensitivity.fd_opportunity_cost_12m_sgd';


--
-- Name: COLUMN mv_customer_360.income_gain_plus25bp_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.income_gain_plus25bp_12m_sgd IS 'Estimated 12-month effect of a 25bp rise: bond price change, plus extra interest on cash, money-market funds and repricing deposits, minus extra margin interest Unit: SGD / %. Caveat: Negative means the customer is hurt. rate_hike_impact_rank = 1 is the most negatively affected customer. Equity and credit effects are not modelled at all -- for the equity side use tech_equity_exposure_pct and bank_equity_value_sgd. Assumes a parallel shift and full pass-through to deposit and margin rates';


--
-- Name: COLUMN mv_customer_360.net_impact_plus25bp_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.net_impact_plus25bp_sgd IS 'Estimated 12-month effect of a 25bp rise: bond price change, plus extra interest on cash, money-market funds and repricing deposits, minus extra margin interest Unit: SGD / %. Caveat: Negative means the customer is hurt. rate_hike_impact_rank = 1 is the most negatively affected customer. Equity and credit effects are not modelled at all -- for the equity side use tech_equity_exposure_pct and bank_equity_value_sgd. Assumes a parallel shift and full pass-through to deposit and margin rates';


--
-- Name: COLUMN mv_customer_360.net_impact_plus25bp_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.net_impact_plus25bp_pct IS 'Estimated 12-month effect of a 25bp rise: bond price change, plus extra interest on cash, money-market funds and repricing deposits, minus extra margin interest Unit: SGD / %. Caveat: Negative means the customer is hurt. rate_hike_impact_rank = 1 is the most negatively affected customer. Equity and credit effects are not modelled at all -- for the equity side use tech_equity_exposure_pct and bank_equity_value_sgd. Assumes a parallel shift and full pass-through to deposit and margin rates';


--
-- Name: COLUMN mv_customer_360.tech_equity_exposure_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.tech_equity_exposure_pct IS 'Delta-adjusted equity exposure to securities in the Technology sector, as a share of gross assets Unit: %. Caveat: Sector is taken from security.sector. Funds carry no sector, so technology held inside a fund is not counted';


--
-- Name: COLUMN mv_customer_360.investment_income_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.investment_income_12m_sgd IS 'Dividends, deposit interest, note coupons and fund distributions received in the last 12 months Unit: SGD. Caveat: Trailing actuals, not a forward yield. Only income paid into accounts held here';


--
-- Name: COLUMN mv_customer_360.earned_income_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.earned_income_12m_sgd IS 'Salary, pension and allowance credits received in the last 12 months Unit: SGD. Caveat: Only what is paid into accounts held here; a customer banking their salary elsewhere shows zero';


--
-- Name: COLUMN mv_customer_360.avg_monthly_spending_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.avg_monthly_spending_sgd IS 'Average monthly card, bill and ATM outflow over the last 12 months Unit: SGD. Caveat: Only spending that runs through accounts held here. Used by the LOW_LIQUIDITY_UNDER_6M_SPEND flag';


--
-- Name: COLUMN mv_customer_360.fd_maturing_30d_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.fd_maturing_30d_sgd IS 'Fixed deposit principal maturing within 30, 90 and 365 days, and the date of the next maturity Unit: SGD / date. Caveat: Cumulative, so the 30-day figure is also inside the 90-day and 12-month figures. Principal only, no accrued interest';


--
-- Name: COLUMN mv_customer_360.fd_maturing_90d_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.fd_maturing_90d_sgd IS 'Fixed deposit principal maturing within 30, 90 and 365 days, and the date of the next maturity Unit: SGD / date. Caveat: Cumulative, so the 30-day figure is also inside the 90-day and 12-month figures. Principal only, no accrued interest';


--
-- Name: COLUMN mv_customer_360.next_fd_maturity_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.next_fd_maturity_date IS 'Fixed deposit principal maturing within 30, 90 and 365 days, and the date of the next maturity Unit: SGD / date. Caveat: Cumulative, so the 30-day figure is also inside the 90-day and 12-month figures. Principal only, no accrued interest';


--
-- Name: COLUMN mv_customer_360.trades_per_month; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.trades_per_month IS 'Trades per month, the share of those trades that are options, and traded value against gross assets, over the last 12 months Unit: count / % / x. Caveat: Trailing 12 months only. Divided by a fixed 12 months, so a customer who joined mid-year shows a lower rate than they actually trade at';


--
-- Name: COLUMN mv_customer_360.option_trade_share_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.option_trade_share_pct IS 'Trades per month, the share of those trades that are options, and traded value against gross assets, over the last 12 months Unit: count / % / x. Caveat: Trailing 12 months only. Divided by a fixed 12 months, so a customer who joined mid-year shows a lower rate than they actually trade at';


--
-- Name: COLUMN mv_customer_360.turnover_ratio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.turnover_ratio IS 'Trades per month, the share of those trades that are options, and traded value against gross assets, over the last 12 months Unit: count / % / x. Caveat: Trailing 12 months only. Divided by a fixed 12 months, so a customer who joined mid-year shows a lower rate than they actually trade at';


--
-- Name: COLUMN mv_customer_360.net_option_premium_12m_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.net_option_premium_12m_sgd IS 'Net cash from option activity over 12 months: premium received on written options less premium paid on bought options Unit: SGD. Caveat: Positive means net premium collected, which usually means writing options -- income now in exchange for assigned risk later';


--
-- Name: COLUMN mv_customer_360.days_since_last_transaction; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.days_since_last_transaction IS 'Days since the most recent transaction of any kind Unit: days. Caveat: NULL when the customer has never transacted';


--
-- Name: COLUMN mv_customer_360.investor_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.investor_type IS 'Rule-based investor classification: ACTIVE_TRADER, GROWTH_INVESTOR, INCOME_INVESTOR, CONSERVATIVE_INVESTOR, BALANCED_INVESTOR or UNCLASSIFIED Unit: text / 0-1. Caveat: LINEAGE WARNING: carried in from vw_investor_profile, which works on unconverted currency and treats every security holding as equity. It can therefore disagree with equity_pct in this same row -- customers exist who are 90% equity here and BALANCED_INVESTOR there. The inputs behind it are also degenerate: avg_active_months_per_year is 12.00 for every customer, so the ACTIVE_TRADER activity test is always true, and avg_holding_days measures time since the oldest account opened rather than how long positions are held. classification_confidence has a practical ceiling near 0.6, so do not filter on > 0.7. Prefer equity_pct, trades_per_month and option_trade_share_pct when the answer matters';


--
-- Name: COLUMN mv_customer_360.classification_confidence; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.classification_confidence IS 'Rule-based investor classification: ACTIVE_TRADER, GROWTH_INVESTOR, INCOME_INVESTOR, CONSERVATIVE_INVESTOR, BALANCED_INVESTOR or UNCLASSIFIED Unit: text / 0-1. Caveat: LINEAGE WARNING: carried in from vw_investor_profile, which works on unconverted currency and treats every security holding as equity. It can therefore disagree with equity_pct in this same row -- customers exist who are 90% equity here and BALANCED_INVESTOR there. The inputs behind it are also degenerate: avg_active_months_per_year is 12.00 for every customer, so the ACTIVE_TRADER activity test is always true, and avg_holding_days measures time since the oldest account opened rather than how long positions are held. classification_confidence has a practical ceiling near 0.6, so do not filter on > 0.7. Prefer equity_pct, trades_per_month and option_trade_share_pct when the answer matters';


--
-- Name: COLUMN mv_customer_360.risk_profile; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.risk_profile IS 'AGGRESSIVE / MODERATE / CONSERVATIVE by equity share, and LOW / MEDIUM / HIGH by largest-position share Unit: text. Caveat: LINEAGE WARNING: carried in from vw_fact_risk_profile, which sums SGD and USD without conversion and counts options, futures and bond ETFs as equity. Its equity percentage is not the equity_pct in this row and its concentration measure ignores funds, so concentration_risk can read MEDIUM while largest_position_pct in the same row is above 25. Judge risk from equity_pct, leverage_ratio, largest_position_pct and concentration_hhi instead';


--
-- Name: COLUMN mv_customer_360.concentration_risk; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.concentration_risk IS 'AGGRESSIVE / MODERATE / CONSERVATIVE by equity share, and LOW / MEDIUM / HIGH by largest-position share Unit: text. Caveat: LINEAGE WARNING: carried in from vw_fact_risk_profile, which sums SGD and USD without conversion and counts options, futures and bond ETFs as equity. Its equity percentage is not the equity_pct in this row and its concentration measure ignores funds, so concentration_risk can read MEDIUM while largest_position_pct in the same row is above 25. Judge risk from equity_pct, leverage_ratio, largest_position_pct and concentration_hhi instead';


--
-- Name: COLUMN mv_customer_360.target_growth_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.target_growth_pct IS 'Growth assets compared with the 110-minus-age rule of thumb Unit: %. Caveat: A heuristic, not advice, and blind to the customer stated objectives and risk tolerance. Positive means more growth assets than the guide suggests';


--
-- Name: COLUMN mv_customer_360.ml_segment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.ml_segment IS 'K-Means behaviour segment, and the number of transactions flagged unusual by the Isolation Forest model in the last 90 days Unit: text / count. Caveat: Models are retrained on demand, so the segment can change between refreshes. An anomaly is a prompt to look, not evidence of anything';


--
-- Name: COLUMN mv_customer_360.ml_anomalies_90d; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.ml_anomalies_90d IS 'K-Means behaviour segment, and the number of transactions flagged unusual by the Isolation Forest model in the last 90 days Unit: text / count. Caveat: Models are retrained on demand, so the segment can change between refreshes. An anomaly is a prompt to look, not evidence of anything';


--
-- Name: COLUMN mv_customer_360.growth_vs_age_target_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.growth_vs_age_target_pct IS 'Growth assets compared with the 110-minus-age rule of thumb Unit: %. Caveat: A heuristic, not advice, and blind to the customer stated objectives and risk tolerance. Positive means more growth assets than the guide suggests';


--
-- Name: COLUMN mv_customer_360.wealth_percentile_in_age_band; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.wealth_percentile_in_age_band IS 'Where the customer ranks against peers in the same age band Unit: percentile. Caveat: Ranks within this database only, which is a small book -- bands with few customers are noisy. Return percentile ranks unrealised return, which is not time-weighted';


--
-- Name: COLUMN mv_customer_360.return_percentile_in_age_band; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.return_percentile_in_age_band IS 'Where the customer ranks against peers in the same age band Unit: percentile. Caveat: Ranks within this database only, which is a small book -- bands with few customers are noisy. Return percentile ranks unrealised return, which is not time-weighted';


--
-- Name: COLUMN mv_customer_360.rate_hike_impact_rank; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.rate_hike_impact_rank IS 'Estimated 12-month effect of a 25bp rise: bond price change, plus extra interest on cash, money-market funds and repricing deposits, minus extra margin interest Unit: SGD / %. Caveat: Negative means the customer is hurt. rate_hike_impact_rank = 1 is the most negatively affected customer. Equity and credit effects are not modelled at all -- for the equity side use tech_equity_exposure_pct and bank_equity_value_sgd. Assumes a parallel shift and full pass-through to deposit and margin rates';


--
-- Name: COLUMN mv_customer_360.suitability_flags; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.suitability_flags IS 'COMPLEX_PRODUCT_AGE_65_PLUS (age >= 65 and product risk >= 4); SINGLE_POSITION_OVER_25PCT; LEVERAGED (margin loan or leverage > 1.5); LOW_LIQUIDITY_UNDER_6M_SPEND; EQUITY_HEAVY_FOR_AGE (age >= 60 and equity above target + 20); SPECULATIVE_TRADING_SMALL_PORTFOLIO (options over 40% of trades and assets under 250k); FD_MATURING_30D; RATE_HIKE_SENSITIVE (+25bp impact below -0.10%); NOT_ACTIVE; ML_UNUSUAL_ACTIVITY Unit: text[]. Caveat: Review prompts, not conclusions. An empty array means no rule fired, not that the portfolio was assessed and cleared';


--
-- Name: COLUMN mv_customer_360.refreshed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mv_customer_360.refreshed_at IS 'When refresh_analytics() last rebuilt this materialized view Unit: timestamp. Caveat: This is when the numbers were computed, not how old the underlying data is. Position prices carry their own as_of_date on holding and fund_investment, and FX rates carry ref_fx_rate.as_of_date';


--
-- Name: news_research; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.news_research (
    research_id bigint NOT NULL,
    published_at timestamp without time zone,
    source character varying(200),
    title character varying(500),
    content text,
    content_type character varying(30),
    asset_class character varying(50),
    security_symbol character varying(30),
    fund_name character varying(200),
    country character varying(100),
    sector character varying(100),
    sentiment character varying(30),
    embedding public.vector(1536),
    url text,
    retrieved_at timestamp without time zone DEFAULT now()
);


--
-- Name: news_research_research_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.news_research_research_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_research_research_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.news_research_research_id_seq OWNED BY public.news_research.research_id;


--
-- Name: ref_model_portfolio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_model_portfolio (
    model_name character varying(30) NOT NULL,
    bucket character varying(30) NOT NULL,
    target_pct numeric(5,2) NOT NULL,
    min_age integer,
    max_age integer,
    description text
);


--
-- Name: TABLE ref_model_portfolio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ref_model_portfolio IS 'Target allocation per bucket for each life-stage model portfolio, with the age range it applies to.';


--
-- Name: COLUMN ref_model_portfolio.model_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_model_portfolio.model_name IS 'Target allocation per bucket for each life-stage model, and the age range it applies to Unit: %. Caveat: House assumptions. Age bands must cover every customer age or those customers vanish from vw_customer_model_gap';


--
-- Name: COLUMN ref_model_portfolio.bucket; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_model_portfolio.bucket IS 'Target allocation per bucket for each life-stage model, and the age range it applies to Unit: %. Caveat: House assumptions. Age bands must cover every customer age or those customers vanish from vw_customer_model_gap';


--
-- Name: COLUMN ref_model_portfolio.target_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_model_portfolio.target_pct IS 'Target allocation per bucket for each life-stage model, and the age range it applies to Unit: %. Caveat: House assumptions. Age bands must cover every customer age or those customers vanish from vw_customer_model_gap';


--
-- Name: COLUMN ref_model_portfolio.min_age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_model_portfolio.min_age IS 'Target allocation per bucket for each life-stage model, and the age range it applies to Unit: %. Caveat: House assumptions. Age bands must cover every customer age or those customers vanish from vw_customer_model_gap';


--
-- Name: COLUMN ref_model_portfolio.max_age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_model_portfolio.max_age IS 'Target allocation per bucket for each life-stage model, and the age range it applies to Unit: %. Caveat: House assumptions. Age bands must cover every customer age or those customers vanish from vw_customer_model_gap';


--
-- Name: COLUMN ref_model_portfolio.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ref_model_portfolio.description IS 'Target allocation per bucket for each life-stage model, and the age range it applies to Unit: %. Caveat: House assumptions. Age bands must cover every customer age or those customers vanish from vw_customer_model_gap';


--
-- Name: security_security_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.security_security_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: security_security_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.security_security_id_seq OWNED BY public.security.security_id;


--
-- Name: vw_customer_model_gap; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_customer_model_gap AS
 WITH c AS (
         SELECT mv_customer_360.customer_id,
            mv_customer_360.full_name,
            mv_customer_360.age,
            mv_customer_360.status,
            COALESCE(mv_customer_360.equity_pct, (0)::numeric) AS eq,
            COALESCE(mv_customer_360.fixed_income_pct, (0)::numeric) AS fi,
            COALESCE(mv_customer_360.cash_and_deposits_pct, (0)::numeric) AS cash,
            COALESCE(mv_customer_360.multi_asset_pct, (0)::numeric) AS multi,
            ((COALESCE(mv_customer_360.alternatives_pct, (0)::numeric) + COALESCE(mv_customer_360.commodity_pct, (0)::numeric)) + COALESCE(mv_customer_360.structured_pct, (0)::numeric)) AS alts
           FROM public.mv_customer_360
        ), actual AS (
         SELECT c.customer_id,
            c.full_name,
            c.age,
            c.status,
            b.bucket,
            b.pct AS actual_pct,
            b.sort_order
           FROM (c
             CROSS JOIN LATERAL ( VALUES ('EQUITY'::text,(c.eq + (0.5 * c.multi)),1), ('FIXED_INCOME'::text,(c.fi + (0.5 * c.multi)),2), ('CASH_DEPOSITS'::text,c.cash,3), ('ALTERNATIVES'::text,c.alts,4)) b(bucket, pct, sort_order))
        )
 SELECT a.customer_id,
    a.full_name,
    a.age,
    a.status,
    m.model_name,
    m.bucket,
    a.sort_order,
    round(a.actual_pct, 2) AS actual_pct,
    m.target_pct,
    round((a.actual_pct - m.target_pct), 2) AS gap_pct,
        CASE
            WHEN ((a.actual_pct - m.target_pct) > (10)::numeric) THEN 'OVERWEIGHT'::text
            WHEN ((a.actual_pct - m.target_pct) < ('-10'::integer)::numeric) THEN 'UNDERWEIGHT'::text
            ELSE 'IN_RANGE'::text
        END AS gap_status
   FROM (actual a
     JOIN public.ref_model_portfolio m ON ((((m.bucket)::text = a.bucket) AND ((a.age >= m.min_age) AND (a.age <= m.max_age)))));


--
-- Name: VIEW vw_customer_model_gap; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_customer_model_gap IS 'Customer allocation vs life-stage model portfolio (ref_model_portfolio), per bucket; gap beyond plus or minus 10 points flagged. Model chosen by age alone.';


--
-- Name: COLUMN vw_customer_model_gap.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.customer_id IS 'One row per customer per asset bucket, comparing actual allocation with a life-stage model portfolio Caveat: Four rows per customer. A customer whose age falls outside every band in ref_model_portfolio disappears entirely';


--
-- Name: COLUMN vw_customer_model_gap.full_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.full_name IS 'One row per customer per asset bucket, comparing actual allocation with a life-stage model portfolio Caveat: Four rows per customer. A customer whose age falls outside every band in ref_model_portfolio disappears entirely';


--
-- Name: COLUMN vw_customer_model_gap.age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.age IS 'One row per customer per asset bucket, comparing actual allocation with a life-stage model portfolio Caveat: Four rows per customer. A customer whose age falls outside every band in ref_model_portfolio disappears entirely';


--
-- Name: COLUMN vw_customer_model_gap.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.status IS 'One row per customer per asset bucket, comparing actual allocation with a life-stage model portfolio Caveat: Four rows per customer. A customer whose age falls outside every band in ref_model_portfolio disappears entirely';


--
-- Name: COLUMN vw_customer_model_gap.model_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.model_name IS 'Which model portfolio applies, chosen by age: GROWTH, BALANCED_GROWTH, BALANCED or CONSERVATIVE Caveat: Matched on age alone -- it ignores stated objectives, risk tolerance and time horizon';


--
-- Name: COLUMN vw_customer_model_gap.bucket; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.bucket IS 'The asset bucket: EQUITY, FIXED_INCOME, CASH_DEPOSITS or ALTERNATIVES, with a display order Caveat: Coarser than exposure_class: multi-asset is split 50/50 into equity and fixed income, and alternatives, commodities and structured products are pooled';


--
-- Name: COLUMN vw_customer_model_gap.sort_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.sort_order IS 'The asset bucket: EQUITY, FIXED_INCOME, CASH_DEPOSITS or ALTERNATIVES, with a display order Caveat: Coarser than exposure_class: multi-asset is split 50/50 into equity and fixed income, and alternatives, commodities and structured products are pooled';


--
-- Name: COLUMN vw_customer_model_gap.actual_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.actual_pct IS 'Actual allocation against the model target, the difference in points, and whether it is OVERWEIGHT, UNDERWEIGHT or IN_RANGE Unit: % points. Caveat: Targets in ref_model_portfolio are house assumptions, editable there. The plus or minus 10 point tolerance is fixed in the view';


--
-- Name: COLUMN vw_customer_model_gap.target_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.target_pct IS 'Actual allocation against the model target, the difference in points, and whether it is OVERWEIGHT, UNDERWEIGHT or IN_RANGE Unit: % points. Caveat: Targets in ref_model_portfolio are house assumptions, editable there. The plus or minus 10 point tolerance is fixed in the view';


--
-- Name: COLUMN vw_customer_model_gap.gap_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.gap_pct IS 'Actual allocation against the model target, the difference in points, and whether it is OVERWEIGHT, UNDERWEIGHT or IN_RANGE Unit: % points. Caveat: Targets in ref_model_portfolio are house assumptions, editable there. The plus or minus 10 point tolerance is fixed in the view';


--
-- Name: COLUMN vw_customer_model_gap.gap_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_model_gap.gap_status IS 'Actual allocation against the model target, the difference in points, and whether it is OVERWEIGHT, UNDERWEIGHT or IN_RANGE Unit: % points. Caveat: Targets in ref_model_portfolio are house assumptions, editable there. The plus or minus 10 point tolerance is fixed in the view';


--
-- Name: vw_customer_news_relevance; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_customer_news_relevance AS
 WITH pos AS (
         SELECT p.customer_id,
            p.symbol,
            dc.underlying_symbol,
            p.sector,
            p.country,
            p.position_name,
            abs(p.economic_exposure_sgd) AS exposure_sgd
           FROM (public.mv_position_sgd p
             LEFT JOIN public.derivative_contract dc ON ((dc.security_id = p.security_id)))
          WHERE (p.position_source = ANY (ARRAY['HOLDING'::text, 'FUND'::text]))
        ), news AS (
         SELECT n_1.research_id,
            n_1.published_at,
            n_1.source,
            n_1.title,
            "left"(n_1.content, 500) AS summary,
            n_1.security_symbol,
            n_1.sector,
            n_1.country,
            n_1.asset_class,
            n_1.sentiment,
            n_1.url,
            (n_1.url IS NULL) AS is_synthetic,
            (GREATEST((0)::numeric, EXTRACT(day FROM (now() - (n_1.published_at)::timestamp with time zone))))::integer AS days_old
           FROM public.news_research n_1
          WHERE (n_1.published_at >= (now() - '90 days'::interval))
        ), matches AS (
         SELECT p.customer_id,
            n_1.research_id,
            'DIRECT_HOLDING'::text AS match_type,
            1.0 AS weight,
            COALESCE(p.symbol, p.position_name) AS matched_on,
            p.exposure_sgd
           FROM (news n_1
             JOIN pos p ON (((n_1.security_symbol IS NOT NULL) AND (((p.symbol)::text = (n_1.security_symbol)::text) OR ((p.underlying_symbol)::text = (n_1.security_symbol)::text)))))
        UNION ALL
         SELECT p.customer_id,
            n_1.research_id,
            'SECTOR'::text,
            0.5,
            (((p.sector)::text || ': '::text) || (COALESCE(p.symbol, p.position_name))::text),
            p.exposure_sgd
           FROM (news n_1
             JOIN pos p ON (((n_1.sector IS NOT NULL) AND ((p.sector)::text = (n_1.sector)::text) AND ((COALESCE(p.symbol, ''::character varying))::text <> (COALESCE(n_1.security_symbol, '#'::character varying))::text) AND ((COALESCE(p.underlying_symbol, ''::character varying))::text <> (COALESCE(n_1.security_symbol, '#'::character varying))::text))))
        UNION ALL
         SELECT p.customer_id,
            n_1.research_id,
            'COUNTRY'::text,
            0.4,
            (((p.country)::text || ': '::text) || (COALESCE(p.symbol, p.position_name))::text),
            p.exposure_sgd
           FROM (news n_1
             JOIN pos p ON (((n_1.security_symbol IS NULL) AND ((n_1.asset_class)::text = 'EQUITY'::text) AND ((p.country)::text = (n_1.country)::text))))
        UNION ALL
         SELECT r.customer_id,
            n_1.research_id,
            'RATE_SENSITIVE'::text,
            0.7,
            'bonds/deposits'::character varying,
            (r.bond_like_value_sgd + r.fd_total_sgd)
           FROM (news n_1
             JOIN public.mv_customer_rate_sensitivity r ON ((((n_1.asset_class)::text = 'FIXED_INCOME'::text) AND (n_1.security_symbol IS NULL))))
          WHERE ((r.bond_like_value_sgd + r.fd_total_sgd) > (0)::numeric)
        UNION ALL
         SELECT p.customer_id,
            n_1.research_id,
            'SGD_CASH_DEPOSITS'::text,
            0.6,
            'SGD cash & deposits'::character varying,
            sum(p.market_value_sgd) AS sum
           FROM (news n_1
             JOIN public.mv_position_sgd p ON ((((n_1.asset_class)::text = 'CASH'::text) AND ((n_1.country)::text = 'Singapore'::text) AND (p.exposure_class = ANY (ARRAY['CASH'::text, 'DEPOSIT'::text])) AND (p.currency = 'SGD'::bpchar) AND (p.market_value_sgd > (0)::numeric))))
          GROUP BY p.customer_id, n_1.research_id
        ), agg AS (
         SELECT m.customer_id,
            m.research_id,
            (array_agg(m.match_type ORDER BY m.weight DESC))[1] AS match_type,
            max(m.weight) AS weight,
            string_agg(DISTINCT (m.matched_on)::text, ', '::text) AS matched_on,
            sum(m.exposure_sgd) AS exposure_sgd
           FROM matches m
          GROUP BY m.customer_id, m.research_id
        )
 SELECT a.customer_id,
    n.research_id,
    (n.published_at)::date AS published,
    n.days_old,
    n.source,
    n.title,
    n.summary,
    n.security_symbol,
    n.sector,
    n.country,
    n.sentiment,
    n.url,
    n.is_synthetic,
    a.match_type,
    a.matched_on,
    round(a.exposure_sgd, 2) AS exposure_sgd,
    round((((100)::numeric * a.exposure_sgd) / NULLIF(c.gross_assets_sgd, (0)::numeric)), 2) AS exposure_pct_of_aum,
    round(((((((100)::numeric * a.weight) * LEAST((1)::numeric, (a.exposure_sgd / NULLIF(c.gross_assets_sgd, (0)::numeric)))) * exp((((- n.days_old))::numeric / 30.0))) *
        CASE n.sentiment
            WHEN 'NEUTRAL'::text THEN 0.6
            ELSE 1.0
        END) *
        CASE
            WHEN n.is_synthetic THEN 0.5
            ELSE 1.0
        END), 3) AS relevance_score
   FROM ((agg a
     JOIN news n USING (research_id))
     JOIN public.mv_customer_360 c USING (customer_id));


--
-- Name: VIEW vw_customer_news_relevance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_customer_news_relevance IS 'Recent news (90 days) matched to each customer by holding, sector, country, rate sensitivity or SGD deposits; relevance_score = match weight x exposure share of AUM x recency x sentiment strength (synthetic news halved). Deduplicated to one row per customer per article.';


--
-- Name: COLUMN vw_customer_news_relevance.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.customer_id IS 'One row per customer per news item, for items published in the last 90 days that match something the customer holds Caveat: Deduplicated: a customer matching one article several ways gets a single row carrying the strongest match';


--
-- Name: COLUMN vw_customer_news_relevance.research_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.research_id IS 'One row per customer per news item, for items published in the last 90 days that match something the customer holds Caveat: Deduplicated: a customer matching one article several ways gets a single row carrying the strongest match';


--
-- Name: COLUMN vw_customer_news_relevance.published; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.published IS 'Publication date and its age in days Unit: date / days. Caveat: Only the last 90 days are in scope';


--
-- Name: COLUMN vw_customer_news_relevance.days_old; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.days_old IS 'Publication date and its age in days Unit: date / days. Caveat: Only the last 90 days are in scope';


--
-- Name: COLUMN vw_customer_news_relevance.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.source IS 'Where the item came from and whether it is real Caveat: Synthetic rows are generated test data. Cite source, date and url for real items, and say so when using a synthetic one';


--
-- Name: COLUMN vw_customer_news_relevance.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.title IS 'Headline and the first 500 characters of the body Caveat: The summary is a truncation, not a generated abstract, and can cut mid-sentence';


--
-- Name: COLUMN vw_customer_news_relevance.summary; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.summary IS 'Headline and the first 500 characters of the body Caveat: The summary is a truncation, not a generated abstract, and can cut mid-sentence';


--
-- Name: COLUMN vw_customer_news_relevance.security_symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.security_symbol IS 'What the item is about and its sentiment: POSITIVE, NEUTRAL or NEGATIVE Caveat: Sentiment is a label on the article, not a modelled market impact, and is not weighted by how large the position is';


--
-- Name: COLUMN vw_customer_news_relevance.sector; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.sector IS 'What the item is about and its sentiment: POSITIVE, NEUTRAL or NEGATIVE Caveat: Sentiment is a label on the article, not a modelled market impact, and is not weighted by how large the position is';


--
-- Name: COLUMN vw_customer_news_relevance.country; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.country IS 'What the item is about and its sentiment: POSITIVE, NEUTRAL or NEGATIVE Caveat: Sentiment is a label on the article, not a modelled market impact, and is not weighted by how large the position is';


--
-- Name: COLUMN vw_customer_news_relevance.sentiment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.sentiment IS 'What the item is about and its sentiment: POSITIVE, NEUTRAL or NEGATIVE Caveat: Sentiment is a label on the article, not a modelled market impact, and is not weighted by how large the position is';


--
-- Name: COLUMN vw_customer_news_relevance.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.url IS 'Where the item came from and whether it is real Caveat: Synthetic rows are generated test data. Cite source, date and url for real items, and say so when using a synthetic one';


--
-- Name: COLUMN vw_customer_news_relevance.is_synthetic; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.is_synthetic IS 'Where the item came from and whether it is real Caveat: Synthetic rows are generated test data. Cite source, date and url for real items, and say so when using a synthetic one';


--
-- Name: COLUMN vw_customer_news_relevance.match_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.match_type IS 'Why the item is relevant: DIRECT_HOLDING, SECTOR, COUNTRY, RATE_SENSITIVE or SGD_CASH_DEPOSITS, and which position triggered it Caveat: DIRECT_HOLDING also fires when the article names the underlying of a derivative the customer holds';


--
-- Name: COLUMN vw_customer_news_relevance.matched_on; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.matched_on IS 'Why the item is relevant: DIRECT_HOLDING, SECTOR, COUNTRY, RATE_SENSITIVE or SGD_CASH_DEPOSITS, and which position triggered it Caveat: DIRECT_HOLDING also fires when the article names the underlying of a derivative the customer holds';


--
-- Name: COLUMN vw_customer_news_relevance.exposure_sgd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.exposure_sgd IS 'How much money is behind the match, in SGD and as a share of gross assets Unit: SGD / %. Caveat: Uses absolute economic exposure, so a hedge counts as exposure rather than offsetting it';


--
-- Name: COLUMN vw_customer_news_relevance.exposure_pct_of_aum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.exposure_pct_of_aum IS 'How much money is behind the match, in SGD and as a share of gross assets Unit: SGD / %. Caveat: Uses absolute economic exposure, so a hedge counts as exposure rather than offsetting it';


--
-- Name: COLUMN vw_customer_news_relevance.relevance_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_customer_news_relevance.relevance_score IS 'A single ranking score for how much a news item matters to this customer Unit: score. Caveat: A relative ranking within a customer, not an absolute measure. Not comparable across customers of very different size';


--
-- Name: vw_fact_relevant_news; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_fact_relevant_news AS
 SELECT nr.research_id,
    h.customer_id,
    nr.published_at,
    nr.source,
    nr.title,
    nr.content_type,
    nr.asset_class,
    nr.security_symbol,
    s.security_name,
    nr.sector,
    nr.country,
    nr.sentiment,
    h.market_value,
    h.quantity,
    h.unrealised_pnl,
        CASE
            WHEN ((nr.security_symbol)::text = (s.symbol)::text) THEN 'DIRECT_HOLDING'::text
            WHEN ((nr.sector)::text = (s.sector)::text) THEN 'SECTOR_MATCH'::text
            WHEN ((nr.country)::text = (s.country)::text) THEN 'GEOGRAPHY_MATCH'::text
            ELSE 'INDIRECT'::text
        END AS relevance_type,
        CASE
            WHEN ((nr.sentiment)::text = 'POSITIVE'::text) THEN '↑'::text
            WHEN ((nr.sentiment)::text = 'NEGATIVE'::text) THEN '↓'::text
            ELSE '→'::text
        END AS sentiment_direction,
    (EXTRACT(day FROM (now() - (nr.published_at)::timestamp with time zone)))::integer AS days_old
   FROM ((public.news_research nr
     LEFT JOIN public.holding h ON ((((nr.security_symbol)::text = (( SELECT security.symbol
           FROM public.security
          WHERE (security.security_id = h.security_id)))::text) OR ((nr.sector)::text = (( SELECT security.sector
           FROM public.security
          WHERE (security.security_id = h.security_id)))::text))))
     LEFT JOIN public.security s ON ((h.security_id = s.security_id)))
  WHERE ((nr.published_at > (now() - '90 days'::interval)) AND (h.customer_id IS NOT NULL))
  ORDER BY h.customer_id, nr.published_at DESC;


--
-- Name: VIEW vw_fact_relevant_news; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_fact_relevant_news IS 'LEGACY. News matched to holdings by symbol or sector, not deduplicated: up to six rows per customer per article. Superseded by vw_customer_news_relevance.';


--
-- Name: COLUMN vw_fact_relevant_news.research_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.research_id IS 'Legacy news-to-customer matching for the last 90 days Caveat: NOT DEDUPLICATED: a customer holding several securities in a matching sector gets one row per holding, up to six rows for the same article. Counting rows here overstates news volume. vw_customer_news_relevance replaces this view and is deduplicated, exposure-weighted and scored';


--
-- Name: COLUMN vw_fact_relevant_news.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.customer_id IS 'Legacy news-to-customer matching for the last 90 days Caveat: NOT DEDUPLICATED: a customer holding several securities in a matching sector gets one row per holding, up to six rows for the same article. Counting rows here overstates news volume. vw_customer_news_relevance replaces this view and is deduplicated, exposure-weighted and scored';


--
-- Name: COLUMN vw_fact_relevant_news.published_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.published_at IS 'Publication date and age in days Unit: days.';


--
-- Name: COLUMN vw_fact_relevant_news.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.source IS 'Where the item came from and what kind of item it is Caveat: No url column here, so real and synthetic items cannot be told apart -- vw_customer_news_relevance exposes is_synthetic';


--
-- Name: COLUMN vw_fact_relevant_news.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.title IS 'Where the item came from and what kind of item it is Caveat: No url column here, so real and synthetic items cannot be told apart -- vw_customer_news_relevance exposes is_synthetic';


--
-- Name: COLUMN vw_fact_relevant_news.content_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.content_type IS 'Where the item came from and what kind of item it is Caveat: No url column here, so real and synthetic items cannot be told apart -- vw_customer_news_relevance exposes is_synthetic';


--
-- Name: COLUMN vw_fact_relevant_news.asset_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.asset_class IS 'What the article is about and the matched security Caveat: Macro items with no symbol and no sector match nothing and never appear';


--
-- Name: COLUMN vw_fact_relevant_news.security_symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.security_symbol IS 'What the article is about and the matched security Caveat: Macro items with no symbol and no sector match nothing and never appear';


--
-- Name: COLUMN vw_fact_relevant_news.security_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.security_name IS 'What the article is about and the matched security Caveat: Macro items with no symbol and no sector match nothing and never appear';


--
-- Name: COLUMN vw_fact_relevant_news.sector; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.sector IS 'What the article is about and the matched security Caveat: Macro items with no symbol and no sector match nothing and never appear';


--
-- Name: COLUMN vw_fact_relevant_news.country; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.country IS 'What the article is about and the matched security Caveat: Macro items with no symbol and no sector match nothing and never appear';


--
-- Name: COLUMN vw_fact_relevant_news.sentiment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.sentiment IS 'POSITIVE, NEUTRAL or NEGATIVE, with an arrow for display Caveat: A label on the article, not a modelled impact on the customer';


--
-- Name: COLUMN vw_fact_relevant_news.market_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.market_value IS 'The customer position that caused the match Unit: SGD or USD. Caveat: In the instrument currency, not converted. Repeated on every duplicate row, so summing it double-counts';


--
-- Name: COLUMN vw_fact_relevant_news.quantity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.quantity IS 'The customer position that caused the match Unit: SGD or USD. Caveat: In the instrument currency, not converted. Repeated on every duplicate row, so summing it double-counts';


--
-- Name: COLUMN vw_fact_relevant_news.unrealised_pnl; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.unrealised_pnl IS 'The customer position that caused the match Unit: SGD or USD. Caveat: In the instrument currency, not converted. Repeated on every duplicate row, so summing it double-counts';


--
-- Name: COLUMN vw_fact_relevant_news.relevance_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.relevance_type IS 'DIRECT_HOLDING, SECTOR_MATCH, GEOGRAPHY_MATCH or INDIRECT Caveat: Unranked and unweighted -- every match reads as equally important regardless of position size or article age';


--
-- Name: COLUMN vw_fact_relevant_news.sentiment_direction; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.sentiment_direction IS 'POSITIVE, NEUTRAL or NEGATIVE, with an arrow for display Caveat: A label on the article, not a modelled impact on the customer';


--
-- Name: COLUMN vw_fact_relevant_news.days_old; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_relevant_news.days_old IS 'Publication date and age in days Unit: days.';


--
-- Name: vw_fact_trading_activity; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_fact_trading_activity AS
 WITH transaction_summary AS (
         SELECT a.customer_id,
            (count(*))::integer AS total_transactions,
            (count(DISTINCT EXTRACT(month FROM ct.transaction_date)))::integer AS active_months,
            (avg(abs(ct.amount)))::numeric(18,2) AS avg_transaction_amount,
            (sum(
                CASE
                    WHEN (ct.amount > (0)::numeric) THEN ct.amount
                    ELSE (0)::numeric
                END))::numeric(18,2) AS total_deposits,
            (sum(
                CASE
                    WHEN (ct.amount < (0)::numeric) THEN abs(ct.amount)
                    ELSE (0)::numeric
                END))::numeric(18,2) AS total_withdrawals,
            max(ct.transaction_date) AS last_transaction_date,
            min(ct.transaction_date) AS first_transaction_date
           FROM (public.account a
             LEFT JOIN public.customer_transaction ct ON ((a.account_id = ct.account_id)))
          WHERE ((a.status)::text = 'ACTIVE'::text)
          GROUP BY a.customer_id
        ), holding_summary AS (
         SELECT holding.customer_id,
            (count(*))::integer AS num_positions,
            (avg(
                CASE
                    WHEN (holding.average_cost > (0)::numeric) THEN (((holding.market_price - holding.average_cost) / holding.average_cost) * (100)::numeric)
                    ELSE (0)::numeric
                END))::numeric(6,2) AS avg_position_return_pct,
            ((((sum(
                CASE
                    WHEN (holding.unrealised_pnl > (0)::numeric) THEN 1
                    ELSE 0
                END))::numeric / NULLIF((count(*))::numeric, (0)::numeric)) * (100)::numeric))::numeric(6,2) AS win_rate_pct,
            (sum(holding.unrealised_pnl))::numeric(18,2) AS total_unrealised_pnl,
            (sum(
                CASE
                    WHEN (holding.unrealised_pnl > (0)::numeric) THEN holding.unrealised_pnl
                    ELSE (0)::numeric
                END))::numeric(18,2) AS total_gains,
            (sum(
                CASE
                    WHEN (holding.unrealised_pnl < (0)::numeric) THEN abs(holding.unrealised_pnl)
                    ELSE (0)::numeric
                END))::numeric(18,2) AS total_losses
           FROM public.holding
          GROUP BY holding.customer_id
        ), dividend_summary AS (
         SELECT h.customer_id,
            (sum((h.market_value * 0.02)))::numeric(18,2) AS estimated_annual_dividend
           FROM public.holding h
          WHERE (h.market_value > (0)::numeric)
          GROUP BY h.customer_id
        )
 SELECT c.customer_id,
    c.customer_number,
    COALESCE(ts.total_transactions, 0) AS total_transactions,
    COALESCE(ts.active_months, 0) AS active_months,
    (((COALESCE(ts.total_transactions, 0))::numeric / NULLIF((COALESCE(ts.active_months, 0))::numeric, (0)::numeric)))::numeric(8,2) AS transactions_per_month,
    COALESCE(ts.avg_transaction_amount, (0)::numeric) AS avg_transaction_amount,
    COALESCE(ts.total_deposits, (0)::numeric) AS total_deposits,
    COALESCE(ts.total_withdrawals, (0)::numeric) AS total_withdrawals,
    COALESCE(hs.num_positions, 0) AS num_equity_positions,
    COALESCE(hs.avg_position_return_pct, (0)::numeric) AS avg_position_return_pct,
    COALESCE(hs.win_rate_pct, (0)::numeric) AS win_rate_pct,
    COALESCE(hs.total_unrealised_pnl, (0)::numeric) AS total_unrealised_pnl,
    COALESCE(hs.total_gains, (0)::numeric) AS total_gains,
    COALESCE(hs.total_losses, (0)::numeric) AS total_losses,
    COALESCE(ds.estimated_annual_dividend, (0)::numeric) AS estimated_annual_dividend,
    (EXTRACT(day FROM (now() - (ts.last_transaction_date)::timestamp with time zone)))::integer AS days_since_last_activity,
    ts.last_transaction_date,
    ts.first_transaction_date
   FROM (((public.customer c
     LEFT JOIN transaction_summary ts ON ((c.customer_id = ts.customer_id)))
     LEFT JOIN holding_summary hs ON ((c.customer_id = hs.customer_id)))
     LEFT JOIN dividend_summary ds ON ((c.customer_id = ds.customer_id)))
  WHERE ((c.status)::text = 'ACTIVE'::text);


--
-- Name: VIEW vw_fact_trading_activity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_fact_trading_activity IS 'LEGACY. Transaction behaviour. active_months uses the month number, so it cannot exceed 12 and inflates transactions_per_month over multi-year history; estimated_annual_dividend is a flat 2% assumption. Use mv_customer_behaviour and mv_customer_income.';


--
-- Name: COLUMN vw_fact_trading_activity.customer_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.customer_id IS 'Customer keys Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_fact_trading_activity.customer_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.customer_number IS 'Customer keys Caveat: ACTIVE customers only';


--
-- Name: COLUMN vw_fact_trading_activity.total_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.total_transactions IS 'Lifetime transaction count and monthly rate Unit: count. Caveat: active_months extracts the month NUMBER, so January 2025 and January 2026 count once. It can never exceed 12 and transactions_per_month is inflated for any customer with more than a year of history. Use mv_customer_behaviour.trades_per_month';


--
-- Name: COLUMN vw_fact_trading_activity.active_months; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.active_months IS 'Lifetime transaction count and monthly rate Unit: count. Caveat: active_months extracts the month NUMBER, so January 2025 and January 2026 count once. It can never exceed 12 and transactions_per_month is inflated for any customer with more than a year of history. Use mv_customer_behaviour.trades_per_month';


--
-- Name: COLUMN vw_fact_trading_activity.transactions_per_month; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.transactions_per_month IS 'Lifetime transaction count and monthly rate Unit: count. Caveat: active_months extracts the month NUMBER, so January 2025 and January 2026 count once. It can never exceed 12 and transactions_per_month is inflated for any customer with more than a year of history. Use mv_customer_behaviour.trades_per_month';


--
-- Name: COLUMN vw_fact_trading_activity.avg_transaction_amount; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.avg_transaction_amount IS 'Average transaction size and lifetime money in and out Unit: mixed SGD and USD. Caveat: Not currency converted, and counts every transaction type including salary and card payments, so these are banking flows rather than investment flows';


--
-- Name: COLUMN vw_fact_trading_activity.total_deposits; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.total_deposits IS 'Average transaction size and lifetime money in and out Unit: mixed SGD and USD. Caveat: Not currency converted, and counts every transaction type including salary and card payments, so these are banking flows rather than investment flows';


--
-- Name: COLUMN vw_fact_trading_activity.total_withdrawals; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.total_withdrawals IS 'Average transaction size and lifetime money in and out Unit: mixed SGD and USD. Caveat: Not currency converted, and counts every transaction type including salary and card payments, so these are banking flows rather than investment flows';


--
-- Name: COLUMN vw_fact_trading_activity.num_equity_positions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.num_equity_positions IS 'Number of security positions, their average return on cost, and the share showing a gain Unit: count / %. Caveat: Unweighted across positions, so a tiny winner counts as much as the largest holding. Open positions only -- closed trades are not tracked, so this is not a track record';


--
-- Name: COLUMN vw_fact_trading_activity.avg_position_return_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.avg_position_return_pct IS 'Number of security positions, their average return on cost, and the share showing a gain Unit: count / %. Caveat: Unweighted across positions, so a tiny winner counts as much as the largest holding. Open positions only -- closed trades are not tracked, so this is not a track record';


--
-- Name: COLUMN vw_fact_trading_activity.win_rate_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.win_rate_pct IS 'Number of security positions, their average return on cost, and the share showing a gain Unit: count / %. Caveat: Unweighted across positions, so a tiny winner counts as much as the largest holding. Open positions only -- closed trades are not tracked, so this is not a track record';


--
-- Name: COLUMN vw_fact_trading_activity.total_unrealised_pnl; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.total_unrealised_pnl IS 'Mark-to-market P&L split into gains and losses Unit: mixed SGD and USD. Caveat: Currencies added without conversion. Use mv_customer_360.unrealised_pnl_sgd';


--
-- Name: COLUMN vw_fact_trading_activity.total_gains; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.total_gains IS 'Mark-to-market P&L split into gains and losses Unit: mixed SGD and USD. Caveat: Currencies added without conversion. Use mv_customer_360.unrealised_pnl_sgd';


--
-- Name: COLUMN vw_fact_trading_activity.total_losses; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.total_losses IS 'Mark-to-market P&L split into gains and losses Unit: mixed SGD and USD. Caveat: Currencies added without conversion. Use mv_customer_360.unrealised_pnl_sgd';


--
-- Name: COLUMN vw_fact_trading_activity.estimated_annual_dividend; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.estimated_annual_dividend IS 'Assumed annual dividend income from security holdings Unit: mixed SGD and USD. Caveat: A flat 2% assumption applied to every holding regardless of what it is or whether it pays anything. It is not a measurement. mv_customer_income.dividends_12m_sgd holds the dividends actually received';


--
-- Name: COLUMN vw_fact_trading_activity.days_since_last_activity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.days_since_last_activity IS 'First and last transaction and how long since the last one Unit: days / timestamp. Caveat: Covers ACTIVE accounts only, so activity on a closed account is invisible';


--
-- Name: COLUMN vw_fact_trading_activity.last_transaction_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.last_transaction_date IS 'First and last transaction and how long since the last one Unit: days / timestamp. Caveat: Covers ACTIVE accounts only, so activity on a closed account is invisible';


--
-- Name: COLUMN vw_fact_trading_activity.first_transaction_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vw_fact_trading_activity.first_transaction_date IS 'First and last transaction and how long since the last one Unit: days / timestamp. Caveat: Covers ACTIVE accounts only, so activity on a closed account is invisible';


--
-- Name: account account_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account ALTER COLUMN account_id SET DEFAULT nextval('public.account_account_id_seq'::regclass);


--
-- Name: channel_activity activity_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_activity ALTER COLUMN activity_id SET DEFAULT nextval('public.channel_activity_activity_id_seq'::regclass);


--
-- Name: customer customer_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer ALTER COLUMN customer_id SET DEFAULT nextval('public.customer_customer_id_seq'::regclass);


--
-- Name: customer_insight insight_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_insight ALTER COLUMN insight_id SET DEFAULT nextval('public.customer_insight_insight_id_seq'::regclass);


--
-- Name: customer_transaction transaction_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_transaction ALTER COLUMN transaction_id SET DEFAULT nextval('public.customer_transaction_transaction_id_seq'::regclass);


--
-- Name: example_queries example_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.example_queries ALTER COLUMN example_id SET DEFAULT nextval('public.example_queries_example_id_seq'::regclass);


--
-- Name: fixed_deposit fd_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_deposit ALTER COLUMN fd_id SET DEFAULT nextval('public.fixed_deposit_fd_id_seq'::regclass);


--
-- Name: fund_investment investment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fund_investment ALTER COLUMN investment_id SET DEFAULT nextval('public.fund_investment_investment_id_seq'::regclass);


--
-- Name: holding holding_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holding ALTER COLUMN holding_id SET DEFAULT nextval('public.holding_holding_id_seq'::regclass);


--
-- Name: news_research research_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_research ALTER COLUMN research_id SET DEFAULT nextval('public.news_research_research_id_seq'::regclass);


--
-- Name: security security_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security ALTER COLUMN security_id SET DEFAULT nextval('public.security_security_id_seq'::regclass);


--
-- Name: account account_account_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_account_number_key UNIQUE (account_number);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (account_id);


--
-- Name: channel_activity channel_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_activity
    ADD CONSTRAINT channel_activity_pkey PRIMARY KEY (activity_id);


--
-- Name: customer customer_customer_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_customer_number_key UNIQUE (customer_number);


--
-- Name: customer_insight customer_insight_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_insight
    ADD CONSTRAINT customer_insight_pkey PRIMARY KEY (insight_id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- Name: customer_profile customer_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_profile
    ADD CONSTRAINT customer_profile_pkey PRIMARY KEY (customer_id);


--
-- Name: customer_transaction customer_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_transaction
    ADD CONSTRAINT customer_transaction_pkey PRIMARY KEY (transaction_id);


--
-- Name: derivative_contract derivative_contract_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.derivative_contract
    ADD CONSTRAINT derivative_contract_pkey PRIMARY KEY (security_id);


--
-- Name: example_queries example_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.example_queries
    ADD CONSTRAINT example_queries_pkey PRIMARY KEY (example_id);


--
-- Name: fixed_deposit fixed_deposit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_deposit
    ADD CONSTRAINT fixed_deposit_pkey PRIMARY KEY (fd_id);


--
-- Name: fund_investment fund_investment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fund_investment
    ADD CONSTRAINT fund_investment_pkey PRIMARY KEY (investment_id);


--
-- Name: holding holding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holding
    ADD CONSTRAINT holding_pkey PRIMARY KEY (holding_id);


--
-- Name: metric_catalog metric_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metric_catalog
    ADD CONSTRAINT metric_catalog_pkey PRIMARY KEY (object_name, metric_name);


--
-- Name: ml_customer_segment ml_customer_segment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_customer_segment
    ADD CONSTRAINT ml_customer_segment_pkey PRIMARY KEY (customer_id);


--
-- Name: ml_segment_profile ml_segment_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_segment_profile
    ADD CONSTRAINT ml_segment_profile_pkey PRIMARY KEY (segment_id);


--
-- Name: ml_transaction_anomaly ml_transaction_anomaly_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_transaction_anomaly
    ADD CONSTRAINT ml_transaction_anomaly_pkey PRIMARY KEY (transaction_id);


--
-- Name: news_research news_research_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_research
    ADD CONSTRAINT news_research_pkey PRIMARY KEY (research_id);


--
-- Name: ref_duration_assumption ref_duration_assumption_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_duration_assumption
    ADD CONSTRAINT ref_duration_assumption_pkey PRIMARY KEY (match_kind, match_value);


--
-- Name: ref_fx_rate ref_fx_rate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_fx_rate
    ADD CONSTRAINT ref_fx_rate_pkey PRIMARY KEY (currency, as_of_date);


--
-- Name: ref_market_rate ref_market_rate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_market_rate
    ADD CONSTRAINT ref_market_rate_pkey PRIMARY KEY (currency, product);


--
-- Name: ref_model_portfolio ref_model_portfolio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_model_portfolio
    ADD CONSTRAINT ref_model_portfolio_pkey PRIMARY KEY (model_name, bucket);


--
-- Name: ref_underlying_level ref_underlying_level_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_underlying_level
    ADD CONSTRAINT ref_underlying_level_pkey PRIMARY KEY (underlying_symbol);


--
-- Name: security security_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security
    ADD CONSTRAINT security_pkey PRIMARY KEY (security_id);


--
-- Name: security security_symbol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security
    ADD CONSTRAINT security_symbol_key UNIQUE (symbol);


--
-- Name: idx_account_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_account_customer ON public.account USING btree (customer_id);


--
-- Name: idx_channel_activity_customer_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_channel_activity_customer_time ON public.channel_activity USING btree (customer_id, activity_time DESC);


--
-- Name: idx_channel_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_channel_customer ON public.channel_activity USING btree (customer_id);


--
-- Name: idx_channel_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_channel_time ON public.channel_activity USING btree (activity_time);


--
-- Name: idx_customer_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_number ON public.customer USING btree (customer_number);


--
-- Name: idx_customer_segment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_segment ON public.customer USING btree (customer_segment);


--
-- Name: idx_customer_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_status ON public.customer USING btree (status);


--
-- Name: idx_derivative_expiry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_derivative_expiry ON public.derivative_contract USING btree (expiry_date);


--
-- Name: idx_derivative_underlying; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_derivative_underlying ON public.derivative_contract USING btree (underlying_symbol);


--
-- Name: idx_fd_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fd_customer ON public.fixed_deposit USING btree (customer_id);


--
-- Name: idx_fixed_deposit_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fixed_deposit_customer ON public.fixed_deposit USING btree (customer_id);


--
-- Name: idx_fund_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fund_customer ON public.fund_investment USING btree (customer_id);


--
-- Name: idx_fund_investment_customer_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fund_investment_customer_date ON public.fund_investment USING btree (customer_id, as_of_date DESC);


--
-- Name: idx_holding_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_holding_customer ON public.holding USING btree (customer_id);


--
-- Name: idx_holding_customer_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_holding_customer_date ON public.holding USING btree (customer_id, as_of_date DESC);


--
-- Name: idx_insight_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_insight_customer ON public.customer_insight USING btree (customer_id);


--
-- Name: idx_ml_anomaly_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ml_anomaly_customer ON public.ml_transaction_anomaly USING btree (customer_id);


--
-- Name: idx_news_embedding_hnsw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_embedding_hnsw ON public.news_research USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_news_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_published ON public.news_research USING btree (published_at DESC);


--
-- Name: idx_news_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_symbol ON public.news_research USING btree (security_symbol);


--
-- Name: idx_research_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_research_symbol ON public.news_research USING btree (security_symbol);


--
-- Name: idx_security_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_symbol ON public.security USING btree (symbol);


--
-- Name: idx_transaction_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_account ON public.customer_transaction USING btree (account_id);


--
-- Name: idx_transaction_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_date ON public.customer_transaction USING btree (transaction_date);


--
-- Name: idx_transaction_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_product ON public.customer_transaction USING btree (product_type);


--
-- Name: idx_transaction_security; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_security ON public.customer_transaction USING btree (security_id);


--
-- Name: mv_customer_360_customer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mv_customer_360_customer_id_idx ON public.mv_customer_360 USING btree (customer_id);


--
-- Name: mv_customer_360_full_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mv_customer_360_full_name_idx ON public.mv_customer_360 USING btree (full_name);


--
-- Name: mv_customer_behaviour_customer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mv_customer_behaviour_customer_id_idx ON public.mv_customer_behaviour USING btree (customer_id);


--
-- Name: mv_customer_exposure_customer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mv_customer_exposure_customer_id_idx ON public.mv_customer_exposure USING btree (customer_id);


--
-- Name: mv_customer_income_customer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mv_customer_income_customer_id_idx ON public.mv_customer_income USING btree (customer_id);


--
-- Name: mv_customer_rate_sensitivity_customer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mv_customer_rate_sensitivity_customer_id_idx ON public.mv_customer_rate_sensitivity USING btree (customer_id);


--
-- Name: mv_position_sgd_customer_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mv_position_sgd_customer_id_idx ON public.mv_position_sgd USING btree (customer_id);


--
-- Name: mv_position_sgd_position_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mv_position_sgd_position_id_idx ON public.mv_position_sgd USING btree (position_id);


--
-- Name: ux_news_research_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_news_research_url ON public.news_research USING btree (url) WHERE (url IS NOT NULL);


--
-- Name: account account_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: channel_activity channel_activity_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_activity
    ADD CONSTRAINT channel_activity_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.account(account_id);


--
-- Name: channel_activity channel_activity_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_activity
    ADD CONSTRAINT channel_activity_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: customer_insight customer_insight_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_insight
    ADD CONSTRAINT customer_insight_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: customer_profile customer_profile_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_profile
    ADD CONSTRAINT customer_profile_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: customer_transaction customer_transaction_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_transaction
    ADD CONSTRAINT customer_transaction_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.account(account_id);


--
-- Name: customer_transaction customer_transaction_security_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_transaction
    ADD CONSTRAINT customer_transaction_security_id_fkey FOREIGN KEY (security_id) REFERENCES public.security(security_id);


--
-- Name: derivative_contract derivative_contract_security_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.derivative_contract
    ADD CONSTRAINT derivative_contract_security_id_fkey FOREIGN KEY (security_id) REFERENCES public.security(security_id);


--
-- Name: fixed_deposit fixed_deposit_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_deposit
    ADD CONSTRAINT fixed_deposit_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: fund_investment fund_investment_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fund_investment
    ADD CONSTRAINT fund_investment_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: holding holding_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holding
    ADD CONSTRAINT holding_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: holding holding_security_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holding
    ADD CONSTRAINT holding_security_id_fkey FOREIGN KEY (security_id) REFERENCES public.security(security_id);


--
-- Name: ml_customer_segment ml_customer_segment_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_customer_segment
    ADD CONSTRAINT ml_customer_segment_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: ml_transaction_anomaly ml_transaction_anomaly_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_transaction_anomaly
    ADD CONSTRAINT ml_transaction_anomaly_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: ml_transaction_anomaly ml_transaction_anomaly_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_transaction_anomaly
    ADD CONSTRAINT ml_transaction_anomaly_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.customer_transaction(transaction_id);


--
-- PostgreSQL database dump complete
--


