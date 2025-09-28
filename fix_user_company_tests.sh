#!/bin/bash

# Script to fix user_company integration tests
# This adds static testMenuOptions and replaces menuOptions calls

USER_COMPANY_DIR="/home/hans/growerp/flutter/packages/growerp_user_company/example/integration_test"

# Define the static menu template
MENU_OPTIONS='
// Static menuOptions for testing (no localization needed)
List<MenuOption> testMenuOptions = [
  MenuOption(
    image: '\''packages/growerp_core/images/dashBoardGrey.png'\'',
    selectedImage: '\''packages/growerp_core/images/dashBoard.png'\'',
    title: '\''Main'\'',
    route: '\''/'\''
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const MainMenu(),
  ),
];
'

cd "$USER_COMPANY_DIR"

# Get list of dart files to fix (exclude already fixed ones)
FILES=$(find . -name "*.dart" | grep -v user_supplier_test.dart | grep -v user_lead_test.dart)

for file in $FILES; do
    echo "Fixing $file..."
    
    # Add menu options after imports
    # Look for the line after the last import and before void main() or Future<void> main()
    awk -v menu="$MENU_OPTIONS" '
    /^import/ { imports++; }
    /^void main\(\)|^Future<void> main\(\)/ && !added { 
        print menu; 
        added=1; 
    }
    { print; }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    
    # Replace menuOptions with testMenuOptions
    sed -i 's/menuOptions,/testMenuOptions,/g' "$file"
done

echo "Fixed all files in $USER_COMPANY_DIR"