# Healthcare Data Pipeline with dbt and Google Cloud

This guide will help you set up a complete healthcare data pipeline using dbt and Google Cloud BigQuery to ingest CSV data from healthcare GitHub repositories.

## 🏗️ Project Structure

```
my_project/
├── models/
│   ├── staging/           # Data cleaning and standardization
│   │   ├── stg_patients.sql
│   │   ├── stg_visits.sql
│   │   └── stg_lab_results.sql
│   ├── marts/             # Business logic and aggregations
│   │   ├── patient_summary.sql
│   │   └── department_metrics.sql
│   ├── sources.yml        # Source table definitions
│   ├── staging/schema.yml # Staging model documentation
│   └── marts/schema.yml   # Mart model documentation
├── seeds/                 # CSV data files
│   ├── patients.csv
│   ├── visits.csv
│   └── lab_results.csv
├── macros/                # Reusable SQL functions
│   └── healthcare_utils.sql
└── dbt_project.yml        # Project configuration
```

## 🚀 Quick Start

### 1. Prerequisites

- Python 3.8+ with virtual environment
- Google Cloud Platform account
- dbt installed (`pip install dbt-bigquery`)

### 2. Google Cloud Setup

#### Create a BigQuery Dataset

```bash
# Using gcloud CLI
bq mk --dataset --location=US your-gcp-project-id:healthcare_data_dev
bq mk --dataset --location=US your-gcp-project-id:healthcare_data_prod
```

#### Service Account Setup

1. Go to Google Cloud Console → IAM & Admin → Service Accounts
2. Create a new service account with BigQuery permissions
3. Download the JSON key file
4. Update the `profiles.yml` file with your project details

### 3. Configure dbt

Update the `profiles.yml` file with your Google Cloud details:

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: your-gcp-project-id # Replace with your project ID
      dataset: healthcare_data_dev
      keyfile: /path/to/your/service-account-key.json
      location: US
```

### 4. Load CSV Data

```bash
# Navigate to your dbt project
cd my_project

# Load seed data (CSV files)
dbt seed

# Run the models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## 📊 Data Models

### Staging Models

- **stg_patients**: Cleaned patient demographics and contact info
- **stg_visits**: Standardized visit records with clinical data
- **stg_lab_results**: Processed laboratory test results

### Mart Models

- **patient_summary**: Comprehensive patient analytics
- **department_metrics**: Department performance metrics

## 🔧 Customization for Healthcare GitHub Repos

### 1. Download CSV Data from GitHub

```bash
# Example: Download from a healthcare GitHub repository
curl -o my_project/seeds/patients.csv \
  "https://raw.githubusercontent.com/healthcare-repo/data/main/patients.csv"

curl -o my_project/seeds/visits.csv \
  "https://raw.githubusercontent.com/healthcare-repo/data/main/visits.csv"

curl -o my_project/seeds/lab_results.csv \
  "https://raw.githubusercontent.com/healthcare-repo/data/main/lab_results.csv"
```

### 2. Update Source Configuration

Modify `models/sources.yml` to match your CSV structure:

```yaml
sources:
  - name: healthcare
    tables:
      - name: your_csv_table
        description: "Description of your data"
        columns:
          - name: column_name
            description: "Column description"
            tests:
              - unique
              - not_null
```

### 3. Create Custom Models

Add new models in the appropriate directory:

```sql
-- models/staging/stg_your_data.sql
{{ config(materialized='table') }}

select
    id,
    cleaned_column,
    calculated_field
from {{ source('healthcare', 'your_csv_table') }}
```

## 🧪 Testing and Quality

### Built-in Tests

- **Uniqueness**: Ensures primary keys are unique
- **Not null**: Validates required fields
- **Relationships**: Checks foreign key integrity
- **Accepted values**: Validates categorical data

### Custom Tests

Create custom tests in `tests/` directory:

```sql
-- tests/assert_valid_ages.sql
select *
from {{ ref('stg_patients') }}
where age < 0 or age > 150
```

## 📈 Analytics and Insights

### Key Metrics Available

- Patient utilization patterns
- Department performance metrics
- Lab result trends and abnormalities
- Financial analytics (revenue, insurance coverage)
- Clinical quality indicators

### Sample Queries

```sql
-- High-risk patients (multiple emergency visits)
select *
from {{ ref('patient_summary') }}
where emergency_visits > 2
  and utilization_category = 'High Utilizer'

-- Department efficiency analysis
select *
from {{ ref('department_metrics') }}
where efficiency_category = 'Efficient'
order by completion_rate desc
```

## 🔄 Automation and Scheduling

### GitHub Actions (Recommended)

Create `.github/workflows/dbt-pipeline.yml`:

```yaml
name: Healthcare Data Pipeline
on:
  schedule:
    - cron: "0 6 * * *" # Daily at 6 AM
  workflow_dispatch:

jobs:
  dbt-run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: "3.8"
      - name: Install dbt
        run: pip install dbt-bigquery
      - name: Run dbt
        run: |
          cd my_project
          dbt seed
          dbt run
          dbt test
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
```

### Google Cloud Scheduler

1. Create a Cloud Function to run dbt
2. Schedule it with Cloud Scheduler
3. Set up monitoring and alerting

## 🛠️ Advanced Features

### Incremental Models

For large datasets, use incremental models:

```sql
{{ config(
    materialized='incremental',
    unique_key='patient_id',
    on_schema_change='fail'
) }}

select *
from {{ source('healthcare', 'patients') }}
{% if is_incremental() %}
  where updated_date > (select max(updated_date) from {{ this }})
{% endif %}
```

### Snapshots

Track changes over time:

```sql
-- snapshots/patient_snapshots.sql
{% snapshot patient_snapshots %}
    {{
        config(
          target_schema='snapshots',
          unique_key='patient_id',
          strategy='timestamp',
          updated_at='updated_date',
        )
    }}
    select * from {{ source('healthcare', 'patients') }}
{% endsnapshot %}
```

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Healthcare Data Standards](https://www.hl7.org/)
- [ICD-10 Codes](https://www.cdc.gov/nchs/icd/icd10cm.htm)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
