#!/bin/bash
# [무엇을 막나] "정본" 파일이 조용히 수정·덮어쓰기 되는 것. 차단이 아니라 ask.
# [왜 생겼나] 파생물(문서·요약본)을 고치다가 원본까지 같이 손대는 일이 생긴다.
#             정본은 손대기 전에 사람이 한 번 봐야 한다.
#
# ⚠️ TODO: PROTECTED 패턴을 본인 환경에 맞게 채우세요. 아래는 예시입니다.

input=$(cat)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$fp" ] && exit 0

ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}' "$1"
  exit 0
}

case "$fp" in
  # ── 예시 패턴 (본인 것으로 바꾸세요) ────────────────────────
  */docs/ADR-*.md)      ask "설계 결정 기록(ADR) 수정입니다. 변경 내용을 확인하고 승인하세요." ;;
  */*정본*)             ask "정본 문서 수정입니다. 변경 내용을 확인하고 승인하세요." ;;
  *.env|*.env.*)        ask "환경설정 파일 수정입니다. 비밀값이 섞이지 않는지 확인하세요." ;;
  # ──────────────────────────────────────────────────────────
esac
exit 0
