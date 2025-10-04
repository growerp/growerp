import sys
import os
import re

def clean_arb_file(filepath):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    with open(filepath, 'r') as f:
        lines = f.readlines()

    cleaned_lines = []
    in_meta_block = False
    for line in lines:
        if re.match(r'^\s*"@.*":\s*\{', line):
            in_meta_block = True
        if not in_meta_block:
            cleaned_lines.append(line)
        if in_meta_block and re.match(r'^\s*\},?', line):
            in_meta_block = False

    # Remove trailing commas from the last element before a closing brace
    cleaned_content = "".join(cleaned_lines)
    cleaned_content = re.sub(r',\s*(\n\s*\})', r'\1', cleaned_content)


    with open(filepath, 'w') as f:
        f.write(cleaned_content)

if __name__ == "__main__":
    for filepath in sys.argv[1:]:
        clean_arb_file(filepath)