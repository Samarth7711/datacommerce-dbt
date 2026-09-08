# Enterprise E-Commerce Modern Data Platform

A production-grade, enterprise data platform built with **dbt Core (v1.12)** and **Snowflake**, implementing medallion architecture, incremental merge strategies, automated CI/CD with Slim CI, Snowflake FinOps controls, and the dbt Semantic Layer.

---

## Architecture Overview
[Raw Sources: Snowflake]
├── jaffle_shop.customers
├── jaffle_shop.orders
└── stripe.payments
│
▼
[Bronze / Staging Layer (Views)]
├── stg_jaffle_shop__customers
├── stg_jaffle_shop__orders
└── stg_stripe__payments
│
├───► [SCD Type 2: snap_customers]
▼
[Gold / Business Marts (Transient Tables)]
├── fct_orders (Incremental Merge + Lookback + Dynamic Jinja Pivot)
└── dim_customers (Enriched Customer Segmentation)
│
├───► [metricflow_time_spine (Calendar Spine)]
▼
[Semantic / Metric Layer]
└── semantic_orders
├── Gross Revenue (USD)
├── Total Orders
└── Average Order Value (AOV)

---

## Key Technical Features

### 1. Robust Incremental Modeling (`fct_orders`)
* **Strategy**: Snowflake native `merge` strategy partitioned and clustered on `order_date`.
* **Late-Arriving Fact Handling**: 3-day lookback window (`order_date >= max(order_date) - interval '3 days'`) to safely reprocess updated order statuses and late payment settlements.
* **Jinja Macro Metaprogramming**: Dynamic payment channel extraction (`pivot_payments`) avoiding repeated manual SQL expressions.

### 2. Slowly Changing Dimensions (SCD Type 2)
* **Snapshot (`snap_customers`)**: Implements `check` strategy tracking customer record mutations over time with automatic invalidation on source deletion (`invalidate_hard_deletes: true`).

### 3. FinOps & Compute Governance
* **Aggressive Warehouse Auto-Suspend**: Configured `DEV_WH` to `AUTO_SUSPEND = 60` with `AUTO_RESUME = TRUE` to eliminate idle compute overhead.
* **Spend Protection**: Attached credit resource monitors with automated suspension at 100% threshold.
* **Storage Optimization**: Marts configured as `transient: true` to bypass 7-day Fail-Safe storage costs for rebuildable analytical models.
* **Dynamic Query Tagging**: Macro hooks append session tags (`{"dbt_model": "...", "environment": "dev"}`) into Snowflake's `QUERY_HISTORY` for granular cost attribution.

### 4. Enterprise Quality Assurance & Testing
* **Schema Integrity**: `unique`, `not_null`, and referential integrity (`relationships`) across staging and marts.
* **Domain Assertions**: Custom generic macro test (`is_positive`) asserting non-negative revenue and balances.
* **Value Whitelisting**: `accepted_values` validation on dynamic customer segments (`VIP`, `Regular`, `Prospect`).

### 5. Automated CI/CD & Slim CI
* **GitHub Actions Workflow**: Runs on every pull request targeting `master`.
* **State-Comparison (Slim CI)**: Leverages `dbt build --select state:modified+ --defer` comparing PR branches against production `manifest.json` artifacts, building and testing only changed models.
* **Environment Isolation**: Parameterized `profiles.yml` via `env_var()` deploying PR executions into ephemeral schemas (`DBT_CI_PR_<NUMBER>`).

### 6. dbt Semantic Layer (MetricFlow)
* Generated a continuous daily `metricflow_time_spine` spanning 2020–2030.
* Standardized enterprise business metrics (`gross_revenue`, `total_orders`, `average_order_value`), providing a centralized source of truth across downstream BI tools.

---

## Project Structure

```text
datacommerce-dbt/
├── .github/
│   └── workflows/
│       └── dbt_ci.yml              # Automated GitHub Actions Slim CI pipeline
├── analytics/
│   ├── analyses/
│   │   └── test_metric_query.sql   # Metric compile validation queries
│   ├── macros/
│   │   ├── pivot_payments.sql      # Dynamic SQL Jinja pivot macro
│   │   ├── query_tag.sql           # Dynamic Snowflake session tagger
│   │   └── test_is_positive.sql    # Custom domain-specific data assertion
│   ├── models/
│   │   ├── marts/core/             # Fact, dimension, time spine, and semantic models
│   │   └── staging/                # Medallion 1:1 view wrappers with type casting
│   ├── snapshots/
│   │   └── snap_customers.sql      # SCD Type 2 tracking table
│   ├── dbt_project.yml             # Global configuration, FinOps rules, hooks
│   └── profiles.yml                # Parameterized credential profile
└── README.md