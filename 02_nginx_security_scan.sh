#!/bin/bash

# Security assessment script for Nginx server
ENV_FILE="02.env"

# Load target from .env file
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    if [ -z "$TARGET" ]; then
        echo "[-] Error: TARGET variable not found in $ENV_FILE"
        exit 1
    fi
    echo "[*] Target loaded from $ENV_FILE: $TARGET"
else
    echo "[-] Error: $ENV_FILE not found"
    exit 1
fi

# Function for displaying tree-like output
tree_echo() {
    local level=$1
    local message=$2
    local prefix=""

    if [ $level -gt 0 ]; then
        for ((i = 1; i < level; i++)); do
            prefix="${prefix}│   "
        done
        prefix="${prefix}└── "
    fi

    echo "${prefix}${message}"
}

echo "Starting security assessment for Nginx server at $TARGET"

# Check if required tools are installed
for tool in curl nmap nikto wget; do
    if ! command -v $tool &>/dev/null; then
        echo "[-] Error: $tool is not installed. Please install it first."
        exit 1
    fi
done

# Function to test a specific URL and save response
test_url() {
    local url="$1"
    local description="$2"
    local level=$3

    tree_echo $level "[*] Testing: $description ($url)"

    # Request with curl
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 10)

    if [ "$status_code" == "000" ]; then
        tree_echo $((level + 1)) "[-] Connection failed to $url"
        return
    fi

    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 400 ]; then
        tree_echo $((level + 1)) "[+] Access successful: $url (Status code: $status_code)"

        # Check if response contains sensitive information
        sensitive=$(curl -s "$url" | grep -qi "password\|user\|admin\|config\|database" && echo "yes" || echo "no")
        if [ "$sensitive" == "yes" ]; then
            tree_echo $((level + 2)) "[!] ALERT: Potential sensitive information found in response!"
        fi
    else
        tree_echo $((level + 1)) "[*] Access restricted: $url (Status code: $status_code)"
    fi
}

# 1. Basic server information
tree_echo 0 "[*] Gathering server information"
server_header=$(curl -s -I "$TARGET" | grep -i "Server:")
tree_echo 1 "[*] Server header: $server_header"

# 2. Check for common Nginx configuration files
tree_echo 0 "[*] Checking for exposed configuration files"
test_url "$TARGET/nginx.conf" "Nginx main configuration file" 1
test_url "$TARGET/conf/nginx.conf" "Nginx main configuration file (conf directory)" 1
test_url "$TARGET/.config/nginx/nginx.conf" "Nginx configuration file (hidden directory)" 1
test_url "$TARGET/etc/nginx/nginx.conf" "Nginx configuration file (etc directory)" 1

# 3. Check for common backup files
tree_echo 0 "[*] Checking for backup files"
test_url "$TARGET/nginx.conf~" "Nginx configuration backup file" 1
test_url "$TARGET/nginx.conf.bak" "Nginx configuration backup file" 1
test_url "$TARGET/.nginx.conf.swp" "Nginx configuration swap file" 1

# 4. Check for .git directory exposure
tree_echo 0 "[*] Checking for exposed version control directories"
test_url "$TARGET/.git/HEAD" "Git HEAD file" 1
test_url "$TARGET/.git/config" "Git config file" 1

# 5. Check for directory listing
tree_echo 0 "[*] Checking for directory listing"
test_url "$TARGET/conf/" "Configuration directory" 1
test_url "$TARGET/logs/" "Logs directory" 1
test_url "$TARGET/backup/" "Backup directory" 1

# 6. Check for PHP info files
tree_echo 0 "[*] Checking for PHP information disclosure"
test_url "$TARGET/info.php" "PHP info file" 1
test_url "$TARGET/phpinfo.php" "PHP info file" 1

# 7. Check for hidden files
tree_echo 0 "[*] Checking for hidden files"
test_url "$TARGET/.env" "Environment file" 1
test_url "$TARGET/.htpasswd" "htpasswd file" 1
test_url "$TARGET/.htaccess" "htaccess file" 1

# 8. Check for status pages
tree_echo 0 "[*] Checking for status pages"
test_url "$TARGET/status" "Nginx status page" 1
test_url "$TARGET/nginx_status" "Nginx status page" 1
test_url "$TARGET/server-status" "Server status page" 1

# 9. Check for common web vulnerabilities using curl
tree_echo 0 "[*] Testing for common web vulnerabilities"

# Path traversal attempts
test_url "$TARGET/../../../etc/passwd" "Path traversal attempt" 1
test_url "$TARGET/..%2f..%2f..%2fetc%2fpasswd" "Encoded path traversal attempt" 1

# 10. Perform port scan on the server (limited to common web ports)
tree_echo 0 "[*] Performing limited port scan"
# Extract hostname/IP from TARGET
TARGET_HOST=$(echo "$TARGET" | sed -E 's|^https?://||' | sed -E 's|/.*$||' | sed -E 's|:.*$||')
echo "└── Running nmap on $TARGET_HOST (ports 80,443,8080,8443)..."
nmap_result=$(nmap -p 80,443,8080,8443 -sV "$TARGET_HOST" 2>&1)
echo "└── Port scan results:"
echo "$nmap_result" | sed 's/^/    /'

# 11. Run nikto scan
tree_echo 0 "[*] Running Nikto web vulnerability scanner"
echo "└── This may take several minutes..."
nikto_result=$(nikto -h "$TARGET" 2>&1)
echo "└── Nikto scan results:"
echo "$nikto_result" | sed 's/^/    /'

# 12. Check for SSL/TLS configuration
if curl -s -I "${TARGET/http:/https:}" >/dev/null 2>&1; then
    tree_echo 0 "[*] Testing SSL/TLS configuration"
    ssl_result=$(nmap --script ssl-enum-ciphers -p 443 "$TARGET_HOST" 2>&1)
    echo "└── SSL/TLS scan results:"
    echo "$ssl_result" | sed 's/^/    /'
fi

# 13. Check for HTTP methods
tree_echo 0 "[*] Checking allowed HTTP methods"
methods=$(curl -s -X OPTIONS -I "$TARGET" | grep -i "Allow:")
tree_echo 1 "[*] Allowed HTTP methods: $methods"

# 14. Testing for XSS reflection
test_url "$TARGET/?test=<script>alert(1)</script>" "XSS reflection test" 0

# Summary
tree_echo 0 "[*] Security assessment completed"
