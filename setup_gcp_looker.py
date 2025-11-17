#!/usr/bin/env python3
"""
Google Cloud Platform and Looker Setup Script for Healthcare dbt Project
This script helps configure your dbt project to work with Google Cloud BigQuery and Looker Studio.
"""

import os
import json
import subprocess
import sys
from pathlib import Path


def print_step(step_num, title):
    """Print a formatted step header"""
    print(f"\n{'='*60}")
    print(f"STEP {step_num}: {title}")
    print(f"{'='*60}")


def check_gcloud_installed():
    """Check if gcloud CLI is installed"""
    try:
        subprocess.run(["gcloud", "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def get_project_info():
    """Get Google Cloud project information from user"""
    print("\n📋 Google Cloud Project Setup")
    print("-" * 40)

    project_id = input("Enter your Google Cloud Project ID: ").strip()
    if not project_id:
        print("❌ Project ID is required!")
        return None, None

    # Check if project exists
    try:
        result = subprocess.run(
            ["gcloud", "projects", "describe", project_id],
            capture_output=True,
            text=True,
            check=True,
        )
        print(f"✅ Project '{project_id}' found!")
    except subprocess.CalledProcessError:
        print(f"❌ Project '{project_id}' not found or you don't have access!")
        return None, None

    # Get current user email for IAM setup
    try:
        result = subprocess.run(
            [
                "gcloud",
                "auth",
                "list",
                "--filter=status:ACTIVE",
                "--format=value(account)",
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        user_email = result.stdout.strip()
        print(f"✅ Active user: {user_email}")
    except subprocess.CalledProcessError:
        user_email = input("Enter your Google account email: ").strip()

    return project_id, user_email


def setup_bigquery_datasets(project_id):
    """Create BigQuery datasets"""
    print_step(2, "Setting up BigQuery Datasets")

    datasets = ["healthcare_data_dev", "healthcare_data_prod"]

    for dataset in datasets:
        try:
            cmd = ["bq", "mk", "--dataset", f"--location=US", f"{project_id}:{dataset}"]
            subprocess.run(cmd, check=True)
            print(f"✅ Created dataset: {dataset}")
        except subprocess.CalledProcessError as e:
            if "already exists" in str(e):
                print(f"ℹ️  Dataset {dataset} already exists")
            else:
                print(f"❌ Failed to create dataset {dataset}: {e}")
                return False

    return True


def create_service_account(project_id):
    """Create service account for dbt"""
    print_step(3, "Creating Service Account")

    service_account_name = "dbt-healthcare-service"
    service_account_email = (
        f"{service_account_name}@{project_id}.iam.gserviceaccount.com"
    )

    # Create service account
    try:
        cmd = [
            "gcloud",
            "iam",
            "service-accounts",
            "create",
            service_account_name,
            "--display-name=dbt Healthcare Service Account",
            "--description=Service account for dbt healthcare data pipeline",
            f"--project={project_id}",
        ]
        subprocess.run(cmd, check=True)
        print(f"✅ Created service account: {service_account_name}")
    except subprocess.CalledProcessError as e:
        if "already exists" in str(e):
            print(f"ℹ️  Service account {service_account_name} already exists")
        else:
            print(f"❌ Failed to create service account: {e}")
            return None

    # Assign roles
    roles = [
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/bigquery.dataViewer",
        "roles/bigquery.connectionUser",
    ]

    for role in roles:
        try:
            cmd = [
                "gcloud",
                "projects",
                "add-iam-policy-binding",
                project_id,
                f"--member=serviceAccount:{service_account_email}",
                f"--role={role}",
            ]
            subprocess.run(cmd, check=True)
            print(f"✅ Assigned role: {role}")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to assign role {role}: {e}")

    return service_account_email


def create_service_account_key(project_id, service_account_email):
    """Create and download service account key"""
    print_step(4, "Creating Service Account Key")

    key_file = Path(__file__).parent / "dbt-service-account-key.json"

    try:
        cmd = [
            "gcloud",
            "iam",
            "service-accounts",
            "keys",
            "create",
            str(key_file),
            f"--iam-account={service_account_email}",
        ]
        subprocess.run(cmd, check=True)
        print(f"✅ Created service account key: {key_file}")
        return str(key_file)
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to create service account key: {e}")
        return None


def update_profiles_yml(project_id, key_file_path):
    """Update dbt profiles.yml with project configuration"""
    print_step(5, "Updating dbt Configuration")

    profiles_file = Path(__file__).parent / "profiles.yml"

    if not profiles_file.exists():
        print(f"❌ profiles.yml not found at {profiles_file}")
        return False

    # Read current profiles.yml
    with open(profiles_file, "r") as f:
        content = f.read()

    # Replace placeholders
    content = content.replace("your-gcp-project-id", project_id)
    content = content.replace(
        "/Users/nezamsp8/Developer/python/dataEngineeringPractice/dbt-service-account-key.json",
        key_file_path,
    )

    # Write updated content
    with open(profiles_file, "w") as f:
        f.write(content)

    print(f"✅ Updated profiles.yml with project ID: {project_id}")
    print(f"✅ Updated key file path: {key_file_path}")

    return True


def test_dbt_connection():
    """Test dbt connection to BigQuery"""
    print_step(6, "Testing dbt Connection")

    project_dir = Path(__file__).parent / "my_project"

    if not project_dir.exists():
        print(f"❌ dbt project directory not found: {project_dir}")
        return False

    try:
        # Test connection
        cmd = ["dbt", "debug", "--project-dir", str(project_dir)]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("✅ dbt connection test successful!")
        print("Connection details:")
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ dbt connection test failed: {e}")
        print("Error output:")
        print(e.stderr)
        return False


def setup_looker_instructions():
    """Provide instructions for Looker Studio setup"""
    print_step(7, "Looker Studio Setup Instructions")

    print(
        """
🎯 Next Steps for Looker Studio Integration:

1. Go to Looker Studio: https://datastudio.google.com/
2. Click "Create" → "Data Source"
3. Select "BigQuery" as your data source
4. Choose your project and dataset (healthcare_data_dev or healthcare_data_prod)
5. Select the tables you want to visualize:
   - stg_patients (cleaned patient data)
   - stg_visits (visit records)
   - stg_lab_results (lab test results)
   - patient_summary (aggregated patient analytics)
   - department_metrics (department performance)

6. Create visualizations:
   📊 Patient Demographics Dashboard
   📈 Department Performance Metrics
   🔬 Lab Results Trends
   👥 Patient Utilization Patterns

7. Share your dashboards with your team!

💡 Pro Tips:
- Use the marts models (patient_summary, department_metrics) for business dashboards
- Use staging models (stg_*) for detailed analysis
- Set up scheduled refreshes to keep data current
- Use BigQuery's built-in ML features for predictive analytics
"""
    )


def main():
    """Main setup function"""
    print("🏥 Healthcare dbt + Google Cloud + Looker Setup")
    print("=" * 60)

    # Check prerequisites
    if not check_gcloud_installed():
        print("❌ Google Cloud CLI not found!")
        print("Please install it from: https://cloud.google.com/sdk/docs/install")
        return False

    # Get project information
    project_id, user_email = get_project_info()
    if not project_id:
        return False

    # Setup BigQuery datasets
    if not setup_bigquery_datasets(project_id):
        return False

    # Create service account
    service_account_email = create_service_account(project_id)
    if not service_account_email:
        return False

    # Create service account key
    key_file = create_service_account_key(project_id, service_account_email)
    if not key_file:
        return False

    # Update dbt configuration
    if not update_profiles_yml(project_id, key_file):
        return False

    # Test dbt connection
    if not test_dbt_connection():
        print("\n⚠️  dbt connection test failed, but you can continue with manual setup")

    # Provide Looker instructions
    setup_looker_instructions()

    print("\n🎉 Setup Complete!")
    print("=" * 60)
    print(
        "Your healthcare data pipeline is now configured for Google Cloud and Looker!"
    )
    print("\nNext steps:")
    print("1. Run 'dbt seed' to load your CSV data")
    print("2. Run 'dbt run' to create your models")
    print("3. Run 'dbt test' to validate data quality")
    print("4. Set up Looker Studio dashboards")

    return True


if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n❌ Setup cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)





