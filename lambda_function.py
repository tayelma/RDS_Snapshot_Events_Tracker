import csv
import boto3
import os
import logging
import re
import json
from datetime import datetime

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Validate that the event is a dictionary
    if not isinstance(event, dict):
        logger.error("Invalid event object: expected a dictionary.")
        return {
            'statusCode': 400,
            'body': 'Invalid event object.'
        }

    s3_client = boto3.client('s3')
    bucket_name = os.environ.get("s3_bucket", "test")

    try:
        # Log the entire event payload in a clean JSON format
        logger.info("Entire event payload:\n%s", json.dumps(event, indent=4))

        # Extract required details from event
        event_detail = event.get('detail', {})
        date = event_detail.get('Date', 'N/A')
        message = event_detail.get('Message', 'N/A')
        source_identifier = event_detail.get('SourceIdentifier', 'N/A')

        # Skip entry if all key fields are "N/A"
        if date == 'N/A' and message == 'N/A' and source_identifier == 'N/A':
            logger.info("Skipping entry with all 'N/A' values.")
            return {
                'statusCode': 200,
                'body': 'Entry skipped.'
            }

        # Use regex to extract the RDS instance name from the snapshot ARN
        pattern = r"rds:([^-]+(?:-[^-]+)*)-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}"
        match = re.search(pattern, source_identifier)
        source_database = match.group(1) if match else 'Unknown'

        # Filter: only process snapshots for the three desired RDS instances
        allowed_rds = ["depost", "withdrawal", "recon"]
        if source_database not in allowed_rds:
            logger.info(f"Skipping snapshot event for {source_database}, not in allowed list.")
            return {
                'statusCode': 200,
                'body': f"Snapshot event for {source_database} skipped."
            }

        # Determine the current year for dynamic file creation
        current_year = datetime.now().year
        csv_filename = f"rds_snapshots_tracker_{current_year}.csv"
        s3_key = f"{current_year}/{csv_filename}"

        # Prepare data row in order: [SourceDatabase, Snapshot Name, Status, Snapshot Creation Time]
        csv_row = [source_database, source_identifier, message, date]

        # Define local CSV file path in /tmp
        local_csv_path = f"/tmp/{csv_filename}"

        # Download existing file from S3 if available
        file_exists = False
        file_has_headers = False
        try:
            s3_client.download_file(bucket_name, s3_key, local_csv_path)
            file_exists = True
            # Check if file has headers by reading the first line
            with open(local_csv_path, mode='r') as f:
                first_line = f.readline().strip()
            file_has_headers = first_line.startswith("SourceDatabase")
        except s3_client.exceptions.ClientError as e:
            if e.response['Error']['Code'] != '404':
                raise

        # Open the local CSV file in append mode and write the new row
        with open(local_csv_path, mode='a', newline='') as file:
            writer = csv.writer(file)
            if not file_exists or not file_has_headers:
                writer.writerow(["SourceDatabase", "Snapshot Name", "Status", "Snapshot Creation Time"])
            writer.writerow(csv_row)

        # Upload the updated CSV file back to S3 in the correct yearly subfolder
        s3_client.upload_file(local_csv_path, bucket_name, s3_key)

        logger.info(f"Successfully processed snapshot event for {source_identifier} (RDS: {source_database})")

        return {
            'statusCode': 200,
            'body': 'Snapshot event logged successfully.'
        }

    except Exception as e:
        logger.error(f"Error processing snapshot event: {e}")
        return {
            'statusCode': 500,
            'body': f"Error: {e}"
        }