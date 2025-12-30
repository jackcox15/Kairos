#!/usr/bin/bash
# WireGuard Credential Baker for KAIROS Deploy Script
# This script creates a customized deploy_rns.sh with your VPS credentials baked in

############################
### Colors
############################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

############################
### Variables
############################
SOURCE_SCRIPT="deploy_rns.sh"
OUTPUT_DIR="./configured_scripts"

############################
### Functions
############################

print_header() {
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════${NC}"
    echo -e "${PURPLE}   WireGuard Credential Baker${NC}"
    echo -e "${PURPLE}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}This tool creates a deploy_rns.sh with your VPS${NC}"
    echo -e "${CYAN}credentials embedded for easy deployment.${NC}"
    echo ""
}

validate_source() {
    if [ ! -f "$SOURCE_SCRIPT" ]; then
        echo -e "${RED}Error: $SOURCE_SCRIPT not found in current directory!${NC}"
        echo -e "${YELLOW}Make sure you're running this from the directory containing deploy_rns.sh${NC}"
        exit 1
    fi
    
    # Verify it has the placeholders we need
    if ! grep -q 'WG_PRIVATE_KEY="__REPLACE_PRIVATE_KEY__"' "$SOURCE_SCRIPT"; then
        echo -e "${RED}Error: $SOURCE_SCRIPT doesn't contain expected placeholders!${NC}"
        echo -e "${YELLOW}Are you using the correct version of deploy_rns.sh?${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Found $SOURCE_SCRIPT${NC}"
}

validate_wireguard_key() {
    local key="$1"
    local key_name="$2"
    
    if [[ ! "$key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
        echo -e "${YELLOW}⚠ Warning: $key_name doesn't match standard WireGuard format${NC}"
        echo -e "${YELLOW}  Expected: 44 characters ending with '='${NC}"
        echo -e "${YELLOW}  Got: ${#key} characters${NC}"
        echo ""
        echo -e "${BLUE}Continue anyway? (y/n)${NC}"
        read -r continue
        if [[ ! "$continue" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborted${NC}"
            exit 1
        fi
    fi
}

validate_ip() {
    local ip="$1"
    
    if [[ ! "$ip" =~ ^10\.5\.5\.[0-9]+$ ]]; then
        echo -e "${YELLOW}⚠ Warning: IP should be in 10.5.5.x format for VPS backbone${NC}"
        echo -e "${YELLOW}  You entered: $ip${NC}"
        echo ""
        echo -e "${BLUE}Continue anyway? (y/n)${NC}"
        read -r continue
        if [[ ! "$continue" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborted${NC}"
            exit 1
        fi
    fi
}

validate_endpoint() {
    local endpoint="$1"
    
    if [[ ! "$endpoint" =~ ^[a-zA-Z0-9.-]+:[0-9]+$ ]]; then
        echo -e "${YELLOW}⚠ Warning: Endpoint should be in format 'host:port'${NC}"
        echo -e "${YELLOW}  Examples: vps.example.com:51820 or 192.168.1.1:51820${NC}"
        echo -e "${YELLOW}  You entered: $endpoint${NC}"
        echo ""
        echo -e "${BLUE}Continue anyway? (y/n)${NC}"
        read -r continue
        if [[ ! "$continue" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborted${NC}"
            exit 1
        fi
    fi
}

collect_credentials() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Client Information${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${BLUE}Client name (e.g., detroit-node-01):${NC}"
    read -r CLIENT_NAME
    
    if [ -z "$CLIENT_NAME" ]; then
        echo -e "${RED}Client name cannot be empty${NC}"
        exit 1
    fi
    
    # Sanitize client name (remove spaces, special chars)
    CLIENT_NAME=$(echo "$CLIENT_NAME" | tr -cd '[:alnum:]-_')
    echo -e "${GREEN}Using client name: $CLIENT_NAME${NC}"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  WireGuard Credentials${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${BLUE}Client private key:${NC}"
    echo -e "${YELLOW}(44 chars, ends with '=')${NC}"
    read -r WG_PRIVATE_KEY
    validate_wireguard_key "$WG_PRIVATE_KEY" "Private key"
    echo ""
    
    echo -e "${BLUE}Client public key:${NC}"
    echo -e "${YELLOW}(44 chars, ends with '=')${NC}"
    read -r WG_PUBLIC_KEY
    validate_wireguard_key "$WG_PUBLIC_KEY" "Public key"
    echo ""
    
    echo -e "${BLUE}Client IP address (e.g., 10.5.5.11):${NC}"
    read -r WG_CLIENT_IP
    validate_ip "$WG_CLIENT_IP"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  VPS Server Information${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${BLUE}Server public key:${NC}"
    echo -e "${YELLOW}(44 chars, ends with '=')${NC}"
    read -r WG_SERVER_PUBLIC_KEY
    validate_wireguard_key "$WG_SERVER_PUBLIC_KEY" "Server public key"
    echo ""
    
    echo -e "${BLUE}VPS endpoint (e.g., vps.example.com:51820):${NC}"
    read -r WG_ENDPOINT
    validate_endpoint "$WG_ENDPOINT"
    echo ""
    
    echo -e "${BLUE}Internal VPS IP (e.g., 10.5.5.2):${NC}"
    read -r WG_INTERNAL_IP
    validate_ip "$WG_INTERNAL_IP"
    echo ""
}

show_summary() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Configuration Summary${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${PURPLE}Client:${NC}"
    echo -e "  Name: ${BLUE}$CLIENT_NAME${NC}"
    echo -e "  IP: ${BLUE}$WG_CLIENT_IP${NC}"
    echo -e "  Public Key: ${BLUE}${WG_PUBLIC_KEY:0:20}...${NC}"
    echo ""
    echo -e "${PURPLE}Server:${NC}"
    echo -e "  Endpoint: ${BLUE}$WG_ENDPOINT${NC}"
    echo -e "  Internal IP: ${BLUE}$WG_INTERNAL_IP${NC}"
    echo -e "  Public Key: ${BLUE}${WG_SERVER_PUBLIC_KEY:0:20}...${NC}"
    echo ""
    echo -e "${BLUE}Proceed with these settings? (y/n)${NC}"
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
}

create_configured_script() {
    echo ""
    echo -e "${BLUE}Creating configured script...${NC}"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Define output file
    OUTPUT_FILE="$OUTPUT_DIR/deploy_rns_${CLIENT_NAME}.sh"
    
    # Check if file exists
    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "${YELLOW}Warning: $OUTPUT_FILE already exists${NC}"
        echo -e "${BLUE}Overwrite? (y/n)${NC}"
        read -r overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Aborted${NC}"
            exit 0
        fi
    fi
    
    # Copy source script
    cp "$SOURCE_SCRIPT" "$OUTPUT_FILE" || {
        echo -e "${RED}Failed to copy script${NC}"
        exit 1
    }
    
    # Replace placeholders
    echo -e "${BLUE}Replacing credentials...${NC}"
    
    # Use @ as delimiter to avoid issues with / in base64
    sed -i "s@WG_PRIVATE_KEY=\"__REPLACE_PRIVATE_KEY__\"@WG_PRIVATE_KEY=\"$WG_PRIVATE_KEY\"@g" "$OUTPUT_FILE"
    sed -i "s@WG_PUBLIC_KEY=\"__REPLACE_PUBLIC_KEY__\"@WG_PUBLIC_KEY=\"$WG_PUBLIC_KEY\"@g" "$OUTPUT_FILE"
    sed -i "s@WG_CLIENT_IP=\"__REPLACE_CLIENT_IP__\"@WG_CLIENT_IP=\"$WG_CLIENT_IP\"@g" "$OUTPUT_FILE"
    sed -i "s@WG_SERVER_PUBLIC_KEY=\"__REPLACE_SERVER_PUBLIC_KEY__\"@WG_SERVER_PUBLIC_KEY=\"$WG_SERVER_PUBLIC_KEY\"@g" "$OUTPUT_FILE"
    sed -i "s@WG_ENDPOINT=\"__REPLACE_ENDPOINT__\"@WG_ENDPOINT=\"$WG_ENDPOINT\"@g" "$OUTPUT_FILE"
    sed -i "s@WG_INTERNAL_IP=\"__REPLACE_INTERNAL_IP__\"@WG_INTERNAL_IP=\"$WG_INTERNAL_IP\"@g" "$OUTPUT_FILE"
    
    # Make executable
    chmod +x "$OUTPUT_FILE"
    
    echo -e "${GREEN}✓ Script created${NC}"
}

verify_replacements() {
    echo -e "${BLUE}Verifying replacements...${NC}"
    
    local errors=0
    
    # Check that variable assignments were replaced (no placeholders in assignments)
    if grep -q 'WG_PRIVATE_KEY="__REPLACE_PRIVATE_KEY__"' "$OUTPUT_FILE"; then
        echo -e "${RED}✗ Private key not replaced${NC}"
        errors=$((errors + 1))
    fi
    
    if grep -q 'WG_PUBLIC_KEY="__REPLACE_PUBLIC_KEY__"' "$OUTPUT_FILE"; then
        echo -e "${RED}✗ Public key not replaced${NC}"
        errors=$((errors + 1))
    fi
    
    if grep -q 'WG_CLIENT_IP="__REPLACE_CLIENT_IP__"' "$OUTPUT_FILE"; then
        echo -e "${RED}✗ Client IP not replaced${NC}"
        errors=$((errors + 1))
    fi
    
    if grep -q 'WG_SERVER_PUBLIC_KEY="__REPLACE_SERVER_PUBLIC_KEY__"' "$OUTPUT_FILE"; then
        echo -e "${RED}✗ Server public key not replaced${NC}"
        errors=$((errors + 1))
    fi
    
    if grep -q 'WG_ENDPOINT="__REPLACE_ENDPOINT__"' "$OUTPUT_FILE"; then
        echo -e "${RED}✗ Endpoint not replaced${NC}"
        errors=$((errors + 1))
    fi
    
    if grep -q 'WG_INTERNAL_IP="__REPLACE_INTERNAL_IP__"' "$OUTPUT_FILE"; then
        echo -e "${RED}✗ Internal IP not replaced${NC}"
        errors=$((errors + 1))
    fi
    
    # Verify validation check still exists (this should NOT be replaced)
    if ! grep -q '== "__REPLACE_PRIVATE_KEY__"' "$OUTPUT_FILE"; then
        echo -e "${RED}✗ Validation check was corrupted!${NC}"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "${RED}Verification failed with $errors errors${NC}"
        echo -e "${YELLOW}The generated script may not work correctly${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All replacements verified${NC}"
}

show_completion() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Configuration Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${PURPLE}Created file:${NC}"
    echo -e "  ${BLUE}$OUTPUT_FILE${NC}"
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo ""
    echo -e "${CYAN}Option 1: Deploy on current machine${NC}"
    echo -e "  ${BLUE}cd $OUTPUT_DIR${NC}"
    echo -e "  ${BLUE}sudo ./$( basename $OUTPUT_FILE )${NC}"
    echo ""
    echo -e "${CYAN}Option 2: Deploy on remote machine${NC}"
    echo -e "  ${BLUE}scp $OUTPUT_FILE user@target:/tmp/${NC}"
    echo -e "  ${BLUE}ssh user@target${NC}"
    echo -e "  ${BLUE}sudo /tmp/$( basename $OUTPUT_FILE )${NC}"
    echo ""
    echo -e "${YELLOW}Security reminder:${NC}"
    echo -e "  This script contains your VPN private key!"
    echo -e "  - Transfer securely (scp, not public channels)"
    echo -e "  - Delete after deployment if not needed"
    echo -e "  - Never commit to version control"
    echo ""
}

show_credential_preview() {
    echo ""
    echo -e "${BLUE}Credentials in generated script:${NC}"
    grep "^WG_.*=" "$OUTPUT_FILE" | while read line; do
        var_name=$(echo "$line" | cut -d'=' -f1)
        var_value=$(echo "$line" | cut -d'"' -f2)
        
        # Truncate long values for display
        if [ ${#var_value} -gt 50 ]; then
            echo -e "  ${GREEN}$var_name${NC} = ${var_value:0:30}...${var_value: -10}"
        else
            echo -e "  ${GREEN}$var_name${NC} = ${var_value}"
        fi
    done
    echo ""
}

############################
### Main Script
############################

# Print header
print_header

# Validate source script exists
validate_source

# Collect credentials from user
collect_credentials

# Show summary and confirm
show_summary

# Create configured script
create_configured_script

# Verify replacements worked
verify_replacements

# Show credential preview
show_credential_preview

# Show completion instructions
show_completion

exit 0
