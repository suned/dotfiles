#!/bin/sh
input=$(cat)
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

if [ -z "$used" ]; then
  exit 0
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
