#!/bin/bash
# [무엇을 막나] 사람 몫인 GitHub 액션(PR 머지·코멘트·리뷰)과 이력 통째 재작성.
# [왜 생겼나] 팀 레포에서 AI가 PR에 코멘트를 달거나 머지하면 그건 사람의 서명으로
#             나간다. 머지·리뷰는 책임이 따르는 행위라 AI에게 위임하지 않는다.
#             filter-branch/filter-repo는 되돌릴 수 없는 이력 재작성이다.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -z "$cmd" ] && exit 0

if printf '%s' "$cmd" | grep -qE 'gh[[:space:]]+pr[[:space:]]+(merge|comment|review)([[:space:]]|$|;|\||&)'; then
  echo "[차단] 'gh pr merge/comment/review'는 금지입니다." >&2
  echo "   머지·PR 코멘트·리뷰는 사용자 몫입니다. 멈추고 보고하세요." >&2
  exit 2
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+filter-(branch|repo)([[:space:]]|$|;|\||&)'; then
  echo "[차단] 'git filter-branch/filter-repo'(이력 통째 재작성)는 금지입니다." >&2
  echo "   이력 재작성이 필요하면 멈추고 사용자에게 보고하세요." >&2
  exit 2
fi
exit 0
