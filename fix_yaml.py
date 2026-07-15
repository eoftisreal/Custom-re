with open(".github/workflows/build-coinos-digitalocean.yml", "r") as f:
    lines = f.readlines()

new_lines = []
skip_lines = 0

for i, line in enumerate(lines):
    if skip_lines > 0:
        skip_lines -= 1
        continue

    if "if: >" in line and "success()" in lines[i+1] and "secrets.DO_SPACES_KEY" in lines[i+2]:
        new_lines.append("        if: success()\n")
        skip_lines = 3
    elif "if: >" in line and "always()" in lines[i+1] and "notify_slack" in lines[i+2] and "secrets.SLACK" in lines[i+3]:
        new_lines.append("        if: always() && github.event.inputs.notify_slack == 'true'\n")
        skip_lines = 4
    elif "if: >" in line and "always()" in lines[i+1] and "notify_email" in lines[i+2] and "secrets.NOTIFY" in lines[i+3]:
        new_lines.append("        if: always() && github.event.inputs.notify_email == 'true'\n")
        skip_lines = 4
    elif "run: |" in line and "OUT_DIR=\"${WORKSPACE_DIR}" in lines[i+1] and "REGION=" in lines[i+2]:
        new_lines.append(line)
        new_lines.append("          if [ -z \"${DO_SPACES_KEY}\" ] || [ -z \"${DO_SPACES_SECRET}\" ]; then\n")
        new_lines.append("            echo \"Skipping upload: DO_SPACES_KEY or DO_SPACES_SECRET is not set.\"\n")
        new_lines.append("            exit 0\n")
        new_lines.append("          fi\n")
    elif "run: |" in line and "COLOR=\"good\"" in lines[i+1] and "ICON=" in lines[i+2] and "if [ \"${JOB_STATUS}\"" in lines[i+3]:
        new_lines.append(line)
        new_lines.append("          if [ -z \"${SLACK_WEBHOOK_URL}\" ]; then\n")
        new_lines.append("            echo \"Skipping Slack notification: SLACK_WEBHOOK_URL is not set.\"\n")
        new_lines.append("            exit 0\n")
        new_lines.append("          fi\n")
    elif "run: |" in line and "curl -fsSL -X POST https://api.sendgrid.com" in lines[i+1] and "-H \"Authorization: Bearer" in lines[i+2]:
        new_lines.append(line)
        new_lines.append("          if [ -z \"${NOTIFY_EMAIL}\" ] || [ -z \"${SENDGRID_API_KEY}\" ]; then\n")
        new_lines.append("            echo \"Skipping email notification: NOTIFY_EMAIL or SENDGRID_API_KEY is not set.\"\n")
        new_lines.append("            exit 0\n")
        new_lines.append("          fi\n")
    else:
        new_lines.append(line)

with open(".github/workflows/build-coinos-digitalocean.yml", "w") as f:
    f.writelines(new_lines)
