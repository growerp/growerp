#!/bin/bash

# GrowERP Deep Link Configuration Generator
# This script generates the configuration files needed for HTTPS deep links

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  GrowERP Deep Link Configuration Generator            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Get app selection
echo -e "${BLUE}Select app to configure:${NC}"
echo "1) Admin"
echo "2) Support"
echo "3) Hotel"
echo "4) All apps"
read -p "Enter choice [1-4]: " app_choice

case $app_choice in
    1) APPS=("admin") ;;
    2) APPS=("support") ;;
    3) APPS=("hotel") ;;
    4) APPS=("admin" "support" "hotel") ;;
    *) print_error "Invalid choice"; exit 1 ;;
esac

# Get keystore info
echo ""
echo -e "${BLUE}Android Configuration${NC}"
echo "Select keystore type:"
echo "1) Debug keystore (for testing)"
echo "2) Release keystore (for production)"
read -p "Enter choice [1-2]: " keystore_choice

if [ "$keystore_choice" = "1" ]; then
    KEYSTORE_PATH="$HOME/.android/debug.keystore"
    KEYSTORE_ALIAS="androiddebugkey"
    KEYSTORE_PASS="android"
    KEY_PASS="android"
else
    read -p "Enter keystore path: " KEYSTORE_PATH
    read -p "Enter keystore alias: " KEYSTORE_ALIAS
    read -sp "Enter keystore password: " KEYSTORE_PASS
    echo ""
    read -sp "Enter key password: " KEY_PASS
    echo ""
fi

# Expand tilde in path
KEYSTORE_PATH="${KEYSTORE_PATH/#\~/$HOME}"

# Verify keystore exists
if [ ! -f "$KEYSTORE_PATH" ]; then
    print_error "Keystore not found at: $KEYSTORE_PATH"
    exit 1
fi

# Get SHA256 fingerprint
print_info "Extracting SHA256 fingerprint..."
SHA256=$(keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$KEYSTORE_ALIAS" -storepass "$KEYSTORE_PASS" -keypass "$KEY_PASS" 2>/dev/null | grep "SHA256:" | cut -d' ' -f3)

if [ -z "$SHA256" ]; then
    print_error "Failed to extract SHA256 fingerprint"
    exit 1
fi

print_success "SHA256: $SHA256"

# Get iOS Team ID
echo ""
echo -e "${BLUE}iOS Configuration${NC}"
read -p "Enter your Apple Team ID (e.g., ABCD123456): " TEAM_ID

if [ -z "$TEAM_ID" ]; then
    print_warning "No Team ID provided. iOS configuration will be skipped."
fi

# Get domain configuration
echo ""
echo -e "${BLUE}Domain Configuration${NC}"
print_info "Default domains: admin.growerp.com, support.growerp.com, hotel.growerp.com"
read -p "Use custom domains? (y/n): " use_custom

if [ "$use_custom" = "y" ]; then
    for app in "${APPS[@]}"; do
        read -p "Enter domain for $app app: " domain
        eval "${app}_domain=$domain"
    done
else
    admin_domain="admin.growerp.com"
    support_domain="support.growerp.com"
    hotel_domain="hotel.growerp.com"
fi

# Create output directory
OUTPUT_DIR="deep-link-config"
mkdir -p "$OUTPUT_DIR"

print_info "Creating configuration files in $OUTPUT_DIR/"

# Generate files for each app
for app in "${APPS[@]}"; do
    PACKAGE_NAME="org.growerp.$app"
    domain_var="${app}_domain"
    DOMAIN="${!domain_var}"
    
    APP_DIR="$OUTPUT_DIR/$app"
    mkdir -p "$APP_DIR/.well-known"
    
    print_info "Generating files for $app app ($DOMAIN)..."
    
    # Create assetlinks.json (Android)
    cat > "$APP_DIR/.well-known/assetlinks.json" <<EOF
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "$PACKAGE_NAME",
    "sha256_cert_fingerprints": [
      "$SHA256"
    ]
  }
}]
EOF
    
    # Create apple-app-site-association (iOS)
    if [ -n "$TEAM_ID" ]; then
        cat > "$APP_DIR/.well-known/apple-app-site-association" <<EOF
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "$TEAM_ID.$PACKAGE_NAME",
        "paths": ["*"]
      }
    ]
  }
}
EOF
    fi
    
    # Create README for this app
    cat > "$APP_DIR/README.md" <<EOF
# Deep Link Configuration for $app App

## Files Generated

- \`.well-known/assetlinks.json\` - Android App Links configuration
- \`.well-known/apple-app-site-association\` - iOS Universal Links configuration

## Upload Instructions

Upload these files to your web server:

\`\`\`
https://$DOMAIN/.well-known/assetlinks.json
https://$DOMAIN/.well-known/apple-app-site-association
\`\`\`

## Requirements

- ✅ Files must be served over HTTPS
- ✅ Files must be publicly accessible (no authentication)
- ✅ \`assetlinks.json\` must have \`Content-Type: application/json\`
- ✅ \`apple-app-site-association\` must have \`Content-Type: application/json\`

## Verification

**Android:**
\`\`\`bash
curl https://$DOMAIN/.well-known/assetlinks.json
\`\`\`

**iOS:**
\`\`\`bash
curl https://$DOMAIN/.well-known/apple-app-site-association
\`\`\`

## Testing

**Android:**
\`\`\`bash
adb shell am start -a android.intent.action.VIEW -d "https://$DOMAIN/user" $PACKAGE_NAME
\`\`\`

**iOS:**
\`\`\`bash
xcrun simctl openurl booted "https://$DOMAIN/user"
\`\`\`

## Configuration Details

- **Package Name:** $PACKAGE_NAME
- **Domain:** $DOMAIN
- **SHA256 Fingerprint:** $SHA256
- **Apple Team ID:** $TEAM_ID

For more information, see \`docs/deep_linking_production_setup.md\`
EOF
    
    print_success "Created configuration for $app app"
done

# Create master README
cat > "$OUTPUT_DIR/README.md" <<EOF
# GrowERP Deep Link Configuration Files

Generated on: $(date)

## Apps Configured

EOF

for app in "${APPS[@]}"; do
    domain_var="${app}_domain"
    DOMAIN="${!domain_var}"
    echo "- **$app**: https://$DOMAIN" >> "$OUTPUT_DIR/README.md"
done

cat >> "$OUTPUT_DIR/README.md" <<EOF

## Upload Instructions

For each app, upload the files in the \`.well-known\` directory to your web server:

\`\`\`
admin/.well-known/     → https://admin.growerp.com/.well-known/
support/.well-known/   → https://support.growerp.com/.well-known/
hotel/.well-known/     → https://hotel.growerp.com/.well-known/
\`\`\`

## Nginx Configuration Example

\`\`\`nginx
server {
    listen 443 ssl http2;
    server_name admin.growerp.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /.well-known/assetlinks.json {
        alias /var/www/admin.growerp.com/.well-known/assetlinks.json;
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    location /.well-known/apple-app-site-association {
        alias /var/www/admin.growerp.com/.well-known/apple-app-site-association;
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
}
\`\`\`

## Verification

After uploading, verify the files are accessible:

\`\`\`bash
curl https://admin.growerp.com/.well-known/assetlinks.json
curl https://admin.growerp.com/.well-known/apple-app-site-association
\`\`\`

## Testing

Use the provided test script:

\`\`\`bash
cd ..
./test_deep_link.sh -p android -a admin -r /user -s https
\`\`\`

## Configuration Details

- **Keystore:** $KEYSTORE_PATH
- **SHA256:** $SHA256
- **Apple Team ID:** $TEAM_ID

For detailed setup instructions, see \`docs/deep_linking_production_setup.md\`
EOF

# Create upload script
cat > "$OUTPUT_DIR/upload.sh" <<'EOF'
#!/bin/bash

# Upload script for deep link configuration files
# Customize this script for your deployment method

echo "This is a template upload script."
echo "Customize it for your deployment method (scp, rsync, etc.)"
echo ""
echo "Example using scp:"
echo ""
echo "scp -r admin/.well-known/* user@server:/var/www/admin.growerp.com/.well-known/"
echo "scp -r support/.well-known/* user@server:/var/www/support.growerp.com/.well-known/"
echo "scp -r hotel/.well-known/* user@server:/var/www/hotel.growerp.com/.well-known/"
echo ""
echo "Example using rsync:"
echo ""
echo "rsync -avz admin/.well-known/ user@server:/var/www/admin.growerp.com/.well-known/"
echo "rsync -avz support/.well-known/ user@server:/var/www/support.growerp.com/.well-known/"
echo "rsync -avz hotel/.well-known/ user@server:/var/www/hotel.growerp.com/.well-known/"
EOF

chmod +x "$OUTPUT_DIR/upload.sh"

# Summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Configuration files generated successfully!           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
print_success "Files created in: $OUTPUT_DIR/"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the generated files in $OUTPUT_DIR/"
echo "2. Upload the .well-known directories to your web servers"
echo "3. Verify files are accessible via HTTPS"
echo "4. Test deep links on your devices"
echo ""
echo -e "${BLUE}Quick verification:${NC}"
for app in "${APPS[@]}"; do
    domain_var="${app}_domain"
    DOMAIN="${!domain_var}"
    echo "curl https://$DOMAIN/.well-known/assetlinks.json"
done
echo ""
print_info "See $OUTPUT_DIR/README.md for detailed instructions"
print_info "See docs/deep_linking_production_setup.md for complete guide"
