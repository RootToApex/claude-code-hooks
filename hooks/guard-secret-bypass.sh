#!/bin/bash
# [무엇을 막나] 시크릿 차단 장치(git 훅)를 **우회하려는 명령** 자체.
# [왜 생겼나] 레포의 git 훅(.githooks/pre-commit)이 시크릿 커밋을 막아도
#             `--no-verify` 한 단어면 우회된다. 시간 압박 속에서 에이전트가 그걸
#             붙이고 사람이 승인창에서 습관적으로 yes를 누르면 그대로 뚫린다.
#             → 문서 규칙이 아니라 실행 차단으로 만든다.
# [보강 이력] 외부 교차리뷰에서 우회로 4개가 더 나와 함께 막았다:
#             ① git -c 인라인 설정 ② GIT_CONFIG_* 환경변수
#             ③ 셸 리다이렉트·tee로 훅 파일 덮어쓰기 ④ 가드 디렉터리 자기보호
#
# ※ 짝이 되는 훅: guard-hook-files.sh (Write/Edit 도구로 같은 파일을 고치는 경로를 막는다)
#    Bash만 막으면 편집 도구로 우회된다. 두 개가 세트다.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -z "$cmd" ] && exit 0

blocked() {
  echo "[차단] $1" >&2
  echo "   $2" >&2
  exit 2
}

# 1) --no-verify / -n 우회
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+(commit|push)([[:space:]]+[^;|&]*)?[[:space:]](-n|--no-verify)([[:space:]]|$|;|\||&)'; then
  blocked "git commit/push 의 --no-verify(-n)" \
"시크릿 차단 훅을 건너뛰는 명령입니다. 훅이 막았다면 진짜로 막아야 할 것이 있습니다.
   ▶ 걸린 값을 환경변수로 빼고 다시 커밋하세요.
   ▶ 정말 오탐이라면 근거를 사람에게 보고하고 승인을 받으세요. 임의로 우회하지 않습니다."
fi

# 2) core.hooksPath 조작 (허용형은 '훅 활성화' 하나뿐)
if printf '%s' "$cmd" | grep -q 'core\.hooksPath'; then
  if ! printf '%s' "$cmd" | grep -qE 'git[[:space:]]+config[[:space:]]+core\.hooksPath[[:space:]]+\.githooks([[:space:]]*($|;|&&))'; then
    blocked "core.hooksPath 조작" \
"훅을 무력화하는 설정입니다(-c 인라인·unset·경로 변경 포함).
   허용되는 유일한 형태는 'git config core.hooksPath .githooks'(활성화)뿐입니다."
  fi
fi

# 3) GIT_CONFIG_* 환경변수 주입 (git -c 와 같은 우회로)
if printf '%s' "$cmd" | grep -qE 'GIT_CONFIG[A-Z_]*='; then
  blocked "GIT_CONFIG_* 환경변수 주입" \
"환경변수로 git 설정을 주입하면 훅 경로도 바꿀 수 있습니다. 필요하면 사람에게 보고하세요."
fi

# 4) 훅·가드 파일 파괴·변조 (rm·chmod·mv·리다이렉트·tee·cp)
if printf '%s' "$cmd" | grep -qE '(rm[[:space:]]+[^;|&]*\.(githooks|claude)|chmod[[:space:]]+[^;|&]*\.(githooks|claude)|mv[[:space:]]+[^;|&]*\.(githooks|claude)|>[>]?[[:space:]]*[^;|&[:space:]]*\.(githooks|claude)/|tee[[:space:]]+[^;|&]*\.(githooks|claude)/|cp[[:space:]]+[^;|&]*[[:space:]][^;|&[:space:]]*\.(githooks|claude)/)'; then
  blocked ".githooks/.claude 변조" \
"차단 훅 또는 에이전트 가드를 삭제·덮어쓰기·무력화하는 조작입니다."
fi

exit 0
