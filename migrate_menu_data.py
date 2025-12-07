import xml.etree.ElementTree as ET
import re

file_path = 'moqui/runtime/component/growerp/data/GrowerpMenuSeedData.xml'

with open(file_path, 'r') as f:
    content = f.read()

# Simple regex-based approach might be safer to preserve comments and layout than full XML parsing which might reformat everything
# Pattern: <growerp.menu.MenuItem ... />

def process_match(match):
    full_tag = match.group(0)
    
    # Extract attributes
    menu_config_id_match = re.search(r'menuConfigurationId="([^"]+)"', full_tag)
    menu_item_id_match = re.search(r'menuItemId="([^"]+)"', full_tag)
    is_active_match = re.search(r'isActive="([^"]+)"', full_tag)
    
    if not menu_config_id_match or not menu_item_id_match:
        return full_tag # Should not happen based on file structure
        
    menu_config_id = menu_config_id_match.group(1)
    menu_item_id = menu_item_id_match.group(1)
    is_active = is_active_match.group(1) if is_active_match else 'Y'
    
    # Remove attributes from MenuItem
    new_tag = re.sub(r'\s*menuConfigurationId="[^"]+"', '', full_tag)
    new_tag = re.sub(r'\s*isActive="[^"]+"', '', new_tag)
    
    # Create MenuOption tag
    # Indent it same as the MenuItem
    indent = re.match(r'^\s*', full_tag).group(0) if re.match(r'^\s*', full_tag) else '    '
    # Actually match.group(0) includes leading whitespace if the regex covered it. 
    # My regex below needs to catch the whitespace to get indentation or I assume 4 spaces.
    
    menu_option = f'<growerp.menu.MenuOption menuConfigurationId="{menu_config_id}" menuItemId="{menu_item_id}"'
    if is_active != 'Y':
        menu_option += f' isActive="{is_active}"'
    menu_option += "/>"
    
    return f'{new_tag}\n    {menu_option}' # Add extra indentation for the new tag to look nice

# Regex to find MenuItem tags across multiple lines
# We look for <growerp.menu.MenuItem ... />
pattern = re.compile(r'<growerp\.menu\.MenuItem\s+[^>]+/>', re.DOTALL)

new_content = pattern.sub(process_match, content)

with open(file_path, 'w') as f:
    f.write(new_content)

print("Migration complete.")
