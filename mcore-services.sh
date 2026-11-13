#!/usr/bin/env bash
set -e

mkdir -p /var/log/mcore
chown -R mcoreai:mcoreai /var/log/mcore

# Stop any previous Next.js instances cleanly before starting
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "next start" 2>/dev/null || true
sleep 1

start_next_app() {
    local APP_NAME="$1"
    local PORT="$2"
    local APP_DIR="/srv/mcore/apps/${APP_NAME}"
    local LOG_FILE="/var/log/mcore/${APP_NAME}.log"

    if [ ! -d "$APP_DIR" ]; then
        return
    fi

    # Use production 'start' if built (.next/BUILD_ID exists), otherwise fall back to 'dev'
    local MODE="dev"
    if [ -f "${APP_DIR}/.next/BUILD_ID" ]; then
        MODE="start"
    fi

    ip netns exec mcore-ns su - mcoreai -c "
        cd '$APP_DIR'
        nohup pnpm exec next $MODE -H 0.0.0.0 -p $PORT > '$LOG_FILE' 2>&1 &
    "
}

start_next_app "academy-web" 3000
start_next_app "ais-profile" 3001
start_next_app "eduverse"    3002

echo "✅ MCORE apps started inside mcore-ns ($(cat /run/mcore-target-ip 2>/dev/null)) on ports 3000, 3001, 3002"
