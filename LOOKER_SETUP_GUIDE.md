# Looker Studio Setup Guide for Healthcare Analytics

## 🎯 Overview

This guide will help you connect your dbt healthcare data pipeline to Looker Studio (formerly Google Data Studio) for creating interactive dashboards and visualizations.

## 📊 Prerequisites

- ✅ Google Cloud Project with BigQuery datasets created
- ✅ dbt models running successfully in BigQuery
- ✅ Service account with proper permissions
- ✅ Data loaded via `dbt seed` and `dbt run`

## 🚀 Step-by-Step Looker Studio Setup

### 1. Access Looker Studio

1. Go to [Looker Studio](https://datastudio.google.com/)
2. Sign in with your Google account
3. Click **"Create"** → **"Data Source"**

### 2. Connect to BigQuery

1. In the data source gallery, select **"BigQuery"**
2. Choose your connection method:
   - **My Projects**: Use your personal Google account
   - **Organization**: Use your organization's BigQuery (if applicable)

### 3. Select Your Dataset

1. Navigate to your project: `your-gcp-project-id`
2. Choose dataset: `healthcare_data_dev` (for development) or `healthcare_data_prod` (for production)
3. Select tables to include in your data source:
   - `stg_patients` - Cleaned patient demographics
   - `stg_visits` - Visit records and clinical data
   - `stg_lab_results` - Laboratory test results
   - `patient_summary` - Aggregated patient analytics
   - `department_metrics` - Department performance metrics

### 4. Configure Data Source

1. **Name your data source**: "Healthcare Analytics - Patient Data"
2. **Set up authentication**: Use your Google account or service account
3. **Configure refresh schedule**:
   - Manual refresh (for development)
   - Daily refresh (for production dashboards)

### 5. Create Your First Dashboard

#### 📊 Patient Demographics Dashboard

1. Click **"Create"** → **"Report"**
2. Select your healthcare data source
3. Add these visualizations:

**Chart 1: Patient Age Distribution**

- Chart type: **Histogram**
- Dimension: `age`
- Metric: `Record Count`
- Filter: `age` is not null

**Chart 2: Gender Distribution**

- Chart type: **Pie Chart**
- Dimension: `gender`
- Metric: `Record Count`

**Chart 3: Insurance Coverage**

- Chart type: **Bar Chart**
- Dimension: `insurance_type`
- Metric: `Record Count`

**Chart 4: Patient Count by Department**

- Chart type: **Column Chart**
- Dimension: `department`
- Metric: `Record Count`

#### 📈 Department Performance Dashboard

1. Create a new report
2. Use `department_metrics` table
3. Add these visualizations:

**Chart 1: Department Efficiency**

- Chart type: **Scorecard**
- Metric: `completion_rate`
- Dimension: `department`

**Chart 2: Average Length of Stay**

- Chart type: \*\*Bar Chart`
- Dimension: `department`
- Metric: `avg_length_of_stay`

**Chart 3: Patient Satisfaction**

- Chart type: \*\*Line Chart`
- Dimension: `department`
- Metric: `satisfaction_score`

#### 🔬 Lab Results Dashboard

1. Create a new report
2. Use `stg_lab_results` table
3. Add these visualizations:

**Chart 1: Abnormal Results by Test Type**

- Chart type: \*\*Pie Chart`
- Dimension: `test_name`
- Metric: `Record Count`
- Filter: `is_abnormal` = true

**Chart 2: Lab Results Trend**

- Chart type: \*\*Time Series`
- Dimension: `test_date`
- Metric: `Record Count`

**Chart 3: Critical Values Alert**

- Chart type: \*\*Table`
- Dimensions: `patient_id`, `test_name`, `result_value`
- Filter: `is_critical` = true

### 6. Advanced Features

#### 🔄 Scheduled Refreshes

1. Go to **"Resource"** → **"Manage added data sources"**
2. Click on your data source
3. Set **"Data freshness"** to your desired schedule:
   - **Manual**: Refresh when you open the report
   - **Daily**: Refresh once per day
   - **Hourly**: Refresh every hour (for real-time dashboards)

#### 📱 Mobile Optimization

1. Click **"File"** → **"Report settings"**
2. Enable **"Mobile-friendly"**
3. Test on mobile devices

#### 🔗 Sharing and Collaboration

1. Click **"Share"** button
2. Add collaborators with appropriate permissions:
   - **Viewer**: Can view reports
   - **Editor**: Can edit reports
   - **Owner**: Full control

### 7. Sample Dashboard Templates

#### Template 1: Executive Summary Dashboard

```
Layout: 2x2 Grid
├── Patient Count (Scorecard)
├── Average Length of Stay (Scorecard)
├── Department Performance (Bar Chart)
└── Patient Satisfaction Trend (Line Chart)
```

#### Template 2: Clinical Operations Dashboard

```
Layout: 3x2 Grid
├── Emergency Visits Today (Scorecard)
├── Lab Results Pending (Scorecard)
├── Department Utilization (Pie Chart)
├── Patient Flow by Hour (Line Chart)
├── Critical Lab Values (Table)
└── Readmission Rate (Bar Chart)
```

#### Template 3: Quality Metrics Dashboard

```
Layout: 2x3 Grid
├── Overall Quality Score (Scorecard)
├── Patient Safety Incidents (Scorecard)
├── Compliance Rate (Gauge Chart)
├── Quality Trends (Line Chart)
├── Department Comparison (Bar Chart)
└── Quality Metrics Detail (Table)
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

### Layout Tips

- Keep related metrics together
- Use consistent spacing
- Add meaningful titles and descriptions
- Include data refresh timestamps
- Add filters for interactivity

## 🔧 Troubleshooting

### Common Issues

**Issue**: "Unable to connect to BigQuery"

- **Solution**: Check service account permissions
- **Solution**: Verify project ID and dataset names
- **Solution**: Ensure BigQuery API is enabled

**Issue**: "Data not refreshing"

- **Solution**: Check refresh schedule settings
- **Solution**: Verify data source permissions
- **Solution**: Test BigQuery connection manually

**Issue**: "Charts not displaying data"

- **Solution**: Check field mappings
- **Solution**: Verify data types
- **Solution**: Add appropriate filters

### Performance Optimization

1. **Use aggregated tables**: Prefer `patient_summary` over `stg_patients` for dashboards
2. **Limit date ranges**: Add date filters to reduce data volume
3. **Optimize queries**: Use BigQuery's query optimization features
4. **Cache frequently used data**: Set appropriate refresh schedules

## 📚 Additional Resources

### Looker Studio Documentation

- [Looker Studio Help Center](https://support.google.com/datastudio/)
- [BigQuery Connector Guide](https://support.google.com/datastudio/answer/7288010)

### Healthcare Analytics Best Practices

- [Healthcare Data Visualization Guidelines](https://www.himss.org/resources/healthcare-data-visualization)
- [HIPAA Compliance for Dashboards](https://www.hhs.gov/hipaa/for-professionals/privacy/guidance/index.html)

### Sample Queries for Custom Metrics

```sql
-- Patient Readmission Rate
SELECT
  department,
  COUNT(*) as total_discharges,
  COUNT(CASE WHEN readmission_within_30_days THEN 1 END) as readmissions,
  ROUND(COUNT(CASE WHEN readmission_within_30_days THEN 1 END) * 100.0 / COUNT(*), 2) as readmission_rate
FROM {{ ref('patient_summary') }}
GROUP BY department

-- Average Length of Stay by Insurance Type
SELECT
  insurance_type,
  AVG(length_of_stay_days) as avg_length_of_stay
FROM {{ ref('patient_summary') }}
GROUP BY insurance_type
ORDER BY avg_length_of_stay DESC
```

## 🎯 Next Steps

1. **Create your first dashboard** using the templates above
2. **Share with stakeholders** for feedback
3. **Set up automated refreshes** for production use
4. **Create additional dashboards** for different user groups
5. **Monitor performance** and optimize as needed

## 📞 Support

If you encounter issues:

1. Check the [Looker Studio Help Center](https://support.google.com/datastudio/)
2. Review BigQuery logs for data pipeline issues
3. Test individual components (dbt models, BigQuery queries)
4. Verify permissions and authentication

---

**Happy Dashboarding! 📊✨**
