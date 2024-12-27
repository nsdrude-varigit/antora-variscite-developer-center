#!/usr/bin/env bash

if [ -z "$IN_NIX_SHELL" ]; then
    # Check if nix-shell is available and use shell.nix if it exists
    if command -v nix-shell >/dev/null 2>&1 && [ -f shell.nix ]; then
        echo "Using nix-shell with shell.nix to run this script..."
        nix-shell shell.nix --run "$0 $@"
        exit $?
    elif ! command -v nix-shell >/dev/null 2>&1; then
        echo "nix-shell not available. Continuing without it..."
    fi
fi

# Make the script variables readonly for safety
readonly FILE_SCRIPT="$(basename "$0")"
readonly DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Define source and output paths
readonly ANTORA_UI_BUNDLE="$DIR_SCRIPT/src/antora-ui-variscite"
readonly ANTORA_UI_BUNDLE_ARCHIVE="$ANTORA_UI_BUNDLE/build/ui-bundle.zip"

# Check for --deploy argument
DEPLOY_TO_GITHUB=false
# Process arguments
while (( "$#" )); do
    case "$1" in
        --deploy)
            DEPLOY_TO_GITHUB=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --deploy   Deploy to GitHub"
            echo "  --help, -h Show this help message"
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use --help to display usage information."
            exit 1
            ;;
    esac
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
if [ "$DEPLOY_TO_GITHUB" != "true" ]; then
    # Build it for localhost
    URL="${DIR_SCRIPT}/build/site/index.html" npx antora playbook.yml
else
    # Build it for github public site, defined in playbook.yml
    npx antora playbook.yml
fi

if [ "$DEPLOY_TO_GITHUB" == "true" ]; then
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