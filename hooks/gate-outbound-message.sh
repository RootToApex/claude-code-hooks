#!/bin/bash
# [무엇을 하나] 사람에게 나가는 메시지(슬랙 전송·예약, 캔버스 생성 등) 앞에서 ask.
# [왜 생겼나] 파일을 잘못 쓰면 되돌리면 되지만, **메시지는 보내는 순간 끝난다.**
#             받는 사람이 이미 읽었기 때문에 취소가 의미 없다.
#             그래서 "되돌릴 수 있는가"가 아니라 "사람이 읽는가"를 기준으로 게이트를 건다.
# [배선] matcher에 실제 쓰는 메시징 MCP 도구 이름들을 넣는다.
#        예) mcp__<슬랙서버>__send_message|mcp__<슬랙서버>__schedule_message
#
# 이 훅은 조건 없이 항상 ask를 돌려준다 — matcher가 곧 조건이다.

printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"외부 발신 게이트 — 사람이 읽는 메시지입니다. 본문을 먼저 검토하고 승인해 주세요."}}'
exit 0
