#!/bin/bash
# =============================================================================
# status_check.sh - Visit each discovered subdomain and print its HTTP status
# Usage  : ./status_check.sh <subdomains_file>
# Input  : a subdomain list, e.g. ./sub_recon/example_com.txt (from sub_recon.sh)
# Output : <subdomains_file>_status.txt   (e.g. ./sub_recon/example_com_status.txt)
# =============================================================================

INPUT_FILE="$1"
TIMEOUT=10   # per-request timeout, in seconds

if [ -z "$INPUT_FILE" ] || [ ! -f "$INPUT_FILE" ]; then
    echo "[!] Subdomains file not found: ${INPUT_FILE:-<none given>}"
    echo "    Run sub_recon.sh first, or pass a list: $0 ./sub_recon/<domain>.txt"
    exit 1
fi

# Save results next to the input list, e.g. example_com.txt -> example_com_status.txt
RESULTS_FILE="${INPUT_FILE%.txt}_status.txt"

echo ""
echo "============================================="
echo "   HTTP Status Check"
echo "============================================="
echo ""

> "$RESULTS_FILE"

while read -r host; do
    [ -z "$host" ] && continue

    # Try https first; if there's no response (000), fall back to http.
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "https://$host")
    [ "$code" = "000" ] && code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "http://$host")

    # Colour by class: 2xx green, 3xx cyan, 4xx yellow, 5xx red, dead grey.
    case "$code" in
        2*) c="\033[1;32m" ;;
        3*) c="\033[1;36m" ;;
        4*) c="\033[1;33m" ;;
        5*) c="\033[1;31m" ;;
        *)  c="\033[1;90m" ;;
    esac

    printf "  ${c}[%s]\033[0m  %s\n" "$code" "$host"
    echo "$code $host" >> "$RESULTS_FILE"
done < "$INPUT_FILE"

echo ""
echo "[+] Results saved to: $RESULTS_FILE"
echo ""
