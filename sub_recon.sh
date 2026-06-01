#!/bin/bash 

# =============================================================================
# sub_recon.sh - Automated Subdomain Reconnaissance Script
# Usage: ./sub_recon.sh -u "example.com"
# Tools required: subfinder, assetfinder, sublist3r
# =============================================================================

# ── Argument Parsing ──────────────────────────────────────────────────────────

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 -u <domain>"
    echo "Example: $0 -u tesla.com"
    exit 1
fi

# Parse the -u flag to capture the target domain
while getopts "u:" opt; do
    case $opt in
        u) DOMAIN="$OPTARG" ;;
        *) echo "Invalid option. Usage: $0 -u <domain>"; exit 1 ;;
    esac
done

# Exit if domain is still empty after parsing
if [ -z "$DOMAIN" ]; then
    echo "[!] Error: No domain provided. Use -u <domain>"
    exit 1
fi

# ── Setup ─────────────────────────────────────────────────────────────────────

# Output directory and file where all subdomains will be collected
OUTPUT_DIR="./sub-output"
OUTPUT_FILE="$OUTPUT_DIR/subdomains.txt"

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

echo "============================================================="
echo "  Tip: crt.sh and VirusTotal are the best starting points."
echo "  These 4 are a good starting point for most beginners."
echo "  Users can look for DNS, CT Records for more better OSINT."
echo "============================================================="
echo ""
