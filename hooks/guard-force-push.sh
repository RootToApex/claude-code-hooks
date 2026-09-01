#!/bin/bash
# [무엇을 막나] git force-push (--force / -f / --force-with-lease / --force-if-includes / '+refspec').
# [왜 생겼나] 강제 푸시는 원격 이력을 되돌릴 수 없게 재작성한다. 이력 재작성이
#             필요한 상황이라면 그건 AI가 아니라 사람이 판단할 일이다.
# [허용] 일반 push (별도의 ask 게이트가 확인을 받는다).

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -z "$cmd" ] && exit 0

printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push' || exit 0

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push([[:space:]]+[^;|&]*)?[[:space:]](-f|--force|--force-with-lease|--force-if-includes)([[:space:]=]|$|;|\||&)'; then
  echo "[차단] force-push(--force / -f / --force-with-lease)는 금지입니다." >&2
  echo "   원격 이력 재작성이 필요하면 멈추고 사용자에게 보고하세요." >&2
  exit 2
fi

# '+refspec' 형태 (예: git push origin +main)
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]][^;|&]*[[:space:]]\+[A-Za-z0-9_./:-]+'; then
  echo "[차단] '+refspec' 강제 푸시 형태가 감지됐습니다. 멈추고 보고하세요." >&2
  exit 2
fi
exit 0
