#!/bin/bash
############### Configuration ###############
## Change these variables as needed to match your setup ##
MC_DIR="/usr/games/minecraft"

## You can change these, but that might impact functionality of other scripts
RUNNING_VERSION_FILE="$MC_DIR/.currentversion"
LINK_NAME="$MC_DIR/paperMC"
LOG_FILE="$MC_DIR/paper_update.log"
SCRIPTS_DIR="$MC_DIR/scripts"
MC_CTL_CMD="$SCRIPTS_DIR/minecraft_server_ctl.sh"

### If you change these things stuff will probably break ###
PROJECT="paper"
BASE_URL="https://fill.papermc.io/v3/projects"
USER_AGENT="minecraft-updater/1.0 (contact@example.com)"
CURRENT_VERSION=$(<"$RUNNING_VERSION_FILE")
############ End of Configuration #############

cd "$MC_DIR" || exit 1

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"; }

log "===== Paper update started ====="
log "Running version is $CURRENT_VERSION"

# Get all versions
VERSIONS_JSON=$(curl -s -H 'accept: application/json' "$BASE_URL/$PROJECT")

# Extract all stable versions and sort numerically
LATEST_VERSION=$(echo "$VERSIONS_JSON" \
    | jq -r '.versions | flatten | map(select(test("^(?!.*(-pre|-rc))"))) | 
        sort_by(split(".") | map(tonumber)) | last')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    log "Error: Could not determine latest stable version"
    exit 1
fi
log "Latest stable version: $LATEST_VERSION"

# Get the latest build for that version
LATEST_BUILD_JSON=$(curl -s -H 'accept: application/json' \
    "$BASE_URL/$PROJECT/versions/$LATEST_VERSION/builds/latest")

LATEST_BUILD=$(echo "$LATEST_BUILD_JSON" | jq -r '.id')
DOWNLOAD_URL=$(echo "$LATEST_BUILD_JSON" | jq -r '.downloads["server:default"].url')

if [ -z "$LATEST_BUILD" ] || [ "$LATEST_BUILD" = "null" ] || [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    log "Error: No valid build found for version $LATEST_VERSION"
    exit 1
fi

JAR_NAME="${PROJECT}-${LATEST_VERSION}-${LATEST_BUILD}.jar"
log "Latest build: $LATEST_BUILD"
log "Download URL: $DOWNLOAD_URL"
JAR_FILE="$MC_DIR/$JAR_NAME"

# Download the jar if missing
if [ -f "$JAR_FILE" ]; then
    log "Jar already exists: $JAR_NAME"
else
    log "Downloading $JAR_NAME..."
    curl -L -H "User-Agent: $USER_AGENT" "$DOWNLOAD_URL" -o "$JAR_FILE"
    if [ $? -ne 0 ]; then
        log "Error: Failed to download $JAR_NAME"
        exit 1
    fi
    log "Download complete"
fi

# Update symlink if JAR changed
if [ "$JAR_NAME" = "$CURRENT_VERSION" ]; then
    log "Currently running version is up to date"
else
    log "Updating symlink: $LINK_NAME → $JAR_NAME"
    ln -sfn "$JAR_FILE" "$LINK_NAME"
    "$MC_CTL_CMD" restart
fi

log "===== Paper update completed ====="
