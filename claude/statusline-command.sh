#!/bin/sh
input=$(cat)
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

if [ -z "$used" ]; then
  used=0
fi

# Build a 20-character progress bar
total=20
filled=$(printf "%.0f" "$(echo "$used * $total / 100" | bc -l)")
empty=$((total - filled))

bar=""
i=0
while [ $i -lt "$filled" ]; do
  bar="${bar}█"
  i=$((i + 1))
done
i=0
while [ $i -lt "$empty" ]; do
  bar="${bar}░"
  i=$((i + 1))
done

printf "context: [%s] %.0f%%" "$bar" "$used"

# --- git segment ---
# Show the current branch (or short SHA when detached), with a '*' when the
# working tree is dirty. Uses the workspace dir from the status-line JSON so it
# reflects the project Claude is operating in, not this script's cwd.
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$dir" ] && dir=$(pwd)
branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null \
  || git -C "$dir" rev-parse --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  dirty=""
  [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && dirty="*"
  # \356\202\240 is U+E0A0 (nerd-font branch glyph, matches starship). Kept as an
  # octal escape because editors/tools tend to strip the raw PUA character.
  printf ' \033[35m\356\202\240 %s%s\033[0m' "$branch" "$dirty"
fi

# --- AWS ephemeral-creds segment ---
# Reads the vars set by the aws-ephemeral / aws-ro fish functions, inherited
# from the shell Claude Code was launched in. Colour: red=write, green=read,
# yellow=unknown. Shows a best-effort TTL from AWS_CREDENTIAL_EXPIRATION.
if [ -n "$AWS_EPHEMERAL_INFO" ]; then
  case "$AWS_EPHEMERAL_CAP" in
    write) c=31 ;;
    read)  c=32 ;;
    *)     c=33 ;;
  esac
  ttl=""
  if [ -n "$AWS_CREDENTIAL_EXPIRATION" ]; then
    # normalise Z / +HH:MM offsets to the +HHMM that BSD date wants
    norm=$(printf '%s' "$AWS_CREDENTIAL_EXPIRATION" | sed -E 's/Z$/+0000/; s/([+-][0-9]{2}):([0-9]{2})$/\1\2/')
    exp_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$norm" +%s 2>/dev/null)
    if [ -n "$exp_epoch" ]; then
      left=$(( exp_epoch - $(date +%s) ))
      if [ "$left" -gt 0 ]; then
        ttl=$(printf ' %dh%02dm' $((left / 3600)) $(((left % 3600) / 60)))
      else
        ttl=' expired'
      fi
    fi
  fi
  printf ' \033[1;%sm☁️ %s%s\033[0m' "$c" "$AWS_EPHEMERAL_INFO" "$ttl"
fi
