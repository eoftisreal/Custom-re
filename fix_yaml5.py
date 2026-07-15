with open(".github/workflows/build-coinos-digitalocean.yml", "r") as f:
    lines = f.readlines()

new_lines = []
skip_lines = 0

for i, line in enumerate(lines):
    if skip_lines > 0:
        skip_lines -= 1
        continue

    if "- name: Notify Slack on completion" in line:
        skip_lines = 49 # Skip the rest of the file
    elif "if: ${{ success()" in line:
        new_lines.append("        if: success()\n")
    else:
        new_lines.append(line)

with open(".github/workflows/build-coinos-digitalocean.yml", "w") as f:
    f.writelines(new_lines)
