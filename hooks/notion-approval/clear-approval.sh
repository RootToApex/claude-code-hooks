#!/bin/bash
# [무엇을 하나] UserPromptSubmit 훅. 사용자가 새 입력을 하면 승인 기록을 지운다.
# [왜 필요한가] 새 사용자 입력 = 새 작업 국면. 승인이 세션 내내 살아 있으면
#               "한 번 승인했더니 그 뒤로 뭐든 쓰더라"가 된다.
#               → 승인 1번의 유효 범위 = 그 승인으로 시작한 작업 묶음 하나.

session=$(cat | jq -r '.session_id // "nosession"')
rm -f "$HOME/.claude/hooks/state/approved-$session"
exit 0
