#!/bin/bash
set -euo pipefail

echo "🔍 Checking iOS Code Signing Setup for org.growerp.admin"
echo "=========================================================="
echo ""

# Check installed certificates
echo "📜 Installed Distribution Certificates:"
security find-identity -v -p codesigning | grep "Apple Distribution"
echo ""

# Check provisioning profiles
echo "📱 Installed Provisioning Profiles:"
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PROFILE_DIR" ]; then
  for profile in "$PROFILE_DIR"/*.mobileprovision; do
    if [ -f "$profile" ]; then
      name=$(security cms -D -i "$profile" 2>/dev/null | plutil -extract Name raw - 2>/dev/null || echo "Unknown")
      if [[ "$name" == *"growerp.admin"* ]]; then
        echo "  Profile: $name"
        echo "  File: $(basename "$profile")"
        # Check certificates in the profile
        echo "  Certificates in profile:"
        security cms -D -i "$profile" 2>/dev/null | plutil -extract DeveloperCertificates raw - 2>/dev/null | openssl x509 -inform DER -noout -subject 2>/dev/null || echo "    (Could not extract cert info)"
        echo ""
      fi
    fi
  done
else
  echo "  No provisioning profiles directory found"
fi

echo ""
echo "🔧 Recommended Fix:"
echo "-------------------"
echo "cd flutter/packages/admin/ios"
echo "bundle exec fastlane match appstore --force"
echo ""
echo "Or to completely regenerate:"
echo "bundle exec fastlane match nuke distribution"
echo "bundle exec fastlane match appstore"
