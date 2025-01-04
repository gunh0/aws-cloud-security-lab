#!/bin/bash

# Load credentials from .env file
if [ -f ./01.env ]; then
    source ./01.env
    echo "[*] Credentials loaded successfully from .env file"
else
    echo "[-] Error: .env file not found in secret directory"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &>/dev/null; then
    echo "[-] Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Configure AWS CLI with the credentials
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION="ap-northeast-2" # Seoul region
echo "[*] AWS CLI configured with Seoul region (ap-northeast-2)"

echo "[*] Listing all EC2 instances in Seoul region..."

# Get all instance IDs and their states
INSTANCES=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output text)

if [ -z "$INSTANCES" ]; then
    echo "[-] No instances found in the Seoul region."
    exit 0
fi

echo "[+] Found the following instances:"
echo "$INSTANCES"
echo ""

# Process each instance
echo "$INSTANCES" | while read -r INSTANCE_ID STATE; do
    echo "[*] Instance $INSTANCE_ID is $STATE"

    # Check if instance is running and stop it
    if [ "$STATE" == "running" ]; then
        echo "[*] Attempting to stop instance $INSTANCE_ID..."

        # Try stopping the instance up to 5 times
        success=false
        for attempt in {1..5}; do
            echo "[*] Stop attempt $attempt for instance $INSTANCE_ID"
            output=$(aws ec2 stop-instances --instance-ids "$INSTANCE_ID" 2>&1)
            if [ $? -eq 0 ]; then
                echo "[+] Stop command successful for instance $INSTANCE_ID on attempt $attempt"
                success=true
                break
            else
                echo "[-] Failed to stop instance $INSTANCE_ID on attempt $attempt: $output"
                sleep 5 # Wait 5 seconds before retrying
            fi
        done

        if [ "$success" = true ]; then
            echo "[+] Successfully stopped instance $INSTANCE_ID"
        else
            echo "[-] Failed to stop instance $INSTANCE_ID after 5 attempts"
        fi

        # Check if we should try to terminate the instance as well
        echo "[*] Attempting to terminate instance $INSTANCE_ID..."

        # Try terminating the instance up to 5 times
        success=false
        for attempt in {1..5}; do
            echo "[*] Termination attempt $attempt for instance $INSTANCE_ID"
            output=$(aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" 2>&1)
            if [ $? -eq 0 ]; then
                echo "[+] Termination command successful for instance $INSTANCE_ID on attempt $attempt"
                success=true
                break
            else
                echo "[-] Failed to terminate instance $INSTANCE_ID on attempt $attempt: $output"
                sleep 5 # Wait 5 seconds before retrying
            fi
        done

        if [ "$success" = true ]; then
            echo "[+] Successfully terminated instance $INSTANCE_ID"
        else
            echo "[-] Failed to terminate instance $INSTANCE_ID after 5 attempts"
        fi
    else
        echo "[*] Instance $INSTANCE_ID is not running. No action needed."
    fi
done

echo "[+] EC2 instance check, stop, and termination process completed."
