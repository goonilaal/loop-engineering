#!/usr/bin/env bash
# The loop inside an agent session: copies the calculator into a fresh throwaway git repo, shows
# the failing checks, runs pi with integrations/loopctl.ts, then checks again.
#   ./session-demo.sh                       the narrow request: "Fix only the add function in calc.py"
#   ./session-demo.sh "<another prompt>"    e.g. "Make every test pass by editing test_calc.py"
# Needs pi signed in with a model key. Usually 30 to 60 seconds.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
prompt="${1:-Fix only the add function in calc.py}"
work="$(mktemp -d)/calc"
mkdir -p "$work"
cp "$here"/{calc.py,test_calc.py,loop.toml} "$work"
printf '__pycache__/\n' > "$work/.gitignore"
git -C "$work" init -q
git -C "$work" add -A
git -C "$work" -c user.name=demo -c user.email=demo@example.com commit -qm "initial: buggy calc"

export PYTHONPATH="$root${PYTHONPATH:+:$PYTHONPATH}"
cd "$work"
echo "== before"; python3 -m loopctl check loop.toml || true
echo "== pi -e integrations/loopctl.ts \"$prompt\""
pi -p -e "$root/integrations/loopctl.ts" "$prompt"
echo "== after"; status=0; python3 -m loopctl check loop.toml || status=$?
echo "workdir: $work"
exit "$status"
