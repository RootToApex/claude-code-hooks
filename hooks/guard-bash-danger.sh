#!/bin/bash
# [무엇을 막나] 되돌리기 어려운 Bash 명령을 확인 없이 실행하는 것. 대부분 ask.
#   1) git push            → 원격 반영은 되돌리기 어렵다
#   2) GitHub 외부 공개 행위 → 팀원·외부가 읽는 글이 나간다 (PR/이슈 생성·수정·라벨 등)
#   3) 스크래치패드 밖 rm    → 삭제는 복구가 안 된다
#   4) 파괴적 git           → reset --hard, branch -D 등
# [왜 생겼나] "승인 없이 PR에 답변을 달았다", "엉뚱한 경로를 지웠다" 같은 사고가
#             실제로 났다. 개별 사고마다 패턴을 하나씩 추가해 온 훅이다.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

deny() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"; exit 0; }
ask()  { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}' "$1"; exit 0; }

# ── 1) git push ──────────────────────────────────────────────
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push'; then
  # TODO(선택): 절대 push하면 안 되는 브랜치가 있으면 여기에 추가
  #   if printf '%s' "$cmd" | grep -q '<브랜치명>'; then
  #     deny "차단: <브랜치명> 브랜치는 push 금지 (사유를 여기에)"
  #   fi
  ask "git push 게이트 — 원격 반영은 되돌리기 어렵습니다. 대상 레포·브랜치를 확인하고 승인하세요."
fi

# ── 2) GitHub 외부 공개 행위 ─────────────────────────────────
GH_WRITE='gh[[:space:]]+(pr|issue)[[:space:]]+(create|comment|review|edit|merge|close|reopen|ready|delete|lock|unlock)'
GH_WRITE+='|gh[[:space:]]+(release|repo|workflow|secret|variable|ruleset|label)[[:space:]]+(create|edit|delete|run|set|clone)'
GH_WRITE+='|gh[[:space:]]+api[^;|]*(-X|--method)[[:space:]]*=?[[:space:]]*(POST|PATCH|PUT|DELETE)'
if printf '%s' "$cmd" | grep -qE "$GH_WRITE"; then
  ask "GitHub 공개 게이트 — PR/이슈 생성·리뷰·댓글·라벨·레포 설정 변경은 승인 후 실행."
fi

# ── 3) 삭제 (임시 디렉터리 안은 자유) ────────────────────────
if printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)rm[[:space:]]'; then
  # TODO(선택): 절대 지우면 안 되는 경로를 여기에 추가
  #   if printf '%s' "$cmd" | grep -qE '<보호경로>'; then deny "차단: <보호경로> 삭제 금지"; fi
  if ! printf '%s' "$cmd" | grep -qE 'rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*["'"'"']?(/private/tmp|/tmp|[^ ]*scratchpad)'; then
    ask "삭제 게이트 — 임시 디렉터리 밖 rm 입니다. 대상 경로를 확인하고 승인하세요."
  fi
fi

# ── 4) 파괴적 git ────────────────────────────────────────────
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+(reset[[:space:]]+--hard|branch[[:space:]]+-D|filter-repo)'; then
  ask "파괴적 git 명령 게이트 — 복구가 어려운 작업입니다. 확인 후 승인하세요."
fi

exit 0
