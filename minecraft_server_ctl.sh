#!/bin/bash
############### Configuration ###############
## Change these variables as needed to match your setup ##
MC_DIR="/usr/games/minecraft" 	# path to minecraft server files on your system
MC_JAR="$MC_DIR/paperMC" 	    # name of minecraft server link
MEMORY="4096M"        		    # adjust RAM available to java to match your Pi 

## You can change these, but that might impact functionality of other scripts
RUNNING_VERSION_FILE="$MC_DIR/.currentversion" # file that stores current running version of paper
STOP_FILE="$MC_DIR/.stopflag"  	# File to indicate manual stop
LOG_FILE="$MC_DIR/mc_service.log" # Log file for output
CRASH_RESTART_DELAY=5        # Delay before restarting after crash (in seconds)
############ End of Configuration #############

cd "$MC_DIR" || { echo "$(date '+%Y-%m-%d %H:%M:%S') Minecraft directory not found!"; exit 1; }

# Function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# function to check if server is running
get_status() {
    if pgrep -f "$MC_JAR" > /dev/null; then
        return 0  # server is running
    else
        return 1 # sever service not found
    fi
}

# Function to check the current version of paperMC that is going to use
get_version() {
    TARGET_INFO=$(readlink "$MC_JAR")
    if [ -z "$TARGET_INFO" ]; then
        log "No link found for $MC_JAR"
        exit 1
    fi
    echo "$TARGET_INFO" > "$RUNNING_VERSION_FILE"
    log "Current paper exec version is $TARGET_INFO"
}

# Function to start the server
start_server() {
    if get_status; then
        log "Minecraft server already running!"
        return
    else
        # sever isn't running but there's a stop file, its probably left over from a hard shutdown, so remove it
        if [ -f "$STOP_FILE" ]; then
            log "Removing stale stop file."
            rm -f "$STOP_FILE"
        fi
    fi

    log "Starting Minecraft server..."

    # Run in background and restart if it crashes
    (
        while true; do
            get_version
            java -Xmx$MEMORY -Xms$MEMORY -jar "$MC_JAR" nogui 2>&1 | while IFS= read -r line; do log "$line"; done
            if [ -f "$STOP_FILE" ]; then
                log "Manual stop detected. Exiting restart loop."
                # Remove the stop file to allow future starts
                rm -f "$STOP_FILE"
                break
            fi
            log "Server crashed or exited unexpectedly. Restarting in $CRASH_RESTART_DELAY seconds..."
            sleep $((CRASH_RESTART_DELAY))
        done
    ) &
    log "Minecraft server started in background."
}

# Function to stop the server
stop_server() {
    if get_status; then
        log "Stopping Minecraft server..."
        touch "$STOP_FILE"  # prevent auto-restart
        pkill -f "$MC_JAR"
        sleep $((CRASH_RESTART_DELAY + 2))  # wait for server to stop and skip out on restart attempt
        log "Server stopped."
    else
        log "Minecraft server is not running."
    fi
}

# Function to check server status
status_server() {
    if get_status; then
        echo "Minecraft server is running."
    else
        echo "Minecraft server is not running."
    fi
}

# ----------------------------
# Handle command-line arguments
# ----------------------------
case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        rm -f "$STOP_FILE"
        start_server
        ;;
    status)
        status_server
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
