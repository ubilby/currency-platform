-- ============================================
-- Currency Platform - PostgreSQL Initialization
-- ============================================
-- This script run once at first time

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create schemas for tables
CREATE SCHEMA IF NOT EXISTS metadata;
CREATE SCHEMA IF NOT EXISTS config;

-- ============================================
-- Metadata Schema
-- ============================================

-- Data source table
CREATE TABLE metadata.data_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    type VARCHAR(50) NOT NULL, -- 'exchange', 'moex', 'api'
    base_url TEXT,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Configuration currency pair
CREATE TABLE metadata.currency_pairs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    base_currency VARCHAR(10) NOT NULL,
    quote_currency VARCHAR(10) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(base_currency, quote_currency)
);

-- Maintaingn ingestion jobs table
CREATE TABLE metadata.ingestion_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID REFERENCES metadata.data_sources(id),
    status VARCHAR(20) NOT NULL, -- 'pending', 'running', 'completed', 'failed'
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Config Schema  
-- ============================================

-- Key-value config table
CREATE TABLE config.settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO config.settings (key, value, description) VALUES
    ('ingestion_interval_seconds', '60', 'How often to fetch new data'),
    ('retention_days', '365', 'How long to keep data in ClickHouse'),
    ('max_retry_attempts', '3', 'Max retries for failed ingestions');

-- ============================================
-- Performance indexes
-- ============================================

CREATE INDEX idx_data_sources_active ON metadata.data_sources(is_active);
CREATE INDEX idx_currency_pairs_active ON metadata.currency_pairs(is_active);
CREATE INDEX idx_ingestion_jobs_status ON metadata.ingestion_jobs(status);
CREATE INDEX idx_ingestion_jobs_created ON metadata.ingestion_jobs(created_at DESC);

-- ============================================
-- update_at trigers 
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_data_sources_updated_at
    BEFORE UPDATE ON metadata.data_sources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at
    BEFORE UPDATE ON config.settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Ready!
-- ============================================

COMMENT ON SCHEMA metadata IS 'Метаданные источников данных и джобов';
COMMENT ON SCHEMA config IS 'Конфигурация платформы';

-- Show statistic
SELECT 
    'Initialization completed!' as status,
    COUNT(*) as tables_created
FROM information_schema.tables 
WHERE table_schema IN ('metadata', 'config');