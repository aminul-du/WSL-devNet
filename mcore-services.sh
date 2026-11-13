#!/usr/bin/env bash
set -e

mkdir -p /var/log/mcore

# 1. Stop any old instances before restarting
pkill -f "mcore-rust-engine" 2>/dev/null || true
pkill -f "eduverse" 2>/dev/null || true

# 2. Start Rust Engine inside mcore-ns (Update binary path / command as needed)
# Example: nohup ip netns exec mcore-ns /srv/mcore/target/release/mcore-engine --bind 0.0.0.0:8080 > /var/log/mcore/rust-engine.log 2>&1 &

# 3. Start EduVerse App inside mcore-ns (Update start command as needed)
# Example: nohup ip netns exec mcore-ns bash -c "cd /srv/mcore/eduverse && npm run start" > /var/log/mcore/eduverse.log 2>&1 &

echo "✅ MCORE services hook executed inside mcore-ns"
