#!/bin/bash
# collect.sh - takes one sample of the project's sources and saves it as
# raw/YYYY-mm-dd/HHMM.json (UTC), as defined in the project contract.
# Run from the project root, no arguments. Exits 0 on success.
set -e -u -o pipefail

# --- settings ---
HN_API="https://hacker-news.firebaseio.com/v0"
FINNHUB_API="https://finnhub.io/api/v1"
KEY_FILE="$HOME/.finnhub_key"
TICKERS_FILE="tickers.csv"
TOP_N=30
BASELINES="QQQ IWM"
CURL="curl -sS --fail --max-time 20 --retry 2"

# --- time and target path (one moment, UTC) ---
now=$(date -u +%s)
sample_date=$(date -u -d @"$now" +%F)
sample_time=$(date -u -d @"$now" +%H%M)
sample_iso=$(date -u -d @"$now" +%Y-%m-%dT%H:%M:%SZ)
raw_folder="raw/$sample_date"
raw_file="$raw_folder/$sample_time.json"

# Never overwrite an existing sample (raw/ is append-only)
if [ -e "$raw_file" ]; then
    echo "collect.sh: $raw_file already exists, not overwriting" >&2
    exit 1
fi

# --- temporary workspace (inside the project, so the final mv is atomic) ---
tmp=$(mktemp -d "./.collect.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# --- HN: front page and details of the top posts ---
$CURL "$HN_API/topstories.json" > "$tmp/hn_top.json"
for id in $(jq -r ".[:$TOP_N][]" "$tmp/hn_top.json"); do
    $CURL "$HN_API/item/$id.json"
    echo
done > "$tmp/hn_items.jsonl"

# --- find companies: post domain matches a table domain, or ends with "." + it ---
jq -r '.url // empty' "$tmp/hn_items.jsonl" | cut -d/ -f3 > "$tmp/domains.txt"
awk -F, '
    NR == FNR { gsub(/\r/, ""); if (FNR > 1) map[tolower($1)] = $2; next }
    {
        d = tolower($0)
        for (k in map)
            if (d == k || substr(d, length(d) - length(k)) == "." k) print map[k]
    }' "$TICKERS_FILE" "$tmp/domains.txt" > "$tmp/matched.txt"
tickers=$( { echo "$BASELINES" | tr ' ' '\n'; cat "$tmp/matched.txt"; } | sort -u)

# --- stock quotes ---
key=$(cat "$KEY_FILE")
for s in $tickers; do
    $CURL "$FINNHUB_API/quote?symbol=$s&token=$key" | jq -c --arg s "$s" '{symbol: $s} + .'
done > "$tmp/quotes.jsonl"

# --- combine everything into one file ---
jq -n \
    --arg sample_time "$sample_iso" \
    --slurpfile hn_top "$tmp/hn_top.json" \
    --slurpfile hn_items "$tmp/hn_items.jsonl" \
    --slurpfile quotes "$tmp/quotes.jsonl" \
    '{sample_time: $sample_time, hn_top: $hn_top[0], hn_items: $hn_items, quotes: $quotes}' \
    > "$tmp/sample.json"

# --- validate: valid JSON, all posts present, every quote has a price ---
jq -e --argjson n "$TOP_N" \
    '(.hn_items | length) == $n and (.quotes | length) > 0 and all(.quotes[]; .c != null and .c != 0)' \
    "$tmp/sample.json" > /dev/null

# --- only now, move the complete file into raw/ ---
mkdir -p "$raw_folder"
mv "$tmp/sample.json" "$raw_file"
echo "collect.sh: saved $raw_file"
