#!/bin/bash
# [무엇을 막나] 커밋 메시지·PR/이슈 본문처럼 "밖으로 나가는 글"에 들어가면 안 되는
#               표현이 섞이는 것. (예: 동료 실명·내부 문서명·사용한 AI 도구명 등)
# [왜 생겼나] AI가 커밋 메시지를 쓰다 보면 대화 맥락에 있던 이름·내부 용어를
#             그대로 옮긴다. 공개 레포에서는 그게 그대로 영구 기록이 된다.
#
# ⚠️ TODO: BANNED 목록이 비어 있으면 이 훅은 아무것도 막지 않습니다.
#          본인 환경에 맞는 금지어를 채우세요. 정규식(대소문자 무시)입니다.
#          짧은 약어는 \b 단어경계로 묶어 오탐을 줄이세요. (예: \bERD\b)

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -z "$cmd" ] && exit 0

# 검사 대상 명령만 (그 외는 통과)
case "$cmd" in
  *"gh issue create"*|*"gh issue edit"*|*"gh issue comment"*|\
  *"gh pr create"*|*"gh pr edit"*|*"gh pr comment"*|*"gh pr review"*|\
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# ──────────────────────────────────────────────────────────────
# 여기를 채우세요. 비워두면 훅이 동작하지 않습니다.
#   예) BANNED='홍길동|gildong-hong|내부문서\.md|\bAI도구명\b'
BANNED=''
# ──────────────────────────────────────────────────────────────

[ -z "$BANNED" ] && exit 0

# assignee/reviewer 값은 검사 제외 (거기엔 계정명이 정당하게 들어간다)
scan=$(printf '%s' "$cmd" | sed -E 's/--(add-|remove-)?(assignee|reviewer)[ =][^ ]*//g')

# --body-file / -F 로 넘긴 파일 내용도 검사 대상에 포함
while IFS= read -r p; do
  [ -n "$p" ] && [ -f "$p" ] && scan="$scan
$(cat "$p")"
done < <(printf '%s' "$cmd" | grep -oE -- '(--body-file|-F)[ =][^ ]+' | sed -E 's/^(--body-file|-F)[ =]//')

hit=$(printf '%s' "$scan" | grep -ioE "$BANNED" 2>/dev/null | sort -u | paste -sd ', ' - || true)
if [ -n "$hit" ]; then
  echo "[차단] 외부로 나가는 본문에 금지 표현이 감지됐습니다 → ${hit}" >&2
  echo "   해당 표현을 빼고 다시 작성하세요." >&2
  exit 2
fi
exit 0
