#!/bin/bash
# [무엇을 막나] 외부 문서 도구(여기선 Notion MCP)에 **무단으로 쓰는 것**.
# [왜 생겼나] "이거 어떻게 생각해?"를 "반영해달라"로 오해해서 페이지를 만들거나,
#             엉뚱한 상위 페이지 밑에 문서를 생성하는 사고가 반복됐다.
# [설계 포인트] 매번 묻지 않는다. **대상 단위 승인**이다 —
#   한 번 승인한 대상(페이지/DB와 그 하위 항목)에 이어지는 쓰기는 같은 작업 묶음 동안
#   다시 묻지 않는다. 승인 기록은 사용자의 다음 입력에서 초기화된다(clear-approval.sh).
#   → 승인 1번의 유효 범위 = 그 승인으로 시작한 작업 묶음 하나.
#
# 다른 MCP 서버에 쓰려면 아래 "읽기 전용" case 목록과 tool 접두사를 바꾸면 된다.

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

# ── 읽기 전용 도구는 통과 ────────────────────────────────────
case "$tool" in
  *retrieve*|*API-get-*|*query*|*post-search*|*search*|*fetch*|\
  *get-comments*|*get-teams*|*get-users*|*get-self*|*get-async-task*|\
  *list-*|*download-*)
    exit 0 ;;
esac

# ── 이번 작업 묶음에서 이미 승인된 대상이면 통과 ─────────────
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
state="$HOME/.claude/hooks/state/approved-$session"
if [ -s "$state" ]; then
  payload=$(printf '%s' "$input" | jq -r '.tool_input | tostring')
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    printf '%s' "$payload" | grep -qF -- "$id" && exit 0
  done < "$state"
fi

# ── 그 외(생성·수정·삭제·이동·댓글 등 쓰기): ask ─────────────
printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"외부 문서 쓰기 게이트 — 이 대상에 쓰는 첫 요청입니다. 어디에 무엇을 쓰는지 확인 후 승인하세요. (승인하면 같은 대상·하위 항목은 이번 작업 동안 다시 묻지 않습니다)"}}'
