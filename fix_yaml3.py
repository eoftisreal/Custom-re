with open(".github/workflows/build-coinos-digitalocean.yml", "r") as f:
    lines = f.readlines()

new_lines = []
skip_lines = 0

for i, line in enumerate(lines):
    if skip_lines > 0:
        skip_lines -= 1
        continue

    if "if: >" in line and "success()" in lines[i+1] and "secrets.DO_SPACES_KEY" in lines[i+2]:
        new_lines.append("        if: ${{ success() && secrets.DO_SPACES_KEY != '' && secrets.DO_SPACES_SECRET != '' }}\n")
        skip_lines = 3
    elif "if: >" in line and "always()" in lines[i+1] and "notify_slack" in lines[i+2] and "secrets.SLACK" in lines[i+3]:
        new_lines.append("        if: ${{ always() && github.event.inputs.notify_slack == 'true' && secrets.SLACK_WEBHOOK_URL != '' }}\n")
        skip_lines = 3
    elif "if: >" in line and "always()" in lines[i+1] and "notify_email" in lines[i+2] and "secrets.NOTIFY" in lines[i+3]:
        new_lines.append("        if: ${{ always() && github.event.inputs.notify_email == 'true' && secrets.NOTIFY_EMAIL != '' && secrets.SENDGRID_API_KEY != '' }}\n")
        skip_lines = 4
    else:
        new_lines.append(line)

with open(".github/workflows/build-coinos-digitalocean.yml", "w") as f:
    f.writelines(new_lines)
