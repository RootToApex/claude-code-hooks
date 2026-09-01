#!/bin/bash
# [무엇을 막나] "고르지 않고 통째로 스테이징하는" 모든 경로.
#   1) git add . / * / -A / -u / --all / --update
#   2) git commit -a / -am / --all     ← add를 건너뛰고 추적 파일 전체를 스테이징
# [왜 생겼나] 벌크 스테이징은 빌드 산출물·의존성 디렉터리·로컬 설정·비밀 파일을
#             통째로 끌어들인다. 커밋되면 이력에 남는다.
# [이름을 바꾼 이유] 처음엔 'guard-git-add-all'이라는 이름으로 `git add`만 봤다.
#   그런데 `git commit -am` 한 줄이면 같은 일이 그대로 됐다. **명령어가 아니라
#   행위(벌크 스테이징)를 기준으로 막아야 한다**는 걸 뒤늦게 알고 이름부터 고쳤다.
# [허용] 경로를 명시한 add, `git commit -m`, `git commit --amend`. 삭제는 git rm.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -z "$cmd" ] && exit 0

# 공백·명령경계로 둘러싸인 토큰만 매칭 → 파일명 속 '.'·'-A'는 오탐하지 않는다
ADD_BULK='git[[:space:]]+add([[:space:]]+[^[:space:];|&]+)*[[:space:]]+(\.|\*|-A|-u|--all|--update)([[:space:]]|/|;|\||&|$)'
COMMIT_BULK='git[[:space:]]+commit([[:space:]]+[^;|&]*)?[[:space:]](-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$|;|\||&)'

if printf '%s' "$cmd" | grep -qE "$ADD_BULK"; then
  cat >&2 <<'EOF'
[차단] 벌크 스테이징 금지 — git add . / * / -A / -u / --all
   수정·삭제한 파일을 하나하나 명시해서 추가하세요.
   예) git add src/main/App.java build.gradle
   (삭제는 git rm <경로>)
EOF
  exit 2
fi

if printf '%s' "$cmd" | grep -qE "$COMMIT_BULK"; then
  cat >&2 <<'EOF'
[차단] 벌크 스테이징 금지 — git commit -a / -am / --all
   -a 는 추적 중인 파일의 변경을 전부 자동 스테이징합니다(= 고르지 않은 커밋).
   git add <파일들> 로 명시한 뒤 git commit -m "..." 하세요.
EOF
  exit 2
fi
exit 0
