#!/bin/bash
# [무엇을 막나] 산출물에 "AI가 만들었다"는 흔적이 남는 것.
#   1) 커밋 메시지의 Co-authored-by / "Generated with ..." 서명
#   2) 문서·다이어그램 본문에 검증에 쓴 도구 이름이 그대로 들어가는 것
# [왜 생겼나] 커밋 서명은 기본으로 붙는 경우가 있어 팀 레포 이력에 그대로 남는다.
#             그리고 문서에 "○○로 교차검증함" 같은 문장이 섞여 나간 적이 있다 —
#             **검증은 과정일 뿐 결과물에 적을 내용이 아니다.**
# [적용 범위] Bash(git commit)와 문서 계열 MCP 도구 양쪽.
#
# ⚠️ TODO: EXTRA_TERMS 를 본인 환경에 맞게 채우세요. 비워두면 2)만 꺼지고 1)은 그대로 동작합니다.

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
  exit 0
}

# ── 1) 커밋 서명 ─────────────────────────────────────────────
if [ "$tool" = "Bash" ] || [ -z "$tool" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
  if printf '%s' "$cmd" | grep -qiE 'co-authored-by|generated with.{0,5}(claude|ai|copilot)'; then
    deny "커밋 메시지에 AI 서명(Co-authored-by / Generated with ...)을 넣지 마세요."
  fi
fi

# ── 2) 산출물 본문의 도구 언급 ───────────────────────────────
# 여기를 채우세요. 예) EXTRA_TERMS='codex|코덱스|gpt-[0-9]'
EXTRA_TERMS=''
[ -z "$EXTRA_TERMS" ] && exit 0

payload=$(printf '%s' "$input" | jq -r '.tool_input | tostring' 2>/dev/null)
if printf '%s' "$payload" | grep -qiE "$EXTRA_TERMS"; then
  deny "산출물(문서/다이어그램)에 검증 과정에서 쓴 도구 이름을 넣지 마세요 — 검증은 과정일 뿐 결과물에 적지 않습니다."
fi
exit 0
