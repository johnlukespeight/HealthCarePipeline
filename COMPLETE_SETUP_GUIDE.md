# 🏥 Complete Setup Guide: dbt + Google Cloud + Looker Studio

## 🎯 Overview

This guide will help you set up your healthcare data pipeline with dbt, Google Cloud BigQuery, and Looker Studio for creating interactive dashboards.

## ✅ Prerequisites Checklist

- [ ] Google Cloud Platform account
- [ ] Python 3.8+ installed
- [ ] Virtual environment activated (`dbt_venv`)
- [ ] dbt-bigquery adapter installed

## 🚀 Step-by-Step Setup

### Step 1: Google Cloud Platform Setup

#### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name: `healthcare-analytics` (or your preferred name)
4. **Note your Project ID** - you'll need this later!

#### 1.2 Enable Required APIs

Run these commands in Google Cloud Shell or install the gcloud CLI:

```bash
# Enable required APIs
gcloud services enable bigquery.googleapis.com
gcloud services enable bigqueryconnection.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

# Set your project (replace YOUR_PROJECT_ID)
gcloud config set project YOUR_PROJECT_ID
```

### Step 2: Create BigQuery Datasets

```bash
# Create development dataset
bq mk --dataset --location=US YOUR_PROJECT_ID:healthcare_data_dev

# Create production dataset
bq mk --dataset --location=US YOUR_PROJECT_ID:healthcare_data_prod

# Verify datasets
bq ls --project_id=YOUR_PROJECT_ID
```

### Step 3: Create Service Account

#### Option A: Via Google Cloud Console (Recommended)

1. Go to **IAM & Admin** → **Service Accounts**
2. Click **"Create Service Account"**
3. Name: `dbt-healthcare-service`
4. Description: `Service account for dbt healthcare data pipeline`
5. Click **"Create and Continue"**

#### Assign Roles:

- `BigQuery Data Editor`
- `BigQuery Job User`
- `BigQuery Data Viewer`
- `BigQuery Connection User`

#### Create and Download Key:

1. Click on your service account
2. Go to **"Keys"** tab
3. Click **"Add Key"** → **"Create new key"** → **"JSON"**
4. Download and save the JSON file securely

#### Option B: Via CLI

```bash
# Create service account
gcloud iam service-accounts create dbt-healthcare-service \
  --display-name="dbt Healthcare Service Account" \
  --description="Service account for dbt healthcare data pipeline" \
  --project=YOUR_PROJECT_ID

# Assign roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:dbt-healthcare-service@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:dbt-healthcare-service@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"

# Create and download key
gcloud iam service-accounts keys create ~/dbt-service-account-key.json \
  --iam-account=dbt-healthcare-service@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### Step 4: Configure dbt

#### 4.1 Update Configuration

Run the quick setup script:

```bash
cd /Users/nezamsp8/Developer/python/dataEngineeringPractice
python quick_setup.py
```

Or manually update `/Users/nezamsp8/.dbt/profiles.yml`:

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: YOUR_ACTUAL_PROJECT_ID # Replace this!
      dataset: healthcare_data_dev
      keyfile: /path/to/your/service-account-key.json # Replace this!
      location: US
      priority: interactive
      threads: 4
      timeout_seconds: 300
      retries: 1
```

#### 4.2 Test Connection

```bash
cd /Users/nezamsp8/Developer/python/dataEngineeringPractice
source dbt_venv/bin/activate
cd my_project
dbt debug
```

### Step 5: Run Your dbt Pipeline

#### 5.1 Load Seed Data

```bash
dbt seed
```

#### 5.2 Run Models

```bash
dbt run
```

#### 5.3 Run Tests

```bash
dbt test
```

#### 5.4 Generate Documentation

```bash
dbt docs generate
dbt docs serve
```

### Step 6: Set Up Looker Studio

#### 6.1 Access Looker Studio

1. Go to [Looker Studio](https://datastudio.google.com/)
2. Sign in with your Google account
3. Click **"Create"** → **"Data Source"**

#### 6.2 Connect to BigQuery

1. Select **"BigQuery"** as your data source
2. Choose **"My Projects"** or **"Organization"**
3. Navigate to your project: `YOUR_PROJECT_ID`
4. Choose dataset: `healthcare_data_dev` or `healthcare_data_prod`

#### 6.3 Select Tables

Choose these tables for your dashboards:

- `stg_patients` - Cleaned patient demographics
- `stg_visits` - Visit records and clinical data
- `stg_lab_results` - Laboratory test results
- `patient_summary` - Aggregated patient analytics
- `department_metrics` - Department performance metrics

#### 6.4 Create Your First Dashboard

**📊 Patient Demographics Dashboard:**

- Patient Age Distribution (Histogram)
- Gender Distribution (Pie Chart)
- Insurance Coverage (Bar Chart)
- Patient Count by Department (Column Chart)

**📈 Department Performance Dashboard:**

- Department Efficiency (Scorecard)
- Average Length of Stay (Bar Chart)
- Patient Satisfaction (Line Chart)

**🔬 Lab Results Dashboard:**

- Abnormal Results by Test Type (Pie Chart)
- Lab Results Trend (Time Series)
- Critical Values Alert (Table)

## 🔧 Troubleshooting

### Common Issues

**Issue**: `dbt debug` fails with connection error

- **Solution**: Check your project ID and key file path in `profiles.yml`
- **Solution**: Verify service account has proper permissions
- **Solution**: Ensure BigQuery API is enabled

**Issue**: "Unable to connect to BigQuery" in Looker Studio

- **Solution**: Check service account permissions
- **Solution**: Verify project ID and dataset names
- **Solution**: Ensure BigQuery Connection API is enabled

**Issue**: Data not refreshing in Looker Studio

- **Solution**: Check refresh schedule settings
- **Solution**: Verify data source permissions
- **Solution**: Test BigQuery connection manually

### Performance Optimization

1. **Use aggregated tables**: Prefer `patient_summary` over `stg_patients` for dashboards
2. **Limit date ranges**: Add date filters to reduce data volume
3. **Optimize queries**: Use BigQuery's query optimization features
4. **Cache frequently used data**: Set appropriate refresh schedules

## 📊 Sample Dashboard Templates

### Executive Summary Dashboard

```
Layout: 2x2 Grid
├── Patient Count (Scorecard)
├── Average Length of Stay (Scorecard)
├── Department Performance (Bar Chart)
└── Patient Satisfaction Trend (Line Chart)
```

### Clinical Operations Dashboard

```
Layout: 3x2 Grid
├── Emergency Visits Today (Scorecard)
├── Lab Results Pending (Scorecard)
├── Department Utilization (Pie Chart)
├── Patient Flow by Hour (Line Chart)
├── Critical Lab Values (Table)
└── Readmission Rate (Bar Chart)
```

## 🎨 Design Best Practices

### Color Scheme

- **Primary**: Healthcare blue (#1976D2)
- **Secondary**: Medical green (#388E3C)
- **Alert**: Warning orange (#F57C00)
- **Critical**: Error red (#D32F2F)

### Chart Selection Guidelines

- **Trends over time**: Line charts
- **Comparisons**: Bar charts
- **Proportions**: Pie charts
- **Distributions**: Histograms
- **KPIs**: Scorecards
- **Detailed data**: Tables

## 📚 Additional Resources

### Documentation

- [dbt Documentation](https://docs.getdbt.com/)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Looker Studio Help Center](https://support.google.com/datastudio/)

### Healthcare Analytics

- [Healthcare Data Visualization Guidelines](https://www.himss.org/resources/healthcare-data-visualization)
- [HIPAA Compliance for Dashboards](https://www.hhs.gov/hipaa/for-professionals/privacy/guidance/index.html)

## 🎯 Next Steps

1. **Complete the setup** using the steps above
2. **Create your first dashboard** using the templates
3. **Share with stakeholders** for feedback
4. **Set up automated refreshes** for production use
5. **Create additional dashboards** for different user groups
6. **Monitor performance** and optimize as needed

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review BigQuery logs for data pipeline issues
3. Test individual components (dbt models, BigQuery queries)
4. Verify permissions and authentication

---

**🎉 Congratulations! You now have a complete healthcare data pipeline with dbt, Google Cloud BigQuery, and Looker Studio!**

**Happy Dashboarding! 📊✨**

