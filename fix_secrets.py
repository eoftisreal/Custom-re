import re

with open(".github/workflows/build-coinos-digitalocean.yml", "r") as f:
    content = f.read()

# Replace secrets.XXXX != '' with secrets.XXXX != '' within if conditions
content = re.sub(r"secrets\.([A-Z_]+)\s*!=\s*''", r"secrets.\1 != ''", content)

with open(".github/workflows/build-coinos-digitalocean.yml", "w") as f:
    f.write(content)
