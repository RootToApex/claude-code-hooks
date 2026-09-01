#!/bin/bash
# [무엇을 막나] 서브에이전트(Agent 도구)를 model 지정 없이 띄우는 것.
# [왜 생겼나] "작업에 맞는 모델로 돌려라"를 문서(CLAUDE.md)에 적어뒀는데 반복해서
#             빠뜨리고 상속에 방치했다. 권고층에서 강제층으로 승격한 사례.
# [예외] subagent_type="fork"는 부모 모델을 강제 상속하므로 model 지정이 무시된다.

input=$(cat)

subagent_type=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // ""' 2>/dev/null)
model=$(printf '%s' "$input" | jq -r '.tool_input.model // ""' 2>/dev/null)

if [ "$subagent_type" = "fork" ]; then
  exit 0
fi

if [ -z "$model" ] || [ "$model" = "null" ]; then
  cat >&2 <<'EOF'
[차단] Agent 호출에 model 파라미터가 없습니다. 작업에 맞는 모델을 명시하세요.

  수집·정리·단순 대조 (웹 조사, 파일 훑기, 확인 작업)  → 작고 빠른 모델
  설계·리뷰·복잡한 추론 (아키텍처 판단, 코드 리뷰)      → 가장 강한 모델
  기계적 변환 (형식 변경, 단순 추출)                    → 가장 가벼운 모델

상속에 맡기지 말고 매번 명시할 것. (예외: subagent_type="fork")
EOF
  exit 2
fi

exit 0
