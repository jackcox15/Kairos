#!/usr/bin/bash
#RUN ME FIRST THIS GENERATES A NEW DEPLOY_RNS SCRIPT! 

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SOURCE_SCRIPT="deploy_rns.sh"
OUTPUT_DIR="./configured_scripts"

if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo -e "${RED}Error: $SOURCE_SCRIPT not found!${NC}"
    exit 1
fi

echo -e "${PURPLE}=== WireGuard Key Baker ===${NC}"
echo ""

# Simple direct input - no fancy validation
echo -e "${CYAN}Client name:${NC}"
read CLIENT_NAME

echo -e "${CYAN}Private key:${NC}" 
read WG_PRIVATE_KEY

echo -e "${CYAN}Public key:${NC}"
read WG_PUBLIC_KEY

echo -e "${CYAN}Client IP (e.g. 10.5.5.11):${NC}"
read WG_CLIENT_IP

echo -e "${CYAN}Server public key:${NC}"
read WG_SERVER_PUBLIC_KEY

echo -e "${CYAN}Endpoint (e.g. 64.176.53.32:51820):${NC}"
read WG_ENDPOINT

echo -e "${CYAN}Internal VPS IP (e.g. 10.5.5.2):${NC}"
read WG_INTERNAL_IP

# Create output
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/deploy_rns_${CLIENT_NAME}.sh"

# Copy and replace
cp "$SOURCE_SCRIPT" "$OUTPUT_FILE"

# Show what we're about to replace
echo -e "${BLUE}Replacing placeholders...${NC}"

sed -i "s@WG_PRIVATE_KEY=\"__REPLACE_PRIVATE_KEY__\"@WG_PRIVATE_KEY=\"$WG_PRIVATE_KEY\"@g" "$OUTPUT_FILE"
sed -i "s@WG_PUBLIC_KEY=\"__REPLACE_PUBLIC_KEY__\"@WG_PUBLIC_KEY=\"$WG_PUBLIC_KEY\"@g" "$OUTPUT_FILE"
sed -i "s@WG_CLIENT_IP=\"__REPLACE_CLIENT_IP__\"@WG_CLIENT_IP=\"$WG_CLIENT_IP\"@g" "$OUTPUT_FILE"
sed -i "s@WG_SERVER_PUBLIC_KEY=\"__REPLACE_SERVER_PUBLIC_KEY__\"@WG_SERVER_PUBLIC_KEY=\"$WG_SERVER_PUBLIC_KEY\"@g" "$OUTPUT_FILE"
sed -i "s@WG_ENDPOINT=\"__REPLACE_ENDPOINT__\"@WG_ENDPOINT=\"$WG_ENDPOINT\"@g" "$OUTPUT_FILE"
sed -i "s@WG_INTERNAL_IP=\"__REPLACE_INTERNAL_IP__\"@WG_INTERNAL_IP=\"$WG_INTERNAL_IP\"@g" "$OUTPUT_FILE"
chmod +x "$OUTPUT_FILE"

# VERIFY THE REPLACEMENTS WORKED
echo -e "${BLUE}Verifying replacements...${NC}"
# Check for placeholders in variable assignments (these should be replaced)
if grep -q 'WG_.*="__REPLACE_.*"' "$OUTPUT_FILE"; then
    echo -e "${RED}ERROR: Variable placeholders still found!${NC}"
    grep 'WG_.*="__REPLACE_.*"' "$OUTPUT_FILE"
    exit 1
else
    echo -e "${GREEN}All variable placeholders replaced successfully${NC}"
fi

# Verify validation check still has placeholder (this should NOT be replaced)
if grep -q '== "__REPLACE_PRIVATE_KEY__"' "$OUTPUT_FILE"; then
    echo -e "${GREEN}Validation check preserved correctly${NC}"
else
    echo -e "${RED}ERROR: Validation check was corrupted!${NC}"
    exit 1
fi
echo -e "${GREEN}Done! Created: $OUTPUT_FILE${NC}"

# Show first few lines of WG config in output file to verify
echo -e "${BLUE}WireGuard variables in generated file:${NC}"
grep "WG_.*=" "$OUTPUT_FILE" | head -6
