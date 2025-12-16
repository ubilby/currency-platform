-- ============================================
-- Currency Platform - ClickHouse Initialization
-- ============================================
-- Time-series curency data

-- Create db
CREATE DATABASE IF NOT EXISTS currency_data;

-- ============================================
-- Main table: exchange_rates
-- ============================================
-- Month partition
-- TTL for automatic clear old data

CREATE TABLE IF NOT EXISTS currency_data.exchange_rates
(
    -- Temporal dimensions
    timestamp DateTime64(3) CODEC(Delta, ZSTD),   -- Miliseconds precision
    date Date MATERIALIZED toDate(timestamp),     -- For partitions
    
    -- Currency pair
    base_currency LowCardinality(String),         -- USD, EUR, RUB
    quote_currency LowCardinality(String),        -- USD, EUR, RUB
    
    -- Price data
    rate Decimal64(8),                            -- Exchange rate
    volume Nullable(Decimal64(4)),                -- Trading volume (if any)
    
    -- Metadata
    source LowCardinality(String),                -- 'moex', 'binance', 'exchangeapi'
    source_id String,                             -- ID source record
    
    -- Data quality
    is_interpolated UInt8 DEFAULT 0,              -- 0 = real data, 1 = interpolated
    quality_score Nullable(Float32),              -- Data quality assessment
    
    -- Technical
    ingestion_timestamp DateTime DEFAULT now(),   -- Timestamp data
    
    -- Indexes for quick launh
    INDEX idx_source source TYPE minmax GRANULARITY 4,
    INDEX idx_base base_currency TYPE set(0) GRANULARITY 1,
    INDEX idx_quote quote_currency TYPE set(0) GRANULARITY 1
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(date)                       -- Month partitions
PRIMARY KEY (base_currency, quote_currency, timestamp)
ORDER BY (base_currency, quote_currency, timestamp, source)
TTL date + INTERVAL 365 DAY                       -- Delete older than year
SETTINGS 
    index_granularity = 8192,
    storage_policy = 'default';

-- ============================================
-- Materialized view: daily_rates

-- ============================================
-- Agregation by days for quick launches

CREATE TABLE IF NOT EXISTS currency_data.daily_rates_mv
(
    date Date,
    base_currency LowCardinality(String),
    quote_currency LowCardinality(String),
    source LowCardinality(String),
    
    -- Agregates
    rate_open SimpleAggregateFunction(min, Decimal64(8)),
    rate_close SimpleAggregateFunction(max, Decimal64(8)),
    rate_high SimpleAggregateFunction(max, Decimal64(8)),
    rate_low SimpleAggregateFunction(min, Decimal64(8)),
    rate_avg AggregateFunction(avg, Decimal64(8)),
    
    volume_total AggregateFunction(sum, Nullable(Decimal64(4))),
    records_count AggregateFunction(count, UInt64)
)
ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(date)
PRIMARY KEY (date, base_currency, quote_currency, source)
ORDER BY (date, base_currency, quote_currency, source)
TTL date + INTERVAL 730 DAY;                      -- Keep agregates for 2 years

-- Create Materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS currency_data.daily_rates_mv_view
TO currency_data.daily_rates_mv
AS SELECT
    date,
    base_currency,
    quote_currency,
    source,
    minSimpleState(rate) as rate_open,
    maxSimpleState(rate) as rate_close,
    maxSimpleState(rate) as rate_high,
    minSimpleState(rate) as rate_low,
    avgState(rate) as rate_avg,
    sumState(volume) as volume_total,
    countState(*) as records_count
FROM currency_data.exchange_rates
GROUP BY date, base_currency, quote_currency, source;

-- ============================================
-- Data Quality Metrics Table
-- ============================================

CREATE TABLE IF NOT EXISTS currency_data.data_quality_metrics
(
    timestamp DateTime,
    date Date MATERIALIZED toDate(timestamp),
    
    source LowCardinality(String),
    metric_name LowCardinality(String),            -- 'latency', 'missing_data', 'anomaly_count'
    metric_value Float64,
    
    details String                                 -- JSON with details
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, source, metric_name, timestamp)
TTL date + INTERVAL 90 DAY;

-- ============================================
-- Ready!
-- ============================================

-- Check created tables
SELECT 
    name,
    engine,
    partition_key,
    sorting_key,
    formatReadableSize(total_bytes) as size
FROM system.tables
WHERE database = 'currency_data'
ORDER BY name;