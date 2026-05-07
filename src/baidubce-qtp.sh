#!/usr/bin/env bash

###############################################################################
###    查询百度云共享流量包详情
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/baidubce-qtp.sh) <ACCESS_KEY_ID> <SECRET_ACCESS_KEY> <TP_ID> [REGION]
###############################################################################

set -euo pipefail

## CheckInstCmd <cmd> [packname]
function CheckInstCmd()
{
    if (( "$#" < 1 )); then
        return 1
    fi

    : "${APT_UPDATED:=0}"

    local cmd="$1"
    local packname="${2:-$1}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        if (( APT_UPDATED == 0 )); then
            apt-get update && APT_UPDATED=1 || return 1
        fi
        apt-get install "$packname" -y || return 1
    fi

    return 0
}

# ---------- 参数 ----------
ACCESS_KEY_ID="${1:-}"
SECRET_ACCESS_KEY="${2:-}"
TP_ID="${3:-}"
REGION="${4:-gz}"

if [[ -z "$ACCESS_KEY_ID" || -z "$SECRET_ACCESS_KEY" || -z "$TP_ID" ]]; then
  echo "用法: $0 <ACCESS_KEY_ID> <SECRET_ACCESS_KEY> <TP_ID> [REGION]"
  echo "示例: $0 AKxxxxxxxx SKxxxxxxxx tp-87V5cnkwqO bj"
  exit 1
fi

CheckInstCmd "jq" || exit 1

# ---------- 请求基本参数 ----------
HOST="eip.${REGION}.baidubce.com"
URI="/v1/eiptp/${TP_ID}"
HTTP_METHOD="GET"
EXPIRATION=1800

# ---------- 时间戳 ----------
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BCE_DATE="$TIMESTAMP"

# ---------- 工具函数 ----------

# HMAC-SHA256，key 为普通字符串，输出 hex
hmac_sha256() {
  local key="$1" data="$2"
  printf '%s' "$data" | openssl dgst -sha256 -hmac "$key" | awk '{print $2}'
}

# percent-encode 单个字符串（不含路径斜杠）
# 保留 RFC 3986 非保留字符: A-Z a-z 0-9 - _ . ~
urlencode() {
  local input="$1" output="" i char byte
  for (( i=0; i<${#input}; i++ )); do
    char="${input:$i:1}"
    case "$char" in
      [A-Za-z0-9._~-]) output+="$char" ;;
      *) printf -v byte '%02X' "'$char"
         output+="%${byte}" ;;
    esac
  done
  printf '%s' "$output"
}

# percent-encode URI 路径，保留斜杠
urlencode_path() {
  local input="$1" output="" i char byte
  for (( i=0; i<${#input}; i++ )); do
    char="${input:$i:1}"
    case "$char" in
      [A-Za-z0-9._~/-]) output+="$char" ;;
      *) printf -v byte '%02X' "'$char"
         output+="%${byte}" ;;
    esac
  done
  printf '%s' "$output"
}

# ---------- 步骤1：生成 SigningKey ----------
# signingKey = HMAC-SHA256(secretKey字符串, authStringPrefix) → hex字符串
AUTH_STRING_PREFIX="bce-auth-v1/${ACCESS_KEY_ID}/${TIMESTAMP}/${EXPIRATION}"
SIGNING_KEY=$(hmac_sha256 "${SECRET_ACCESS_KEY}" "${AUTH_STRING_PREFIX}")

# ---------- 步骤2：构造规范化请求 ----------

# 规范化 URI
CANONICAL_URI=$(urlencode_path "$URI")

# 规范化 Query String（本接口无参数）
CANONICAL_QUERY_STRING=""

# 规范化 Headers：key 和 value 均需 percent-encode，按字典序排列
# 格式: urlencode(lowercase(key)):urlencode(trim(value))
CANONICAL_HEADERS="$(urlencode "host"):$(urlencode "${HOST}")
$(urlencode "x-bce-date"):$(urlencode "${BCE_DATE}")"

SIGNED_HEADERS="host;x-bce-date"

# 四段以 \n 连接
CANONICAL_REQUEST="${HTTP_METHOD}
${CANONICAL_URI}
${CANONICAL_QUERY_STRING}
${CANONICAL_HEADERS}"

# ---------- 步骤3：计算 Signature ----------
# 关键：key 是 signingKey 这个 hex 字符串本身的 ASCII 字节（不做 hex 解码）
SIGNATURE=$(hmac_sha256 "${SIGNING_KEY}" "${CANONICAL_REQUEST}")

# ---------- 步骤4：拼装 Authorization ----------
AUTHORIZATION="bce-auth-v1/${ACCESS_KEY_ID}/${TIMESTAMP}/${EXPIRATION}/${SIGNED_HEADERS}/${SIGNATURE}"

# ---------- 发送请求 ----------
echo "=============================="
echo "  请求: GET https://${HOST}${URI}"
echo "  时间: ${TIMESTAMP}"
echo "=============================="
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X GET \
  "https://${HOST}${URI}" \
  -H "Host: ${HOST}" \
  -H "x-bce-date: ${BCE_DATE}" \
  -H "Content-Type: application/json" \
  -H "Authorization: ${AUTHORIZATION}")

HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "HTTP 状态码: ${HTTP_CODE}  (错误)"
  echo "$HTTP_BODY" | jq .
  exit 1
fi

# ---------- 解析字段 ----------
CAPACITY=$(echo "$HTTP_BODY" | jq -r '.capacity     | tonumber')
USED=$(echo "$HTTP_BODY"     | jq -r '.usedCapacity | tonumber')
STATUS=$(echo "$HTTP_BODY"   | jq -r '.status')
PKG_TYPE=$(echo "$HTTP_BODY" | jq -r '.packageType')
DEDUCT=$(echo "$HTTP_BODY"   | jq -r '.deductPolicy')
ID=$(echo "$HTTP_BODY"       | jq -r '.id')
CREATE=$(echo "$HTTP_BODY"   | jq -r '.createTime')
ACTIVE=$(echo "$HTTP_BODY"   | jq -r '.activeTime')
EXPIRE=$(echo "$HTTP_BODY"   | jq -r '.expireTime')

# ---------- 换算为 MB ----------
CAP_MB=$(awk   -v v="$CAPACITY" 'BEGIN {printf "%.2f", v / 1048576}')
USED_MB=$(awk  -v v="$USED"     'BEGIN {printf "%.2f", v / 1048576}')
FREE_MB=$(awk  -v c="$CAPACITY" -v u="$USED" 'BEGIN {printf "%.2f", (c - u) / 1048576}')
USED_PCT=$(awk -v c="$CAPACITY" -v u="$USED" 'BEGIN {printf "%.1f",  u / c * 100}')

# ---------- 状态着色 ----------
if [[ "$STATUS" == "RUNNING" ]]; then
  STATUS_DISPLAY="\033[32m${STATUS}\033[0m"
else
  STATUS_DISPLAY="\033[33m${STATUS}\033[0m"
fi

echo ""
echo    "  流量包 ID   : ${ID}"
echo -e "  状态        : ${STATUS_DISPLAY}"
echo    "  套餐类型    : ${PKG_TYPE}"
echo    "  扣费策略    : ${DEDUCT}"
echo ""
printf  "  总容量    %14s MB            \n" "$CAP_MB"
printf  "  已使用    %14s MB  (%5s%%) \n" "$USED_MB" "$USED_PCT"
printf  "  剩余      %14s MB            \n" "$FREE_MB"
echo ""
echo    "  创建时间  : ${CREATE}"
echo    "  激活时间  : ${ACTIVE}"
echo    "  过期时间  : ${EXPIRE}"
echo ""
