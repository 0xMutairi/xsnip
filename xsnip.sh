#!/usr/bin/env bash
# ================================================================
#  XSnip v3
# Author: 0xMutairi (Duaij Al‑Mutairi)
# URL   : https://github.com/0xMutairi/xsnip
# ================================================================
# A hyper‑parallel recon pipeline for serious bounty hunters.
# ================================================================

set -Eeuo pipefail
shopt -s lastpipe
IFS=$'\n\t'

VERSION="3.0.0"
SCRIPT_URL="https://raw.githubusercontent.com/0xMutairi/xsnip/main/xsnip.sh"

# ----------  ANSI  ---------- #
cR="\e[31m"; cG="\e[32m"; cY="\e[33m"; cC="\e[36m"; c0='\e[0m'
log(){ printf "${cC}[%s]${c0} %s\n" "$(date +%H:%M:%S)" "$*" >&2; }
success(){ printf "${cG}[\u2714]${c0} %s\n" "$*" >&2; }
warn(){ printf "${cY}[!]${c0} %s\n" "$*" >&2; }
fail(){ printf "${cR}[\u2718]${c0} %s\n" "$*" >&2; exit 1; }

usage(){ cat <<EOF
Usage: $(basename "$0") <target.com> [options]

Options:
  -c, --config <file>   Custom YAML config (default: xsnip.yml)
  -o, --outdir <dir>    Output directory (default: xsnip-<target>-<ts>)
  --fast                Run in fast mode (skip heavy modules like amass, katana, gowitness)
  --update              Pull latest version from GitHub & exit
  -h, --help            This help.
EOF
exit 0; }

[[ $# -eq 0 ]] && usage

# ----------  Self‑update  ---------- #
if [[ "$1" == "--update" || "$1" == "-u" ]]; then
  curl -fsSL "$SCRIPT_URL" -o "$0.new" && chmod +x "$0.new" && mv "$0.new" "$0"
  success "Updated to latest version."
  exit 0
fi

# ----------  Parse args  ---------- #
TARGET=""
OUTDIR=""
CONF="xsnip.yml"
FAST_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config) CONF="$2"; shift 2;;
    -o|--outdir) OUTDIR="$2"; shift 2;;
    --fast) FAST_MODE=true; shift;;
    -h|--help) usage;;
    *) TARGET="$1"; shift;;
  esac
done

[[ -z "$TARGET" ]] && fail "No target supplied."
TIMESTAMP="$(date +%s)"
OUTDIR="${OUTDIR:-xsnip-$TARGET-$TIMESTAMP}"
mkdir -p "$OUTDIR" && cd "$OUTDIR"

export PARALLEL_SHELL=/bin/bash
export OG_DIR="$PWD"

log "🎯 Target: $TARGET"

# ----------  Dependency check  ---------- #
need_cmd(){ command -v "$1" &>/dev/null || fail "Dependency missing: $1"; }
for bin in subfinder dnsx httpx nuclei git-hound gf jq parallel gau naabu; do need_cmd "$bin"; done
for sbin in gowitness amass katana trufflehog3 favup asnmap waymore; do command -v "$sbin" &>/dev/null || warn "$sbin not installed (optional)."; done

# ----------  Config vars  ---------- #
SLACK_URL=${SLACK_URL:-}
THREADS=${THREADS:-50}
PORTS="80,443,8080,8443,3000,8000,9000"
NUCLEI_SEV="critical,high,medium"
NUCLEI_TAGS="ssrf,s3,token,redirect,misconfig,debug,exposure,auth"

if command -v yq &>/dev/null && [[ -f ../$CONF ]]; then
  eval $(yq -o=env ../$CONF)
fi

log "🔎 Subdomain enumeration…"
if $FAST_MODE; then
  subfinder -silent -d "$TARGET"
else
  {
    subfinder -silent -d "$TARGET" &
    command -v amass &>/dev/null && amass enum -passive -d "$TARGET" -silent &
    wait
  }
fi | sort -u | tee subs_all.txt | dnsx -silent -a -resp-only | sort -u > resolved.txt
success "Subdomains resolved: $(wc -l < resolved.txt)"

log "🌐 Probing live hosts with httpx…"
httpx -silent -l resolved.txt -ports "$PORTS" -threads "$THREADS" -title -tech-detect -status-code -json | tee httpx.json | jq -r '.url' > live.txt
success "Live hosts: $(wc -l < live.txt)"

log "⏳ Mining Wayback + Gau + Waymore…"
{
  gau --threads "$THREADS" "$TARGET" 2>/dev/null
  curl -s "http://web.archive.org/cdx/search/cdx?url=*.$TARGET&output=text&fl=original&collapse=urlkey&limit=200000"
  $FAST_MODE || (command -v waymore &>/dev/null && waymore -d "$TARGET" -mode U | grep -vE "^#")
} | grep -vE "\\.(png|jpg|gif|svg|css|ico|woff)($|\\?)" | sort -u > wayback_urls.txt

log "📜 Extracting endpoints from JS & crawler…"
grep -Ei "\\.js($|\\?)" wayback_urls.txt | sort -u > js_urls.txt

parallel -j "$THREADS" --halt soon,fail=1 'timeout 10 curl -sL {} | \
  python3 - <<PY
import sys, re
content = sys.stdin.read()
regex = re.compile(r"[a-zA-Z0-9_/\\.-]+\\.(?:php|aspx|jsp|json|action|do|cgi|pl|py)")
for m in regex.findall(content):
    print(m)
PY' :::: js_urls.txt 2>/dev/null | sort -u > endpoints.txt

if ! $FAST_MODE && command -v katana &>/dev/null; then
  katana -silent -list live.txt -o katana.txt -jc -jc-iters 2
  cat katana.txt >> endpoints.txt
fi
sort -u endpoints.txt -o endpoints.txt
success "Endpoints collected: $(wc -l < endpoints.txt)"

log "🔑 Scanning GitHub & public repos for secrets…"
printf "%s\n" "$TARGET" | git-hound --dig-files --filtered-only > git_leaks.txt || true
command -v trufflehog3 &>/dev/null && [[ -n "${GITHUB_TOKEN:-}" ]] && trufflehog3 github --repo "$TARGET" --json > truffle.json || true

log "🖐 Running GF patterns…"
PATTERNS=(ssrf s3-buckets redirect interestingEXT idor rce xss debug_logic)
> gf_matches.txt
for p in "${PATTERNS[@]}"; do
  gf "$p" < endpoints.txt | anew -q gf_matches.txt || true
done

log "🚀 Launching nuclei…"
nuclei -silent -l endpoints.txt -tags "$NUCLEI_TAGS" -severity "$NUCLEI_SEV" -o nuclei.txt || true

if ! $FAST_MODE && command -v gowitness &>/dev/null; then
  log "📸 Capturing screenshots…"
  gowitness file -f live.txt --threads "$THREADS" --timeout 10 --disable-logging >/dev/null || warn "GoWitness failed"
fi

command -v favup &>/dev/null && favup -l live.txt -o favhashes.txt

log "🗒️ Building report…"
{
  echo "# XSnip v3 Report – $TARGET"
  echo "Generated: $(date -Iseconds)"
  echo
  echo "## 📊 Summary"
  echo "- Subdomains: $(wc -l < resolved.txt)"
  echo "- Live hosts: $(wc -l < live.txt)"
  echo "- Endpoints: $(wc -l < endpoints.txt)"
  echo "- Nuclei findings: $(wc -l < nuclei.txt)"
  echo
  echo "## 🔥 Critical / High (Nuclei)"; echo '```'; grep -Ei "\[critical\]|\[high\]" nuclei.txt || echo "None"; echo '```'
  echo "## ✅ Subdomains"; echo '```'; cat resolved.txt; echo '```'
  echo "## 🌐 Live Hosts"; echo '```'; cat live.txt; echo '```'
  echo "## 🗂️ Interesting Endpoints"; echo '```'; cat endpoints.txt; echo '```'
} > report.md

if [[ -n "$SLACK_URL" ]] && [[ -s nuclei.txt ]]; then
  CRIT=$(grep -c "\[critical\]" nuclei.txt || true)
  if [[ $CRIT -gt 0 ]]; then
    jq -nc --arg text "*XSnip:* $TARGET – $CRIT critical findings" '{text:$text}' | \
      curl -s -X POST -H 'Content-type: application/json' --data @- "$SLACK_URL" >/dev/null && \
      success "Slack webhook sent ($CRIT critical)"
  fi
fi

success "Recon completed. Report saved to $OUTDIR/report.md"
