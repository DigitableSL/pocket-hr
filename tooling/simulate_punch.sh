#!/usr/bin/env bash
# Simulate single or parallel load-test attendance Check-In / Check-Out (QR, Remote, or Mixed)
# matching DT-PocketHR's exact API contract.
#
# Single-punch examples:
#   export POCKET_HR_TOKEN="<your-bearer-jwt>"
#   ./tooling/simulate_punch.sh --type checkin --mode qr --accuracy 6.5 --distance 8.2
#   ./tooling/simulate_punch.sh --type checkout --mode remote --accuracy 12.0
#
# Load-test example (1,000 check-outs spread across 15 minutes = 900s, 25 concurrent workers):
#   ./tooling/simulate_punch.sh --type checkout --mode mixed \
#     --count 1000 --concurrency 25 --spread-seconds 900
#
# Multi-user load test (optional tokens file, one JWT per line):
#   ./tooling/simulate_punch.sh --type checkout --mode qr \
#     --count 1000 --concurrency 30 --spread-seconds 900 --tokens-file ./test_tokens.txt

set -euo pipefail

BASE_URL="${POCKET_HR_BASE_URL:-https://api.human.go.digitable.io/human/v2/api}"
TENANT="${POCKET_HR_TENANT:-domex}"
TOKEN="${POCKET_HR_TOKEN:-}"
UID_VAL="${POCKET_HR_USER_ID:-}"
TOKENS_FILE=""

PUNCH_TYPE="checkin"      # checkin | checkout | mixed
PUNCH_MODE="qr"           # qr | remote | mixed
LAT="6.9271"
LNG="79.8612"
ADDRESS="Colombo, Sri Lanka"
ACCURACY="8.50"
DISTANCE="12.40"
PLATFORM="android"        # android | iphone | mixed
APP_VERSION="1.2.4+32"
PUNCH_TIME=""

COUNT=1
CONCURRENCY=20
SPREAD_SECONDS=0
TIMEOUT_SECONDS=15
DRY_RUN="false"
AUTO_YES="false"

usage() {
  cat <<EOF
Usage: POCKET_HR_TOKEN="<jwt>" $0 [options]

Single / Base Options:
  --type <checkin|checkout|mixed>   Punch type (default: checkin)
  --mode <qr|remote|mixed>          Punch mode (default: qr; remote omits distance)
  --tenant <slug>                   Tenant slug (default: \$POCKET_HR_TENANT or domex)
  --uid <user_id>                   User ID (auto-extracted from JWT if omitted)
  --time <ISO-8601>                 Fixed punch timestamp (default: live UTC time per punch)
  --lat <float>                     Base latitude (default: 6.9271)
  --lng <float>                     Base longitude (default: 79.8612)
  --address <text>                  Address string (default: "Colombo, Sri Lanka")
  --accuracy <meters>               Base GPS accuracy in meters (default: 8.50)
  --distance <meters>               Base QR distance in meters (default: 12.40; omitted on remote)
  --platform <android|iphone|mixed> X-Platform header (default: android)
  --version <x.y.z+b>               X-App-Version header (default: 1.2.4+32)

Load / Burst Simulation Options:
  --count <N>                       Total punches to simulate (default: 1; e.g. 1000)
  --concurrency <C>                 Max parallel in-flight requests (default: 20)
  --spread-seconds <S>              Spread punches randomly over S seconds (e.g. 900 = 15 min)
  --tokens-file <path>              Optional file with 1 Bearer JWT per line (multi-user load)
  --timeout <sec>                   Per-request curl timeout in seconds (default: 15)
  --yes                             Skip 3-second confirmation pause for load tests
  --dry-run                         Simulate without sending HTTP requests
  -h, --help                        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)           PUNCH_TYPE="$2"; shift 2 ;;
    --mode)           PUNCH_MODE="$2"; shift 2 ;;
    --tenant)         TENANT="$2"; shift 2 ;;
    --uid)            UID_VAL="$2"; shift 2 ;;
    --time)           PUNCH_TIME="$2"; shift 2 ;;
    --lat)            LAT="$2"; shift 2 ;;
    --lng)            LNG="$2"; shift 2 ;;
    --address)        ADDRESS="$2"; shift 2 ;;
    --accuracy)       ACCURACY="$2"; shift 2 ;;
    --distance)       DISTANCE="$2"; shift 2 ;;
    --platform)       PLATFORM="$2"; shift 2 ;;
    --version)        APP_VERSION="$2"; shift 2 ;;
    --count)          COUNT="$2"; shift 2 ;;
    --concurrency)    CONCURRENCY="$2"; shift 2 ;;
    --spread-seconds) SPREAD_SECONDS="$2"; shift 2 ;;
    --tokens-file)    TOKENS_FILE="$2"; shift 2 ;;
    --timeout)        TIMEOUT_SECONDS="$2"; shift 2 ;;
    --yes)            AUTO_YES="true"; shift ;;
    --dry-run)        DRY_RUN="true"; shift ;;
    -h|--help)        usage; exit 0 ;;
    *)                echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$TOKEN" && -z "$TOKENS_FILE" && "$DRY_RUN" != "true" ]]; then
  echo "Error: set POCKET_HR_TOKEN or --tokens-file (or use --dry-run)." >&2
  exit 2
fi

if [[ -n "$TOKENS_FILE" && ! -f "$TOKENS_FILE" ]]; then
  echo "Error: tokens file not found: $TOKENS_FILE" >&2
  exit 2
fi

if [[ "$PUNCH_TYPE" != "checkin" && "$PUNCH_TYPE" != "checkout" && "$PUNCH_TYPE" != "mixed" ]]; then
  echo "Error: --type must be 'checkin', 'checkout', or 'mixed'." >&2
  exit 2
fi

if [[ "$PUNCH_MODE" != "qr" && "$PUNCH_MODE" != "remote" && "$PUNCH_MODE" != "mixed" ]]; then
  echo "Error: --mode must be 'qr', 'remote', or 'mixed'." >&2
  exit 2
fi

# Load token pool
TOKENS=()
if [[ -n "$TOKENS_FILE" ]]; then
  while IFS= read -r line; do
    trimmed="$(echo "$line" | tr -d '[:space:]')"
    [[ -n "$trimmed" && "$trimmed" != \#* ]] && TOKENS+=("$trimmed")
  done < "$TOKENS_FILE"
fi
if [[ ${#TOKENS[@]} -eq 0 && -n "$TOKEN" ]]; then
  TOKENS+=("$TOKEN")
fi
if [[ ${#TOKENS[@]} -eq 0 ]]; then
  TOKENS+=("")
fi

extract_uid_from_jwt() {
  local tok="$1"
  if [[ -z "$tok" ]]; then
    echo ""
    return
  fi
  python3 -c '
import base64, json, sys
tok = sys.argv[1]
parts = tok.split(".")
if len(parts) >= 2:
    pad = parts[1] + "=" * (-len(parts[1]) % 4)
    p = json.loads(base64.urlsafe_b64decode(pad))
    print(p.get("user_id") or p.get("userId") or p.get("sub") or p.get("id") or "")
' "$tok" 2>/dev/null || true
}

# Pre-compute UIDs for each token in pool
UIDS=()
for tok in "${TOKENS[@]}"; do
  if [[ -n "$UID_VAL" && ${#TOKENS[@]} -eq 1 ]]; then
    UIDS+=("$UID_VAL")
  else
    u="$(extract_uid_from_jwt "$tok")"
    UIDS+=("${u:-${UID_VAL:-test-user-id}}")
  fi
done

# ── Single-punch mode (verbose output) ───────────────────────────────────────
if [[ "$COUNT" -eq 1 ]]; then
  eff_type="$PUNCH_TYPE"
  [[ "$eff_type" == "mixed" ]] && eff_type="checkin"
  eff_mode="$PUNCH_MODE"
  [[ "$eff_mode" == "mixed" ]] && eff_mode="qr"
  eff_plat="$PLATFORM"
  [[ "$eff_plat" == "mixed" ]] && eff_plat="android"

  now_utc=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  ts="${PUNCH_TIME:-$now_utc}"
  if [[ "$eff_type" == "checkout" ]]; then
    endpoint="${BASE_URL}/attendance/check-out"
    time_key="checkout_at"
  else
    endpoint="${BASE_URL}/attendance/check-in"
    time_key="checked_at"
  fi
  is_remote="false"
  [[ "$eff_mode" == "remote" ]] && is_remote="true"

  echo "=== Simulate Attendance Punch ==="
  echo "Endpoint:  POST ${endpoint}"
  echo "Mode:      ${eff_mode} (remote=${is_remote})"
  echo "User ID:   ${UIDS[0]}"
  echo "Time:      ${ts}"
  echo "Coords:    ${LAT}, ${LNG} (accuracy=${ACCURACY}m)"
  if [[ "$is_remote" == "false" ]]; then
    echo "Distance:  ${DISTANCE}m"
  else
    echo "Distance:  <omitted for remote>"
  fi
  echo "Headers:   X-App-Version=${APP_VERSION}, X-Platform=${eff_plat}, Tenant=${TENANT}"
  echo "---------------------------------"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Request not sent."
    exit 0
  fi

  curl_args=(
    -sS -i --max-time "$TIMEOUT_SECONDS" -X POST "$endpoint"
    -H "Accept: application/json"
    -H "Content-Type: application/x-www-form-urlencoded"
    -H "Authorization: Bearer ${TOKENS[0]}"
    -H "Tenant: ${TENANT}"
    -H "Device-Time: ${now_utc}"
    -H "X-App-Version: ${APP_VERSION}"
    -H "X-Platform: ${eff_plat}"
    -H "device-id: sim-device-001"
    -H "device-identifier: sim-device-001"
    -H "device-model: Simulator"
    -H "device-brand: CLI"
    -H "device-platform: ${eff_plat}"
    -H "device-version: 15"
    -H "battery-level: 85"
    --data-urlencode "uid=${UIDS[0]}"
    --data-urlencode "user-id=${UIDS[0]}"
    --data-urlencode "${time_key}=${ts}"
    --data-urlencode "remote=${is_remote}"
    --data-urlencode "lat=${LAT}"
    --data-urlencode "lng=${LNG}"
    --data-urlencode "address=${ADDRESS}"
    --data-urlencode "location_accuracy=${ACCURACY}"
    --data-urlencode "tenant=${TENANT}"
    --data-urlencode "device_id=sim-device-001"
    --data-urlencode "device_identifier=sim-device-001"
    --data-urlencode "device_model=Simulator"
    --data-urlencode "device_brand=CLI"
    --data-urlencode "device_platform=${eff_plat}"
    --data-urlencode "device_version=15"
    --data-urlencode "battery_level=85"
  )
  if [[ "$is_remote" == "false" && -n "$DISTANCE" ]]; then
    curl_args+=(--data-urlencode "distance=${DISTANCE}")
  fi

  curl "${curl_args[@]}"
  echo ""
  exit 0
fi

# ── Parallel Load / Spike Simulation Mode (COUNT > 1) ────────────────────────
echo "=== Parallel Attendance Load Simulation ==="
echo "Target:       ${BASE_URL}"
echo "Tenant:       ${TENANT}"
echo "Requests:     ${COUNT} (concurrency=${CONCURRENCY}, spread=${SPREAD_SECONDS}s)"
echo "Type / Mode:  ${PUNCH_TYPE} / ${PUNCH_MODE} (platform=${PLATFORM})"
echo "Token Pool:   ${#TOKENS[@]} user token(s)"
echo "Dry Run:      ${DRY_RUN}"
echo "==========================================="

if [[ "$DRY_RUN" != "true" && "$AUTO_YES" != "true" ]]; then
  echo "Starting in 3 seconds... (Press Ctrl+C to cancel)"
  sleep 3
fi

RESULTS_FILE=$(mktemp /tmp/pocket_hr_load_XXXXXX.csv)
trap 'rm -f "$RESULTS_FILE"' EXIT
echo "seq,type,mode,platform,status,latency_ms" > "$RESULTS_FILE"

START_EPOCH=$(python3 -c 'import time; print(time.time())')

run_one_punch() {
  local idx="$1"

  local pool_size=${#TOKENS[@]}
  local t_idx=$(( (idx - 1) % pool_size ))
  local tok="${TOKENS[$t_idx]}"
  local uid="${UIDS[$t_idx]}"

  local eff_type="$PUNCH_TYPE"
  if [[ "$eff_type" == "mixed" ]]; then
    if (( idx % 2 == 0 )); then eff_type="checkout"; else eff_type="checkin"; fi
  fi

  local eff_mode="$PUNCH_MODE"
  if [[ "$eff_mode" == "mixed" ]]; then
    # ~70% QR, ~30% Remote
    if (( idx % 10 < 3 )); then eff_mode="remote"; else eff_mode="qr"; fi
  fi

  local eff_plat="$PLATFORM"
  if [[ "$eff_plat" == "mixed" ]]; then
    if (( idx % 3 == 0 )); then eff_plat="iphone"; else eff_plat="android"; fi
  fi

  local is_remote="false"
  [[ "$eff_mode" == "remote" ]] && is_remote="true"

  local endpoint="${BASE_URL}/attendance/check-in"
  local time_key="checked_at"
  if [[ "$eff_type" == "checkout" ]]; then
    endpoint="${BASE_URL}/attendance/check-out"
    time_key="checkout_at"
  fi

  # Slight deterministic jitter for realistic load data
  local acc_jitter=$(( 5 + (idx * 7) % 18 ))
  local dist_jitter=$(( 2 + (idx * 11) % 35 ))
  local dev_id
  dev_id=$(printf "sim-device-%04d" "$idx")
  local now_utc
  now_utc=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  local ts="${PUNCH_TIME:-$now_utc}"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "${idx},${eff_type},${eff_mode},${eff_plat},200,0.0" >> "$RESULTS_FILE"
    return 0
  fi

  local curl_args=(
    -sS -o /dev/null --max-time "$TIMEOUT_SECONDS"
    -w "%{http_code},%{time_total}"
    -X POST "$endpoint"
    -H "Accept: application/json"
    -H "Content-Type: application/x-www-form-urlencoded"
    -H "Authorization: Bearer ${tok}"
    -H "Tenant: ${TENANT}"
    -H "Device-Time: ${now_utc}"
    -H "X-App-Version: ${APP_VERSION}"
    -H "X-Platform: ${eff_plat}"
    -H "device-id: ${dev_id}"
    -H "device-identifier: ${dev_id}"
    -H "device-model: Simulator"
    -H "device-brand: CLI"
    -H "device-platform: ${eff_plat}"
    -H "device-version: 15"
    -H "battery-level: 85"
    --data-urlencode "uid=${uid}"
    --data-urlencode "user-id=${uid}"
    --data-urlencode "${time_key}=${ts}"
    --data-urlencode "remote=${is_remote}"
    --data-urlencode "lat=${LAT}"
    --data-urlencode "lng=${LNG}"
    --data-urlencode "address=${ADDRESS}"
    --data-urlencode "location_accuracy=${acc_jitter}.00"
    --data-urlencode "tenant=${TENANT}"
    --data-urlencode "device_id=${dev_id}"
    --data-urlencode "device_identifier=${dev_id}"
    --data-urlencode "device_model=Simulator"
    --data-urlencode "device_brand=CLI"
    --data-urlencode "device_platform=${eff_plat}"
    --data-urlencode "device_version=15"
    --data-urlencode "battery_level=85"
  )
  if [[ "$is_remote" == "false" ]]; then
    curl_args+=(--data-urlencode "distance=${dist_jitter}.00")
  fi

  local out
  out=$(curl "${curl_args[@]}" 2>/dev/null || echo "000,0")
  local code="${out%%,*}"
  local sec="${out##*,}"
  local ms
  ms=$(python3 -c "print(f'{float(\"${sec:-0}\")*1000:.1f}')" 2>/dev/null || echo "0.0")
  echo "${idx},${eff_type},${eff_mode},${eff_plat},${code},${ms}" >> "$RESULTS_FILE"
}

# Launch up to CONCURRENCY workers in parallel, paced across SPREAD_SECONDS
ACTIVE=0
for (( i = 1; i <= COUNT; i++ )); do
  if (( SPREAD_SECONDS > 0 )) && [[ "$DRY_RUN" != "true" ]]; then
    # Pace arrivals so COUNT requests span ~SPREAD_SECONDS with natural burst jitter
    pace=$(python3 -c "import random; avg=${SPREAD_SECONDS}/${COUNT}; print(f'{random.uniform(0, avg*2):.3f}')")
    sleep "$pace"
  fi

  run_one_punch "$i" &
  ACTIVE=$((ACTIVE + 1))

  if (( ACTIVE >= CONCURRENCY )); then
    wait -n 2>/dev/null || wait
    ACTIVE=0
  fi

  if (( i % 100 == 0 || i == COUNT )); then
    echo "Dispatched ${i}/${COUNT} requests..."
  fi
done

wait

# Print latency percentiles & HTTP status breakdown
python3 - "$RESULTS_FILE" "$START_EPOCH" <<'PY'
import csv, sys, time
from collections import Counter

path, start_ep = sys.argv[1], float(sys.argv[2])
elapsed = max(time.time() - start_ep, 0.001)

rows = list(csv.DictReader(open(path)))
total = len(rows)
statuses = Counter(r["status"] for r in rows)
modes = Counter(r["mode"] for r in rows)
types = Counter(r["type"] for r in rows)
latencies = sorted(float(r["latency_ms"]) for r in rows)
ok = sum(v for k, v in statuses.items() if k.startswith("2"))
failed = total - ok

def pct(arr, p):
    if not arr:
        return 0.0
    idx = min(len(arr) - 1, int(round((p / 100.0) * (len(arr) - 1))))
    return arr[idx]

print("\n=== Load Simulation Summary ===")
print(f"Total requests : {total}")
print(f"Succeeded (2xx): {ok} ({(ok/total*100) if total else 0:.1f}%)")
print(f"Failed         : {failed}")
print(f"Wall time      : {elapsed:.2f}s  ({total/elapsed:.2f} req/s)")
print(f"By type        : {dict(types)}")
print(f"By mode        : {dict(modes)}")
print(f"HTTP statuses  : {dict(sorted(statuses.items()))}")
if latencies:
    print(f"Latency (ms)   : min={latencies[0]:.1f} | avg={sum(latencies)/len(latencies):.1f} | p50={pct(latencies,50):.1f} | p95={pct(latencies,95):.1f} | p99={pct(latencies,99):.1f} | max={latencies[-1]:.1f}")
PY
