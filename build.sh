#!/bin/bash -e

# Make the script variables readonly for safety
readonly FILE_SCRIPT="$(basename "$0")"
readonly DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Define source and output paths
readonly ANTORA_UI_BUNDLE="$DIR_SCRIPT/src/antora-ui-variscite"
readonly ANTORA_UI_BUNDLE_ARCHIVE="$ANTORA_UI_BUNDLE/build/ui-bundle.zip"

# Check for --deploy argument
DEPLOY_TO_GITHUB=false
for arg in "$@"; do
    if [ "$arg" == "--deploy" ]; then
        DEPLOY=true
        break
    fi
done

# Fetch the repos if they don't exist already
cd $DIR_SCRIPT
echo "Fetching repositories"
python3 fetch-repos.py

# Change to the bundle directory
if [ ! -f "$ANTORA_UI_BUNDLE_ARCHIVE" ]; then
    cd "$ANTORA_UI_BUNDLE"
    npm install
    gulp bundle
fi

# Return to the original script directory
cd "$DIR_SCRIPT"

# Run Antora to build the site
if [ "DEPLOY" != "true" ]; then
    # Build it for localhost
    URL="${DIR_SCRIPT}/build/site/index.html" npx antora playbook.yml
else
    # Build it for github public site, defined in playbook.yml
    npx antora playbook.yml
fi

if [ "$DEPLOY" == "true" ]; then
    # Push the output to GitHub
    OUTPUT_DIR=${DIR_SCRIPT}/build/site/
    BRANCH="www"
    GITHUB_REPO="git@github.com:nsdrude-varigit/antora-variscite-developer-center.git"

    echo "Pushing output to GitHub repository: $GITHUB_REPO"

    # Check if the output directory exists
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo "Output directory $OUTPUT_DIR does not exist. Build failed."
        exit 1
    fi

    # Prepare the repository
    cd "$OUTPUT_DIR"
    # Clean any previos pushes
    rm -rf .git
    git init
    git remote add origin "$GITHUB_REPO"
    git checkout -b "$BRANCH"

    # Add and commit the build output
    touch .nojekyll
    git add .
    git commit -m "Update site content - $(date)"

    # Force push to the specified branch
    git push --force origin "$BRANCH"

    echo "Deployment complete."
fi