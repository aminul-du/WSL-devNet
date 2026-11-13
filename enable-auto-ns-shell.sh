#!/usr/bin/env bash
set -e

HOOK_START="# >>> WSL-devNet Auto-Namespace Entry >>>"
HOOK_END="# <<< WSL-devNet Auto-Namespace Entry <<<"

read -r -d '' SNIPPET << 'INNER' || true
# >>> WSL-devNet Auto-Namespace Entry >>>
if [[ $- == *i* ]] && [ -z "$MCORE_NO_NS" ]; then
    CURRENT_NS=$(ip netns identify $$ 2>/dev/null || true)
    if [ "$CURRENT_NS" != "mcore-ns" ]; then
        if ! ip netns list 2>/dev/null | grep -qw "mcore-ns"; then
            sudo /usr/local/bin/mcore-fix.sh >/dev/null 2>&1 || true
        fi
        if ip netns list 2>/dev/null | grep -qw "mcore-ns"; then
            exec sudo ip netns exec mcore-ns su - "$USER"
        fi
    fi
fi
# <<< WSL-devNet Auto-Namespace Entry <<<
INNER

for RC_FILE in "/root/.bashrc" "$HOME/.bashrc"; do
    if [ -f "$RC_FILE" ]; then
        sed -i "/$HOOK_START/,/$HOOK_END/d" "$RC_FILE"
        printf "\n%s\n" "$SNIPPET" >> "$RC_FILE"
    fi
done

echo "✅ Auto-entry into mcore-ns (172.23.180.161) enabled on terminal launch!"
