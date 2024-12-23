import yaml
import subprocess
import os

with open('manifest.yml') as f:
    manifest = yaml.safe_load(f)

for repo in manifest['repositories']:
    if not os.path.exists(repo['path']):
        subprocess.run(['git', 'clone', repo['url'], repo['path']])
    else:
        print(f"Directory {repo['path']} already exists. Skipping clone.")
