#!/bin/bash
# ============================================
# Preflight Check Script
# Run this BEFORE ansible-playbook to verify
# that target servers meet minimum requirements
# ============================================
# Usage:
#   bash preflight.sh              (check localhost)
#   bash preflight.sh <host_ip>    (check remote via SSH)
# ============================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Counters ---
TOTAL_CHECKS=5
PASSED=0
FAILED=0

# --- Helper Functions ---
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}🔍 Server Preflight Check${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Auto Server Provision — Pre-Ansible Check   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Hostname:${NC} $(hostname)"
    echo -e "${BLUE}Date:${NC}     $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BLUE}User:${NC}     $(whoami)"
    echo ""
    echo -e "${BOLD}─────────────────────────────────────────────${NC}"
}

pass() {
    echo -e "  ${GREEN}✅ PASS${NC} — $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${RED}❌ FAIL${NC} — $1"
    echo -e "         ${YELLOW}↳ $2${NC}"
    ((FAILED++))
}

print_summary() {
    echo ""
    echo -e "${BOLD}─────────────────────────────────────────────${NC}"
    echo ""
    if [ "$FAILED" -eq 0 ]; then
        echo -e "  ${GREEN}${BOLD}✅ ALL CHECKS PASSED (${PASSED}/${TOTAL_CHECKS})${NC}"
        echo -e "  ${GREEN}Server is ready for Ansible provisioning!${NC}"
    else
        echo -e "  ${RED}${BOLD}❌ ${FAILED} CHECK(S) FAILED (${PASSED}/${TOTAL_CHECKS} passed)${NC}"
        echo -e "  ${RED}Fix the issues above before running Ansible.${NC}"
    fi
    echo ""
}

# ============================================
# CHECK 1: Operating System — Must be Ubuntu
# ============================================
check_os() {
    echo ""
    echo -e "${BOLD}[1/5] Checking Operating System...${NC}"

    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        if [[ "${ID}" == "ubuntu" ]]; then
            pass "OS is ${PRETTY_NAME}"
        else
            fail "OS is ${PRETTY_NAME}, expected Ubuntu" \
                 "This playbook only supports Ubuntu servers"
        fi
    else
        fail "/etc/os-release not found" \
             "Cannot determine OS. Is this a Linux system?"
    fi
}

# ============================================
# CHECK 2: RAM — Available memory >= 200MB
# ============================================
check_ram() {
    echo ""
    echo -e "${BOLD}[2/5] Checking Available RAM...${NC}"

    if command -v free &> /dev/null; then
        # Get available memory in MB (column 7 of Mem row)
        AVAILABLE_MB=$(free -m | awk '/^Mem:/ {print $7}')

        if [ -z "$AVAILABLE_MB" ]; then
            # Fallback: try $4 (free column) if $7 (available) is empty
            AVAILABLE_MB=$(free -m | awk '/^Mem:/ {print $4}')
        fi

        if [ "$AVAILABLE_MB" -ge 200 ]; then
            pass "Available RAM: ${AVAILABLE_MB}MB (minimum: 200MB)"
        else
            fail "Available RAM: ${AVAILABLE_MB}MB (minimum: 200MB)" \
                 "Free up memory or add more RAM to this VM"
        fi
    else
        fail "'free' command not found" \
             "Install procps: sudo apt install procps"
    fi
}

# ============================================
# CHECK 3: Disk — Free space on / >= 2GB
# ============================================
check_disk() {
    echo ""
    echo -e "${BOLD}[3/5] Checking Disk Space...${NC}"

    if command -v df &> /dev/null; then
        # Get available disk in GB on root partition
        AVAILABLE_GB=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')

        if [ "$AVAILABLE_GB" -ge 2 ]; then
            pass "Available disk: ${AVAILABLE_GB}GB (minimum: 2GB)"
        else
            fail "Available disk: ${AVAILABLE_GB}GB (minimum: 2GB)" \
                 "Free up disk space: sudo apt autoremove && sudo apt clean"
        fi
    else
        fail "'df' command not found" \
             "This is unexpected on a Linux system"
    fi
}

# ============================================
# CHECK 4: SSH — Port 22 is listening
# ============================================
check_ssh() {
    echo ""
    echo -e "${BOLD}[4/5] Checking SSH Service...${NC}"

    if ss -tlnp 2>/dev/null | grep -q ':22 '; then
        pass "SSH is listening on port 22"
    elif netstat -tlnp 2>/dev/null | grep -q ':22 '; then
        pass "SSH is listening on port 22"
    else
        fail "SSH is not listening on port 22" \
             "Start SSH: sudo systemctl start sshd"
    fi
}

# ============================================
# CHECK 5: Python3 — Required by Ansible
# ============================================
check_python() {
    echo ""
    echo -e "${BOLD}[5/5] Checking Python3...${NC}"

    if command -v python3 &> /dev/null; then
        PY_VERSION=$(python3 --version 2>&1)
        pass "Python3 installed: ${PY_VERSION}"
    else
        fail "Python3 is not installed" \
             "Install it: sudo apt install python3"
    fi
}

# ============================================
# MAIN
# ============================================
main() {
    print_header

    check_os
    check_ram
    check_disk
    check_ssh
    check_python

    print_summary

    # Exit with appropriate code
    if [ "$FAILED" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

main "$@"
