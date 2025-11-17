# Healthcare Data Pipeline

A complete end-to-end healthcare analytics data pipeline using dbt, Google Cloud BigQuery, and Looker Studio for creating interactive dashboards and insights.

## Overview

This project demonstrates a modern data engineering approach to healthcare analytics using industry-standard tools and best practices. It includes data ingestion from CSV files, transformation using dbt models, storage in Google Cloud BigQuery, and visualization through Looker Studio dashboards.

## Features

- **Data Transformation with dbt**: Modular SQL transformations organized into staging and mart layers
- **Google Cloud BigQuery**: Scalable cloud data warehouse for healthcare data
- **Looker Studio Integration**: Interactive dashboards for healthcare analytics
- **Automated Setup Scripts**: Python scripts to streamline GCP and Looker configuration
- **Data Quality Testing**: Built-in dbt tests for data validation
- **Healthcare-Specific Models**: Pre-built models for patient demographics, visits, lab results, and department metrics

## Project Structure

```
dataEngineeringPractice/
├── my_project/                   # dbt project root
│   ├── models/
│   │   ├── staging/             # Data cleaning and standardization
│   │   │   ├── stg_patients.sql
│   │   │   ├── stg_visits.sql
│   │   │   └── stg_lab_results.sql
│   │   ├── marts/               # Business logic and aggregations
│   │   │   ├── patient_summary.sql
│   │   │   └── department_metrics.sql
│   │   ├── sources.yml          # Source table definitions
│   │   └── schema.yml           # Model documentation
│   ├── seeds/                   # CSV data files
│   │   ├── patients.csv
│   │   ├── visits.csv
│   │   └── lab_results.csv
│   ├── macros/                  # Reusable SQL functions
│   ├── tests/                   # Custom data tests
│   └── dbt_project.yml          # Project configuration
├── setup_gcp_looker.py          # Automated GCP and Looker setup
├── quick_setup.py               # Quick configuration script
├── setup_pipeline.py            # Pipeline setup automation
├── profiles.yml                 # dbt profile configuration
├── COMPLETE_SETUP_GUIDE.md      # Detailed setup instructions
├── HEALTHCARE_DBT_SETUP.md      # Healthcare-specific dbt setup
└── LOOKER_SETUP_GUIDE.md        # Looker Studio dashboard guide
```

## Quick Start

### Prerequisites

- Python 3.8 or higher
- Google Cloud Platform account
- dbt-bigquery adapter installed
- Virtual environment (recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/johnlukespeight/HealthCarePipeline.git
   cd HealthCarePipeline
   ```

2. **Set up Python virtual environment**
   ```bash
   python -m venv dbt_venv
   source dbt_venv/bin/activate  # On Windows: dbt_venv\Scripts\activate
   pip install dbt-bigquery
   ```

3. **Configure Google Cloud Platform**

   Run the automated setup script:
   ```bash
   python setup_gcp_looker.py
   ```

   Or follow the manual steps in [COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md)

4. **Configure dbt profiles**
   ```bash
   python quick_setup.py
   ```

   Or manually update `~/.dbt/profiles.yml` with your GCP project details.

5. **Test the connection**
   ```bash
   cd my_project
   dbt debug
   ```

6. **Run the pipeline**
   ```bash
   # Load seed data
   dbt seed

   # Run transformations
   dbt run

   # Run tests
   dbt test

   # Generate and view documentation
   dbt docs generate
   dbt docs serve
   ```

## Data Models

### Staging Models
Clean and standardize raw data:
- **stg_patients**: Patient demographics, contact information, and insurance details
- **stg_visits**: Visit records with clinical data and diagnoses
- **stg_lab_results**: Laboratory test results with standardized values

### Mart Models
Business-focused aggregations and analytics:
- **patient_summary**: Comprehensive patient analytics including visit counts, utilization patterns, and risk categories
- **department_metrics**: Department performance metrics including patient volumes, efficiency, and completion rates

## Analytics Capabilities

### Key Metrics
- Patient utilization patterns (High/Medium/Low utilizers)
- Department performance and efficiency
- Lab result trends and abnormalities
- Length of stay analysis
- Insurance coverage distribution
- Age and gender demographics

### Sample Dashboards
- **Executive Summary**: High-level KPIs and trends
- **Clinical Operations**: Real-time operational metrics
- **Patient Demographics**: Population health insights
- **Department Performance**: Efficiency and quality metrics
- **Lab Results Analysis**: Diagnostic trends and critical values

## Setup Guides

Detailed documentation is available for each component:

- **[COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md)**: Step-by-step guide for setting up dbt, GCP, and Looker Studio
- **[HEALTHCARE_DBT_SETUP.md](HEALTHCARE_DBT_SETUP.md)**: Healthcare-specific dbt configuration and customization
- **[LOOKER_SETUP_GUIDE.md](LOOKER_SETUP_GUIDE.md)**: Creating interactive dashboards in Looker Studio

## Configuration Files

### profiles.yml
Contains dbt connection settings for BigQuery:
```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: your-gcp-project-id
      dataset: healthcare_data_dev
      keyfile: /path/to/service-account-key.json
      location: US
```

### dbt_project.yml
Project-specific configurations including model materialization strategies and variable definitions.

## Automation Scripts

### setup_gcp_looker.py
Automated script to:
- Enable required GCP APIs
- Create BigQuery datasets
- Set up service accounts
- Configure IAM permissions
- Initialize Looker Studio connection

### quick_setup.py
Quick configuration script for:
- Updating dbt profiles
- Validating credentials
- Testing BigQuery connections

## Data Quality

The project includes comprehensive data quality tests:
- **Uniqueness tests**: Ensure primary keys are unique
- **Not null tests**: Validate required fields
- **Relationship tests**: Check foreign key integrity
- **Accepted values tests**: Validate categorical data
- **Custom tests**: Healthcare-specific business logic validation

## Best Practices

- **Modular design**: Separate staging and mart layers for maintainability
- **Documentation**: All models include descriptions and column-level documentation
- **Testing**: Comprehensive test coverage for data quality
- **Version control**: Git-based workflow for collaboration
- **Security**: Service account authentication with least-privilege access
- **Scalability**: Incremental models for large datasets

## Technologies Used

- **dbt (data build tool)**: SQL-based data transformation framework
- **Google Cloud BigQuery**: Cloud data warehouse
- **Looker Studio**: Business intelligence and dashboards
- **Python**: Automation and configuration scripts
- **SQL**: Data transformation logic
- **Git**: Version control

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues or questions:
1. Check the troubleshooting sections in the setup guides
2. Review BigQuery logs for pipeline issues
3. Verify service account permissions and authentication
4. Open an issue on GitHub

## Acknowledgments

This project uses synthetic healthcare data for demonstration purposes. All data is simulated and does not contain real patient information.

---

**Ready to get started?** Follow the [COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md) to set up your healthcare data pipeline!
