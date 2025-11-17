#!/usr/bin/env python3
"""
Healthcare Data Pipeline Setup Script
This script helps set up and run the healthcare data pipeline with dbt and Google Cloud.
"""

import os
import subprocess
import sys
import requests
from pathlib import Path


def run_command(command, description):
    """Run a shell command and handle errors."""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(
            command, shell=True, check=True, capture_output=True, text=True
        )
        print(f"✅ {description} completed successfully")
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed: {e.stderr}")
        return None


def download_csv_from_github(repo_url, file_path, local_path):
    """Download a CSV file from a GitHub repository."""
    try:
        print(f"📥 Downloading {file_path} from {repo_url}...")
        response = requests.get(f"{repo_url}/raw/main/{file_path}")
        response.raise_for_status()

        # Ensure the seeds directory exists
        os.makedirs(os.path.dirname(local_path), exist_ok=True)

        with open(local_path, "w") as f:
            f.write(response.text)
        print(f"✅ Downloaded {file_path} to {local_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to download {file_path}: {e}")
        return False


def setup_environment():
    """Set up the Python environment and install dependencies."""
    print("🚀 Setting up healthcare data pipeline environment...")

    # Check if we're in a virtual environment
    if not hasattr(sys, "real_prefix") and not (
        hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix
    ):
        print("⚠️  Warning: You're not in a virtual environment. Consider using one.")

    # Install dbt-bigquery
    run_command("pip install dbt-bigquery", "Installing dbt-bigquery")

    # Install requests for downloading files
    run_command("pip install requests", "Installing requests")


def download_sample_data():
    """Download sample healthcare data from GitHub."""
    print("📊 Downloading sample healthcare data...")

    # Example healthcare data repositories (replace with actual ones)
    sample_data = [
        {
            "repo_url": "https://github.com/your-org/healthcare-data",
            "file_path": "data/patients.csv",
            "local_path": "my_project/seeds/patients.csv",
        },
        {
            "repo_url": "https://github.com/your-org/healthcare-data",
            "file_path": "data/visits.csv",
            "local_path": "my_project/seeds/visits.csv",
        },
        {
            "repo_url": "https://github.com/your-org/healthcare-data",
            "file_path": "data/lab_results.csv",
            "local_path": "my_project/seeds/lab_results.csv",
        },
    ]

    # For now, we'll use the sample data we created
    print("ℹ️  Using sample data files already created in the project")
    return True


def validate_dbt_project():
    """Validate the dbt project configuration."""
    print("🔍 Validating dbt project...")

    # Check if dbt_project.yml exists
    if not os.path.exists("my_project/dbt_project.yml"):
        print("❌ dbt_project.yml not found")
        return False

    # Check if profiles.yml exists
    if not os.path.exists("profiles.yml"):
        print(
            "❌ profiles.yml not found. Please create it with your Google Cloud credentials."
        )
        return False

    print("✅ dbt project validation passed")
    return True


def run_dbt_pipeline():
    """Run the complete dbt pipeline."""
    print("🔄 Running dbt pipeline...")

    # Change to the dbt project directory
    os.chdir("my_project")

    # Run dbt commands
    commands = [
        ("dbt deps", "Installing dbt dependencies"),
        ("dbt seed", "Loading CSV seed data"),
        ("dbt run", "Running dbt models"),
        ("dbt test", "Running dbt tests"),
        ("dbt docs generate", "Generating documentation"),
    ]

    for command, description in commands:
        result = run_command(command, description)
        if result is None:
            print(f"❌ Pipeline failed at: {description}")
            return False

    print("✅ dbt pipeline completed successfully!")
    return True


def main():
    """Main setup function."""
    print("🏥 Healthcare Data Pipeline Setup")
    print("=" * 50)

    # Check if we're in the right directory
    if not os.path.exists("my_project"):
        print("❌ Please run this script from the project root directory")
        sys.exit(1)

    # Setup steps
    setup_environment()

    if not validate_dbt_project():
        print("❌ Project validation failed. Please check your configuration.")
        sys.exit(1)

    download_sample_data()

    if run_dbt_pipeline():
        print("\n🎉 Healthcare data pipeline setup complete!")
        print("\nNext steps:")
        print("1. Update profiles.yml with your Google Cloud credentials")
        print("2. Replace sample CSV files with your actual healthcare data")
        print("3. Run 'dbt docs serve' to view the documentation")
        print("4. Set up automated scheduling with GitHub Actions or Cloud Scheduler")
    else:
        print("❌ Pipeline setup failed. Please check the errors above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
