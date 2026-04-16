#!/usr/bin/env bash
# Toggle Claude Code for this repo: native Claude subscription vs OpenRouter free-only.
# Claude Code cannot mix both in one session; switch when your Pro session window is exhausted.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRESET="$ROOT/.claude/presets/openrouter-free-only.json"
ACTIVE="$ROOT/.claude/settings.local.json"
STORE="$ROOT/.claude/.openrouter-settings.json"

usage() {
  echo "usage: $(basename "$0") pro | free" >&2
  echo "  pro  — remove project override; use Claude subscription (Sonnet/Opus via Pro)." >&2
  echo "  free — apply OpenRouter; opus/sonnet/haiku all map to the free model (no Claude via OR)." >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

case "$1" in
pro)
  if [[ -f "$ACTIVE" ]] && grep -q 'openrouter\.ai/api' "$ACTIVE" 2>/dev/null; then
    cp "$ACTIVE" "$STORE"
  fi
  rm -f "$ACTIVE"
  echo "OK: subscription mode for this repo (no project OpenRouter). Restart Claude Code if it is already open."
  ;;
free)
  if [[ ! -f "$STORE" ]]; then
    cp "$PRESET" "$STORE"
    echo "Created $STORE — put your OpenRouter key in ANTHROPIC_AUTH_TOKEN, then run: $0 free"
  fi
  cp "$STORE" "$ACTIVE"
  echo "OK: OpenRouter free-only mode. Restart Claude Code; run /logout if auth looks wrong, then /status."
  ;;
*)
  usage
  ;;
esac
