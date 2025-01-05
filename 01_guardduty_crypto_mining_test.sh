#!/bin/bash

# Warning: This script is for testing purposes only.
# AWS GuardDuty Cryptocurrency Mining Detection Test Script

echo "[+] Starting GuardDuty cryptocurrency mining detection test..."

# Simulate mining-related DNS queries
simulate_dns_queries() {
    echo "[*] Simulating mining pool DNS queries..."

    # Actual mining pool domains
    MINING_POOLS=(
        "stratum.slushpool.com"
        "eu.stratum.slushpool.com"
        "pool.bitcoin.com"
        "xmr.pool.minergate.com"
        "pool.supportxmr.com"
        "xmrpool.eu"
        "mine.moneropool.com"
        "eth-eu1.nanopool.org"
        "eth-asia1.nanopool.org"
        "eth.2miners.com"
    )

    for pool in "${MINING_POOLS[@]}"; do
        echo "[*] DNS lookup: $pool"
        dig +short $pool
        host $pool
        nslookup $pool
        sleep 2
    done
}

# Simulate mining network traffic
simulate_network_traffic() {
    echo "[*] Simulating mining network traffic..."

    # Common mining ports
    PORTS=(
        "3333" # Stratum protocol
        "3334"
        "8332" # Bitcoin
        "8333"
        "9332"  # Litecoin
        "4444"  # Monero
        "5555"  # Ethereum
        "14444" # Monero alternative port
        "20535" # Zcash
    )

    # Mining pool IP addresses (examples)
    MINING_IPS=(
        "104.27.164.131" # Some pool server IPs
        "104.18.30.192"
        "176.9.0.232"
        "104.27.165.131"
        "194.58.100.109"
    )

    for ip in "${MINING_IPS[@]}"; do
        for port in "${PORTS[@]}"; do
            echo "[*] Connection attempt: $ip:$port"
            timeout 5 nc -zv $ip $port &>/dev/null
            if [ $? -eq 0 ]; then
                echo "[+] Connection successful: $ip:$port"
            else
                echo "[-] Connection failed: $ip:$port"
            fi
            sleep 1
        done
    done
}

# Simulate Stratum protocol messages
simulate_stratum_protocol() {
    echo "[*] Simulating Stratum protocol messages..."

    # Mining pool server (for testing)
    POOL_SERVER="stratum.slushpool.com"
    POOL_PORT="3333"

    # Generate fake JSON-RPC messages
    WORKER_NAME="test_worker"
    SUBSCRIBE='{"id": 1, "method": "mining.subscribe", "params": ["cpuminer/2.5.0"]}'
    AUTHORIZE='{"id": 2, "method": "mining.authorize", "params": ["'$WORKER_NAME'", "x"]}'
    SUBMIT='{"id": 4, "method": "mining.submit", "params": ["'$WORKER_NAME'", "job_id", "ExtraNonce2", "nTime", "nOnce"]}'

    echo "[*] Attempting to send messages: $POOL_SERVER:$POOL_PORT"

    # Output messages (not actually sending)
    echo "    > $SUBSCRIBE"
    echo "    > $AUTHORIZE"
    echo "    > $SUBMIT"

    # Simulate network connection (logging only)
    echo "[*] Attempting to connect to Stratum server..."
    timeout 3 nc -z $POOL_SERVER $POOL_PORT &>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Stratum server connection possible"
    else
        echo "[-] Stratum server connection not possible - proceeding with simulation only"
    fi
}

# Simulate mining-related file downloads
simulate_miner_download() {
    echo "[*] Simulating miner download..."
    TEMP_DIR=$(mktemp -d)

    # Common mining software URLs (not actually downloading)
    MINER_URLS=(
        "https://github.com/xmrig/xmrig/releases/download/v6.16.4/xmrig-6.16.4-linux-x64.tar.gz"
        "https://github.com/ethereum-mining/ethminer/releases/download/v0.18.0/ethminer-0.18.0-linux-x86_64.tar.gz"
        "https://github.com/bitcoin/bitcoin/releases/download/v22.0/bitcoin-22.0-x86_64-linux-gnu.tar.gz"
    )

    for url in "${MINER_URLS[@]}"; do
        echo "[*] Mining software URL lookup: $url"
        curl -s -I $url | head -n 1
        sleep 2
    done

    # Create fake mining binary file
    echo "#!/bin/bash" >"$TEMP_DIR/xmrig"
    echo "echo 'XMRig 6.16.4'" >>"$TEMP_DIR/xmrig"
    echo "echo 'Copyright (c) 2018-2021 SChernykh'" >>"$TEMP_DIR/xmrig"
    echo "echo 'Copyright (c) 2016-2021 XMRig'" >>"$TEMP_DIR/xmrig"
    echo "while true; do" >>"$TEMP_DIR/xmrig"
    echo "  echo '[+] Mining... hashrate: 545.5 H/s'" >>"$TEMP_DIR/xmrig"
    echo "  echo '[+] CPU: INTEL(R) XEON(R) CPU, x64 AES'" >>"$TEMP_DIR/xmrig"
    echo "  echo '[+] Difficulty: 340282'" >>"$TEMP_DIR/xmrig"
    echo "  sleep 10" >>"$TEMP_DIR/xmrig"
    echo "done" >>"$TEMP_DIR/xmrig"

    chmod +x "$TEMP_DIR/xmrig"
    echo "[+] Generated test mining software: $TEMP_DIR/xmrig"
}

# Simulate CPU usage
simulate_cpu_usage() {
    echo "[*] Simulating mining CPU usage..."
    NUM_CORES=$(nproc)
    STRESS_DURATION=120 # seconds

    # Generate CPU load
    echo "[*] Generating CPU load on $NUM_CORES cores for $STRESS_DURATION seconds..."

    for i in $(seq 1 $NUM_CORES); do
        (
            echo "[*] Starting load on core $i"
            end=$((SECONDS + STRESS_DURATION))
            while [ $SECONDS -lt $end ]; do
                # Heavy SHA-256 hashing operations (similar to Bitcoin mining)
                for j in {1..1000}; do
                    echo "mining_data_$j" | sha256sum >/dev/null
                done
            done
        ) &
    done

    # Show progress
    echo "[*] CPU load simulation in progress ($STRESS_DURATION seconds)..."
    for i in $(seq 1 $STRESS_DURATION); do
        if [ $((i % 10)) -eq 0 ]; then
            echo -ne "\r[*] Elapsed time: $i/$STRESS_DURATION seconds"
        fi
        sleep 1
    done
    echo -e "\r[+] CPU load simulation completed                    "

    # Wait for all background processes to complete
    wait
}

# Main execution function
main() {
    echo "===================================================="
    echo "  AWS GuardDuty Cryptocurrency Mining Detection Test Tool"
    echo "  Warning: For testing purposes only!"
    echo "===================================================="

    # Warning and confirmation
    echo "Warning: This script is intended to test GuardDuty cryptocurrency mining detection."
    echo "         This script does not perform actual mining, but simulates mining-related activities."
    echo "         Run only in test environments."

    read -p "Do you want to continue? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi

    # Record start time
    START_TIME=$(date +%s)

    # Run each simulation step
    simulate_dns_queries
    simulate_network_traffic
    simulate_stratum_protocol
    simulate_miner_download
    simulate_cpu_usage

    # Calculate end time and duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "===================================================="
    echo "[+] Test completed: Took $DURATION seconds"
    echo "[*] GuardDuty may take up to 24 hours to detect this activity."
    echo "[*] Check the GuardDuty console for findings like 'CryptoCurrency:EC2/BitcoinTool.B'."
    echo "===================================================="
}

# Run script
main

exit 0
