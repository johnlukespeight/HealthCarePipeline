#!/usr/bin/env python3
"""
Quick Setup Script for dbt + Google Cloud + Looker
This script helps you quickly configure your project with real values.
"""

import os
import sys
from pathlib import Path


def update_profiles_yml(project_id, key_file_path):
    """Update the profiles.yml file with actual values"""
    profiles_file = Path("/Users/nezamsp8/.dbt/profiles.yml")

    if not profiles_file.exists():
        print("❌ profiles.yml not found!")
        return False

    # Read current content
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

    print(f"✅ Updated profiles.yml with:")
    print(f"   Project ID: {project_id}")
    print(f"   Key file: {key_file_path}")

    return True


def main():
    print("🔧 Quick Configuration Setup")
    print("=" * 40)

    # Get project ID
    project_id = input("Enter your Google Cloud Project ID: ").strip()
    if not project_id:
        print("❌ Project ID is required!")
        return False

    # Get key file path
    key_file = input(
        "Enter path to your service account key file (or press Enter for default): "
    ).strip()
    if not key_file:
        key_file = "/Users/nezamsp8/Developer/python/dataEngineeringPractice/dbt-service-account-key.json"

    # Check if key file exists
    if not Path(key_file).exists():
        print(f"❌ Key file not found: {key_file}")
        print("Please download your service account key file first!")
        return False

    # Update profiles.yml
    if update_profiles_yml(project_id, key_file):
        print("\n✅ Configuration updated successfully!")
        print("\nNext steps:")
        print("1. Run: dbt debug (to test connection)")
        print("2. Run: dbt seed (to load CSV data)")
        print("3. Run: dbt run (to create models)")
        print("4. Set up Looker Studio dashboards")
        return True
    else:
        return False


if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n❌ Setup cancelled")
        sys.exit(1)





