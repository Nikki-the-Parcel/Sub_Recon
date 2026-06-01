#!/bin/bash

SETUP_FLAG="./.sub-recon_ran_already"

# ── Loading Bar ───────────────────────────────────────────────────────────────
loading_bar() {
    local label="$1"
    local pid="$2"
    local width=40
    local i=0

    printf "  %-20s\n  [" "$label"
    while kill -0 "$pid" 2>/dev/null; do
        if [ $i -lt $width ]; then
            printf "#"
            i=$((i + 1))
        fi
        sleep 0.3
    done
    # Fill remaining if process finished before bar filled
    while [ $i -lt $width ]; do
        printf "#"
        i=$((i + 1))
    done
    printf "] done\n"
}

# ── Run only on first execution ───────────────────────────────────────────────
if [ ! -f "$SETUP_FLAG" ]; then
    echo "First run detected. Running initial setup..."
    echo ""

    install_go() {
        if command -v go >/dev/null 2>&1; then
            echo "  Go-Lib              Already present. Skipping..."
        else
            if command -v apt >/dev/null 2>&1; then
                (sudo apt update -qq && sudo apt install -y golang-go -qq) > /dev/null 2>&1 &
            elif command -v dnf >/dev/null 2>&1; then
                (sudo dnf install -y golang -q) > /dev/null 2>&1 &
            elif command -v pacman >/dev/null 2>&1; then
                (sudo pacman -Sy --noconfirm go) > /dev/null 2>&1 &
            elif command -v brew >/dev/null 2>&1; then
                (brew install go) > /dev/null 2>&1 &
            else
                echo "Unsupported package manager. Install Go manually."
                exit 1
            fi

            loading_bar "installing go" $!
            wait

            if command -v go >/dev/null 2>&1; then
                echo "  go                   Installed successfully."
            else
                echo "  go                   Installation failed. Aborting."
                exit 1
            fi
        fi

        export PATH="$PATH:$HOME/go/bin"
    }

    install_tool() {
        local tool="$1"

        if command -v "$tool" >/dev/null 2>&1; then
            echo "  $tool$(printf '%*s' $((20 - ${#tool})) '')Already present. Skipping..."
            return 0
        fi

        case "$tool" in
            subfinder)
                go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest > /dev/null 2>&1 &
                ;;
            assetfinder)
                go install github.com/tomnomnom/assetfinder@latest > /dev/null 2>&1 &
                ;;
            sublist3r)
                sudo apt install -y sublist3r -qq > /dev/null 2>&1 &
                ;;
            *)
                echo "Unknown tool: $tool"
                return 1
                ;;
        esac

        loading_bar "Installing $tool" $!
        wait
        hash -r

        if command -v "$tool" >/dev/null 2>&1; then
            echo "  $tool$(printf '%*s' $((20 - ${#tool})) '')installed successfully."
        else
            echo "  $tool$(printf '%*s' $((20 - ${#tool})) '')installation failed."
        fi
    }

    # Install Go first
    install_go

    echo ""

    # Install required tools
    for tool in subfinder assetfinder sublist3r; do
        install_tool "$tool"
    done

    touch "$SETUP_FLAG"
    echo ""
    echo "Initial setup complete."
    echo ""

else
    echo "Setup already completed. Skipping installation checks."
fi

# =============================================================================
# sub_recon.sh - Automated Subdomain Reconnaissance Script
# Usage: ./sub_recon.sh -u "example.com"
# Tools required: subfinder, assetfinder, sublist3r
# =============================================================================

print_banner() {
    echo -e "\033[1;36m"
    echo '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo '  _________    ___.            __________                             '
    echo '  /   _____/__ _\_ |__          \______   \ ____   ____  ____   ____  '
    echo '  \_____  \|  |  \ __ \   ______ |       _// __ \_/ ___\/  _ \ /    \ '
    echo '  /        \  |  / \_\ \ /_____/ |    |   \  ___/\  \__(  <_> )   |  \'
    echo ' /_______  /____/|___  /         |____|_  /\___  >\___  >____/|___|  /'
    echo '         \/          \/                  \/     \/     \/           \/ '
    echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    echo -e "\033[0m"
}

print_banner

# ── Argument Parsing ──────────────────────────────────────────────────────────

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 -u <domain> [--ch]"
    echo "Example: $0 -u tesla.com --ch"
    echo "  --ch : after recon, check the HTTP status of every subdomain found"
    exit 1
fi

# --ch is a long option that getopts can't read, so pull it out of the args first.
RUN_STATUS_CHECK=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --ch) RUN_STATUS_CHECK=true ;;
        *)    ARGS+=("$arg") ;;
    esac
done
set -- "${ARGS[@]}"

# Parse the -u flag to capture the target domain
while getopts "u:" opt; do
    case $opt in
        u) DOMAIN="$OPTARG" ;;
        *) echo "Invalid option. Usage: $0 -u <domain> [--ch]"; exit 1 ;;
    esac
done

# Exit if domain is still empty after parsing
if [ -z "$DOMAIN" ]; then
    echo "[!] Error: No domain provided. Use -u <domain>"
    exit 1
fi

# ── Setup ─────────────────────────────────────────────────────────────────────

# Clean domain for filename creation
CLEAN_DOMAIN=$(echo "$DOMAIN" \
    | sed 's|^https\?://||' \
    | sed 's|/$||' \
    | tr '.' '_')

# Output directory and file
OUTPUT_DIR="./sub_recon"
OUTPUT_FILE="$OUTPUT_DIR/${CLEAN_DOMAIN}.txt"

# Create the Output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Clear any existing subdomains file so we start fresh each run
> "$OUTPUT_FILE"

echo ""
echo "============================================="
echo "   Subdomain Recon  |  Target: $DOMAIN"
echo "============================================="
echo ""

# ── 1. Subfinder ─────────────────────────────────────────────────────────────

echo "[*] Running subfinder on $DOMAIN ..."

# -d  : target domain
# -o  : write results to file (overwrites, so we redirect/append manually)
# -silent : suppress banner/noise, only output subdomains
subfinder -d "$DOMAIN" -silent >> "$OUTPUT_FILE" 2>/dev/null

# Count how many lines subfinder added (approximate; file only has subfinder results at this point)
SUBFINDER_COUNT=$(wc -l < "$OUTPUT_FILE")
echo "[+] subfinder found  : $SUBFINDER_COUNT subdomains"
echo ""

# ── 2. Assetfinder ───────────────────────────────────────────────────────────

echo "[*] Running assetfinder on $DOMAIN ..."

# --subs-only : only return subdomains (skip related domains / wildcard entries)
assetfinder --subs-only "$DOMAIN" >> "$OUTPUT_FILE" 2>/dev/null

# Total lines in file so far; subtract previous count to get assetfinder's contribution
TOTAL_AFTER_ASSET=$(wc -l < "$OUTPUT_FILE")
ASSETFINDER_COUNT=$((TOTAL_AFTER_ASSET - SUBFINDER_COUNT))
echo "[+] assetfinder found: $ASSETFINDER_COUNT subdomains"
echo ""

# ── 3. Sublist3r ─────────────────────────────────────────────────────────────

echo "[*] Running sublist3r on $DOMAIN ..."

# -d : target domain
# -o : output file (sublist3r appends if file exists)
# Sublist3r prints a lot of status info to stdout; redirect stderr to suppress errors
sublist3r -d "$DOMAIN" -o /tmp/sublist3r_tmp.txt > /dev/null 2>&1

# Append sublist3r results (from its temp file) into our master file
if [ -f /tmp/sublist3r_tmp.txt ]; then
    cat /tmp/sublist3r_tmp.txt >> "$OUTPUT_FILE"
    rm /tmp/sublist3r_tmp.txt   # clean up the temp file
fi

TOTAL_AFTER_SUB=$(wc -l < "$OUTPUT_FILE")
SUBLIST3R_COUNT=$((TOTAL_AFTER_SUB - TOTAL_AFTER_ASSET))
echo "[+] sublist3r found  : $SUBLIST3R_COUNT subdomains"
echo ""

# ── Deduplication ─────────────────────────────────────────────────────────────

# All three tools may return overlapping results.
# Sort and remove duplicates, then write back to the same file.
sort -u "$OUTPUT_FILE" -o "$OUTPUT_FILE"

# ── Final Summary ─────────────────────────────────────────────────────────────

TOTAL_UNIQUE=$(wc -l < "$OUTPUT_FILE")

echo "============================================="
echo "   Recon Complete!"
echo "---------------------------------------------"
echo "   subfinder    : $SUBFINDER_COUNT"
echo "   assetfinder  : $ASSETFINDER_COUNT"
echo "   sublist3r    : $SUBLIST3R_COUNT"
echo "---------------------------------------------"
echo "   Total unique subdomains: $TOTAL_UNIQUE"
echo "   Saved to : $OUTPUT_FILE"
echo "============================================="
echo ""

# ── HTTP Status Check (opt-in via --ch) ───────────────────────────────────────
# When --ch is passed, hand the freshly-collected subdomains to status_check.sh,
# which visits each host and reports its HTTP response code (200 / 404 / 503 ...).
if [ "$RUN_STATUS_CHECK" = true ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/status_check.sh" ]; then
        bash "$SCRIPT_DIR/status_check.sh" "$OUTPUT_FILE"
    else
        echo "[!] status_check.sh not found in $SCRIPT_DIR - skipping HTTP status check."
        echo ""
    fi
fi

# =============================================================================
# passive_refs.sh - Passive Subdomain Reconnaissance Reference Links
# Usage: ./passive_refs.sh -u "varonis.com"
# Prints clickable/copyable URLs pre-filled with your target domain
# =============================================================================

echo ""
echo "============================================================="
echo "   Passive Subdomain Resources  |  Target: $DOMAIN"
echo "============================================================="
echo ""
echo " Subdomains can also be found online, here are some of the resources preferred by the author:"
echo ""

# ── Core Four that I Personally Use  ──────────────────────────────────────────

# 1. VirusTotal - Passive DNS, crawled URLs, subdomains from AV telemetry
echo " 1. VirusTotal (Passive DNS + AV telemetry)"
echo "    https://www.virustotal.com/"
echo ""
# 2. Hurricane Electric BGP - DNS records, ASN info, reverse DNS
echo " 2. Hurricane Electric BGP (DNS + ASN records)"
echo "    https://bgp.he.net/"
echo ""

# 3. SubdomainFinder c99 - Aggregates multiple passive sources
echo " 3. SubdomainFinder c99 (Multi-source passive lookup)"
echo "    https://subdomainfinder.c99.nl/"
echo ""

# 4. crt.sh - Certificate Transparency logs (very reliable for new subdomains)
echo " 4. crt.sh (Certificate Transparency logs)"
echo "    https://crt.sh/"
echo ""

# ── Footer ────────────────────────────────────────────────────────────────────

echo "=================================================================="
echo "  Tip: crt.sh and VirusTotal are some of the best starting points."
echo "  These 4 are a good starting point for most beginners."
echo "  Users can look for DNS, CT Records for much better OSINT."
echo "=================================================================="
echo ""
