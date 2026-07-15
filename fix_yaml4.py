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
    elif "DO_SPACES_KEY: ${{ secrets.DO_SPACES_KEY }}" in line or "DO_SPACES_SECRET: ${{ secrets.DO_SPACES_SECRET }}" in line or "DO_SPACES_BUCKET: ${{ secrets.DO_SPACES_BUCKET }}" in line or "DO_SPACES_REGION: ${{ secrets.DO_SPACES_REGION }}" in line or "# Requires secrets: DO_SPACES_KEY" in line:
        continue
    elif "run: |" in line and "OUT_DIR=\"${WORKSPACE_DIR}/out/target/product/j7xelte\"" in lines[i+1] and "REGION=\"${DO_SPACES_REGION:-nyc3}\"" in lines[i+2]:
        new_lines.append(line)
        new_lines.append("          if [ -z \"${DO_SPACES_KEY}\" ] || [ -z \"${DO_SPACES_SECRET}\" ]; then\n")
        new_lines.append("            echo \"Skipping upload: DO_SPACES_KEY or DO_SPACES_SECRET is not set.\"\n")
        new_lines.append("            exit 0\n")
        new_lines.append("          fi\n")
    else:
        new_lines.append(line)

with open(".github/workflows/build-coinos-digitalocean.yml", "w") as f:
    f.writelines(new_lines)
