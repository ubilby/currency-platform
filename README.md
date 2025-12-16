# Currency Data Platform

> Production-grade platform for collecting and analyzing currency exchange rates with event-driven architecture

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-compose-2496ED.svg)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791.svg)](https://www.postgresql.org/)
[![ClickHouse](https://img.shields.io/badge/ClickHouse-24-FFCC01.svg)](https://clickhouse.com/)

## 🎯 Project Status

**Month 1: Infrastructure Foundation** ✅ (In Progress)

- [x] Docker Compose setup
- [x] PostgreSQL with metadata schemas
- [x] ClickHouse with time-series tables
- [ ] RabbitMQ message queue (Next)
- [ ] Redis cache & idempotency (Next)
- [ ] Basic monitoring setup

## 🚀 Quick Start

### Prerequisites

- Docker Desktop (with Docker Compose)
- Make (comes with macOS/Linux)
- 4GB+ RAM available

### Installation

```bash
# 1. Clone repository
git clone https://github.com/ubilby/currency-platform.git
cd currency-platform

# 2. Setup environment
cp .env.example .env
# Edit .env with your settings (optional for development)

# 3. Start all services
make up

# 4. Check status
make ps
make health

# 5. Access services
# - Adminer (Database UI): http://localhost:8080
# - ClickHouse HTTP API: http://localhost:8123/ping
# - PostgreSQL: localhost:5432
# - ClickHouse Native: localhost:9000
```

### Stopping Services

```bash
make down        # Stop all services
make restart     # Restart all services
make clean       # Remove all data (WARNING: destructive!)
```

## 📦 Architecture

### Current Infrastructure (Month 1)

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  ┌─────────────┐      ┌──────────────────┐    │
│  │  Adminer    │─────▶│   PostgreSQL     │    │
│  │  (Web UI)   │      │   (Metadata)     │    │
│  └─────────────┘      └──────────────────┘    │
│                                                 │
│                       ┌──────────────────┐     │
│                       │   ClickHouse     │     │
│                       │  (Time-Series)   │     │
│                       └──────────────────┘     │
│                                                 │
└─────────────────────────────────────────────────┘
          Docker Network: currency_backend
```

### Technology Stack

#### Databases
- **PostgreSQL 16** - Metadata & Configuration Store
  - Extensions: `uuid-ossp`, `pg_stat_statements`
  - Schemas: `metadata`, `config`
  - Tables: `data_sources`, `currency_pairs`, `ingestion_jobs`, `settings`

- **ClickHouse 24** - Time-Series Data Store
  - Database: `currency_data`
  - Main table: `exchange_rates` (partitioned by month, TTL 365 days)
  - Materialized views: `daily_rates_mv` (aggregated daily data)
  - Metrics: `data_quality_metrics`

#### Infrastructure
- **Docker Compose** - Container orchestration
- **Adminer** - Database management UI
- **Make** - Task automation

## 🛠️ Available Commands

```bash
make help       # Show all available commands
make up         # Start all services
make down       # Stop all services
make logs       # Show logs from all services
make logs-postgres    # Show PostgreSQL logs
make logs-clickhouse  # Show ClickHouse logs
make ps         # Show container status
make health     # Check service health
make restart    # Restart all services
make db-init    # Reinitialize databases (destructive!)
make clean      # Remove all containers and volumes
```

## 📊 Database Schemas

### PostgreSQL - Metadata

**Schema: `metadata`**
- `data_sources` - External data source configurations
- `currency_pairs` - Active currency pair tracking
- `ingestion_jobs` - Job execution history

**Schema: `config`**
- `settings` - Platform configuration (key-value store)

### ClickHouse - Time-Series Data

**Database: `currency_data`**
- `exchange_rates` - Main table for currency rates
  - Partitioned by month (`YYYYMM`)
  - TTL: 365 days
  - Indexed by: `base_currency`, `quote_currency`, `timestamp`, `source`
  
- `daily_rates_mv` - Aggregated daily OHLC data
  - Materialized view with automatic updates
  - TTL: 730 days (2 years)

## 🔍 Accessing Databases

### Adminer (Web UI)

URL: http://localhost:8080

**PostgreSQL Connection:**
- System: `PostgreSQL`
- Server: `postgres`
- Username: `currency_user`
- Password: `change_me_in_production`
- Database: `currency_platform`

### CLI Access

**PostgreSQL:**
```bash
docker exec -it currency_postgres psql -U currency_user -d currency_platform

# Examples:
\dn                              # List schemas
\dt metadata.*                   # List tables in metadata schema
SELECT * FROM config.settings;   # Query settings
```

**ClickHouse:**
```bash
docker exec -it currency_clickhouse clickhouse-client

# Examples:
SHOW DATABASES;
USE currency_data;
SHOW TABLES;
DESCRIBE exchange_rates;
SELECT count() FROM exchange_rates;
```

**ClickHouse HTTP API:**
```bash
# Ping
curl http://localhost:8123/ping

# Query
curl "http://localhost:8123/?query=SELECT+version()"

# Show tables
curl "http://localhost:8123/?query=SHOW+TABLES+FROM+currency_data"
```

## 🗂️ Project Structure

```
currency-platform/
├── docker/                    # Docker configurations
│   ├── docker-compose.yml     # Main compose file
│   ├── postgres/
│   │   └── init.sql           # PostgreSQL schema initialization
│   └── clickhouse/
│       ├── init.sql           # ClickHouse schema initialization
│       ├── config.xml         # Server configuration
│       └── users.xml          # User management
├── .env.example               # Environment template
├── Makefile                   # Task automation
├── README.md                  # This file
└── LICENSE                    # MIT License
```

## 🔐 Security Notes

**Development Setup:**
- Default passwords are in `.env.example`
- Change all passwords in production
- `.env` file is gitignored

**Production Recommendations:**
- Use strong passwords
- Enable SSL/TLS for all connections
- Restrict network access
- Regular security updates
- Backup encryption

## 📈 Resource Requirements

### Minimum (Development)
- RAM: 2GB available
- CPU: 2 cores
- Disk: 10GB free space

### Recommended (Development)
- RAM: 4GB available
- CPU: 4 cores
- Disk: 20GB free space

### Current Limits (Docker)
- PostgreSQL: 512MB RAM limit
- ClickHouse: 1GB RAM limit
- Adminer: 128MB RAM limit

## 🗺️ Roadmap

### Month 1: Infrastructure Foundation ✅
- [x] Docker Compose setup
- [x] PostgreSQL with schemas
- [x] ClickHouse with time-series tables
- [ ] RabbitMQ integration
- [ ] Redis cache setup
- [ ] Basic health checks and monitoring

### Month 2: Data Ingestion (Planned)
- [ ] MOEX API integration
- [ ] Exchange rate API clients
- [ ] Data validation and quality checks
- [ ] Retry mechanisms
- [ ] Idempotency handling

### Month 3-6: Advanced Features (Planned)
- [ ] Real-time data streaming
- [ ] Analytics API
- [ ] Monitoring and alerting
- [ ] Data retention policies
- [ ] Performance optimization

See [docs/roadmap.md](docs/roadmap.md) for detailed timeline.

## 🤝 Contributing

This is a personal learning project, but feedback and suggestions are welcome!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built as a learning project for data engineering and infrastructure
- Inspired by production-grade data platforms
- Part of a 6-month learning roadmap

---

**Status:** 🚧 Active Development | Month 1 (Week 2/4)