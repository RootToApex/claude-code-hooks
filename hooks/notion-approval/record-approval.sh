#!/bin/bash
# [무엇을 하나] PostToolUse 훅. **도구가 실제로 실행됐다 = 사용자가 승인을 눌렀다**는
#               신호를 이용해, 그 호출이 향한 대상 id를 "승인됨" 목록에 적어둔다.
# [왜 필요한가] 승인된 DB에 행 80개를 채우는 작업이 행마다 다시 묻지 않게 하려고.
#   - 쓰기: tool_input의 대상 id(page/block/parent db)만 좁게 기록
#           (본문 속 무관한 링크 id가 섞여 등록되지 않도록)
#   - 읽기: 조회 결과 중 **부모가 이미 승인된 대상**인 항목만 자동 등록(하위 상속)
#
# 다른 MCP 서버에 쓰려면 아래 `case "$tool" in mcp__notion*|mcp__*Notion*)` 의
# 패턴을 본인이 쓰는 서버 이름으로 바꾸세요. (별도 설정 변수는 없습니다)

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

# ── 대상 MCP 서버만 처리 ─────────────────────────────────────
case "$tool" in mcp__notion*|mcp__*Notion*) ;; *) exit 0 ;; esac

session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
dir="$HOME/.claude/hooks/state"; mkdir -p "$dir"
state="$dir/approved-$session"

add() { grep -qxF "$1" "$state" 2>/dev/null || printf '%s\n' "$1" >> "$state"; }

case "$tool" in
  *retrieve*|*API-get-*|*query*|*post-search*|*search*|*fetch*|\
  *get-comments*|*get-teams*|*get-users*|*get-self*|*get-async-task*|\
  *list-*|*download-*)
    # 하위 상속: 부모가 이미 승인된 항목만 등록
    # MCP 응답이 {content:[{type:"text",text:"<JSON문자열>"}]} 로 감싸여 오기도 하므로
    # ① tool_response 자체 ② 그 안의 문자열 중 JSON으로 파싱되는 것, 둘 다 훑는다.
    [ -s "$state" ] || exit 0
    printf '%s' "$input" \
      | jq -r '([.tool_response | objects]
                + [.tool_response | .. | strings | fromjson? | objects])
               | .[] | .. | objects | select(has("id") and has("parent"))
               | "\(.id)\t\(.parent.database_id // .parent.data_source_id // .parent.page_id // "")"' 2>/dev/null \
      | sort -u \
      | while IFS=$'\t' read -r pid parent; do
          [ -z "$parent" ] && continue
          grep -qxF "$parent" "$state" 2>/dev/null && add "$pid"
        done
    ;;
  *)
    # 쓰기가 실행됨 = 승인됨: 대상 필드만 좁게 기록
    printf '%s' "$input" \
      | jq -r '.tool_input
               | [ .page_id?, .block_id?,
                   .parent?.database_id?, .parent?.page_id?, .parent?.data_source_id? ]
               | .[] | select(. != null and . != "")' 2>/dev/null \
      | while IFS= read -r id; do add "$id"; done
    ;;
esac

# 오래된 세션 기록 정리 (7일)
find "$dir" -name 'approved-*' -mtime +7 -delete 2>/dev/null
exit 0
