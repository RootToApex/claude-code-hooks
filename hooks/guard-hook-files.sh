#!/bin/bash
# [무엇을 막나] 가드 자신을 편집 도구(Write/Edit)로 고쳐서 무력화하는 것.
# [왜 생겼나] 외부 교차리뷰에서 나온 지적 — Bash 명령만 막으면 에이전트가
#             Write/Edit 도구로 `.githooks/*`나 `.claude/*`를 직접 고쳐
#             차단 장치를 그냥 없애버릴 수 있다. 문을 하나만 잠근 셈이었다.
# [핵심] **가드는 자기 자신을 보호해야 한다.** guard-secret-bypass.sh(Bash)와
#        이 훅(Write/Edit)이 세트로 있어야 우회로가 닫힌다.

input=$(cat)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[ -z "$fp" ] && exit 0

case "$fp" in
  */.githooks/*|*/.git/config|*/.git/hooks/*|*/.claude/settings.json|*/.claude/settings.local.json|*/.claude/hooks/*)
    echo "[차단] 보호 파일 편집 — $fp" >&2
    echo "   차단 훅·에이전트 가드는 작업 중 수정 대상이 아닙니다." >&2
    echo "   수정이 정말 필요하면 이유를 사람에게 보고하고 승인을 받으세요." >&2
    exit 2
    ;;
esac
exit 0
