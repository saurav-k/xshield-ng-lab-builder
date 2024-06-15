import re

def apply_patch(yaml_text, patch_text):
    lines = yaml_text.split('\n')
    patch_lines = [line for line in patch_text.splitlines() if line.strip()]
    
    # Process additions
    additions = []
    current_addition = None
    delete_patterns = []

    for patch_line in patch_lines:
        if patch_line.startswith('+ '):
            if current_addition:
                additions.append(current_addition)
            path = patch_line[2:].strip()
            current_addition = {'path': path, 'lines': []}
        elif patch_line.startswith('- '):
            if current_addition:
                additions.append(current_addition)
                current_addition = None
            delete_patterns.append(patch_line[2:].strip())
        elif current_addition is not None:
            current_addition['lines'].append(patch_line)

    if current_addition:
        additions.append(current_addition)

    result = []
    skip_block = False

    for line in lines:
        if any(re.search(r'\b' + re.escape(pattern) + r'\b', line) for pattern in delete_patterns):
            continue
        result.append(line)

    yaml_text = '\n'.join(result)
    lines = yaml_text.split('\n')
    result = []
    
    for line in lines:
        result.append(line)
        for addition in additions:
            path = addition['path']
            add_lines = addition['lines']
            if re.search(r'\b' + re.escape(path) + r'\b', line):
                indent_level = len(line) - len(line.lstrip())
                for add_line in add_lines:
                    add_line_indent = len(add_line) - len(add_line.lstrip())
                    result.append(' ' * (indent_level + add_line_indent - 2) + add_line.lstrip())
                break

    return '\n'.join([line for line in result if line.strip()])

def main():
    with open('orig.yaml', 'r') as f:
        yaml_text = f.read()

    with open('yaml_patch.txt', 'r') as f:
        patch_text = f.read()
    
    modified_yaml_text = apply_patch(yaml_text, patch_text)
    
    with open('new.yaml', 'w') as f:
        f.write(modified_yaml_text)

if __name__ == "__main__":
    main()
