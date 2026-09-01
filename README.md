# claude-code-hooks

> Claude Code를 **권고가 아니라 강제로** 통제하는 훅 모음.
> Hooks that actually stop Claude Code — because rules written in a doc get broken.

## 왜 훅인가

`CLAUDE.md`에 "항상 ~해라"라고 적어도 지켜지지 않는 순간이 옵니다. 문서는 **권고층**이라 모델이 맥락을 잃거나 급하면 그냥 넘어갑니다.

훅은 **강제층**입니다. `PreToolUse`에서 `exit 2`로 끝내면 그 도구 호출은 실행되지 않습니다. 설득이 아니라 차단입니다.

이 레포의 운영 원칙은 하나입니다:

> **반복해서 어겨지는 규칙은 문서에서 훅으로 승격한다.**

여기 있는 훅은 전부 "실제로 사고가 났거나 반복 위반이 있어서" 만들어진 것들입니다. 처음부터 다 만들어 둔 방어막이 아닙니다.

## 훅 목록

| 훅 | 이벤트 | 동작 | 막는 사고 |
|---|---|---|---|
| `guard-agent-model.sh` | PreToolUse(Agent) | **deny** | 서브에이전트를 모델 지정 없이 띄워 비싼/약한 모델로 도는 것 |
| `guard-bulk-staging.sh` | PreToolUse(Bash) | **deny** | `git add .`·`-A`·`git commit -am`으로 빌드산출물·로컬 설정·비밀파일이 통째로 커밋되는 것 |
| `guard-force-push.sh` | PreToolUse(Bash) | **deny** | `--force` 계열·`+refspec`로 원격 이력이 재작성되는 것 |
| `guard-blocked-actions.sh` | PreToolUse(Bash) | **deny** | 사람 몫인 작업(PR 머지·리뷰·코멘트)과 이력 재작성(`filter-repo`)을 AI가 실행하는 것 |
| **`guard-secret-bypass.sh`** | PreToolUse(Bash) | **deny** | `--no-verify`·`core.hooksPath` 조작·`GIT_CONFIG_*` 주입으로 **시크릿 차단 훅을 우회**하는 것 |
| **`guard-hook-files.sh`** | PreToolUse(Write/Edit) | **deny** | **가드 자신을 편집해서 무력화**하는 것 (위 훅과 세트) |
| **`guard-ai-traces.sh`** | PreToolUse(Bash/문서 MCP) | **deny** | 커밋 서명(`Co-authored-by`)·산출물 본문에 AI 흔적이 남는 것 |
| `guard-outbound-text.sh` | PreToolUse(Bash) | **deny** | 커밋 메시지·PR·이슈 본문에 **나가면 안 되는 표현**이 섞이는 것 |
| `guard-bash-danger.sh` | PreToolUse(Bash) | **ask** | push·외부 공개·임시경로 밖 `rm`·파괴적 git을 확인 없이 실행하는 것 |
| `guard-protected-files.sh` | PreToolUse(Write/Edit) | **ask** | 정본 파일이 조용히 덮어써지는 것 |
| **`gate-outbound-message.sh`** | PreToolUse(메시징 MCP) | **ask** | 사람이 읽는 메시지(슬랙 등)가 검토 없이 나가는 것 |
| `notion-approval/` (3종) | Pre/PostToolUse + UserPromptSubmit | **ask + 대상 단위 승인 기억** | 외부 문서 도구에 무단으로 쓰는 것. 한 번 승인한 대상은 그 작업 동안 다시 묻지 않음 |

### 세트로 동작하는 것들

- **`guard-secret-bypass` + `guard-hook-files`** — Bash로 우회하는 문과 편집 도구로 우회하는 문을 각각 막습니다. **하나만 있으면 다른 쪽으로 뚫립니다.** (외부 교차리뷰에서 나온 지적)
- **`notion-approval/` 3종** — Pre(묻기) · Post(승인 기록) · UserPromptSubmit(기록 초기화)

## deny와 ask를 나누는 기준

- **deny**: 되돌릴 수 없거나, 애초에 AI가 판단할 일이 아닌 것 → 막고 사람에게 보고하게 한다
- **ask**: 정당한 경우가 실제로 있는 것 → 대상을 눈으로 확인하고 승인

deny를 구현하는 길은 두 개고, 이 레포는 둘 다 씁니다.

| 방식 | 모델에게 전달되는 것 | 쓰는 훅 |
|---|---|---|
| `exit 2` | **stderr에 쓴 내용** | 나머지 deny 훅 전부 |
| `exit 0` + stdout JSON `permissionDecision:"deny"` | `permissionDecisionReason` | `guard-ai-traces.sh` |

ask는 JSON 방식으로만 됩니다 — `exit 2`에는 대응물이 없습니다.

판단이 안 서면 막는 쪽(fail-closed)이 기본입니다.

## 설치

**환경**: macOS·Linux + `bash`. 훅은 `#!/bin/bash`이고 일부는 bash 전용 문법(프로세스 치환)을 씁니다 — `sh`/`dash`에서는 동작하지 않습니다. `jq`도 필요합니다 (`brew install jq` / `apt install jq`).

1. 스크립트를 복사하고 실행 권한을 줍니다.

```bash
git clone https://github.com/RootToApex/claude-code-hooks
mkdir -p ~/.claude/hooks
cp claude-code-hooks/hooks/*.sh ~/.claude/hooks/
cp -r claude-code-hooks/hooks/notion-approval ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh ~/.claude/hooks/notion-approval/*.sh
```

2. `settings.example.json`을 참고해 `~/.claude/settings.json`에 배선합니다.
   **필요한 것만 고르세요 — 전부 켤 이유는 없습니다.** 특히 `guard-ai-traces.sh`는 커밋의
   `Co-authored-by` 서명을 막으므로, 그 서명을 쓰신다면 배선에서 빼세요.

3. **배선한 훅이 실제로 살아 있는지 확인합니다.** 경로가 틀리면 훅은 에러 없이 그냥 통과되고,
   아무도 알려주지 않습니다. 설치했다는 사실과 지금 동작한다는 사실은 다릅니다.

```bash
# ① 배선된 명령의 파일이 존재하고 실행 가능한가 — 아무것도 안 나오면 정상
jq -r '.hooks[][].hooks[].command' ~/.claude/settings.json | awk '{print $1}' | \
  while read -r p; do p="${p/#\$HOME/$HOME}"; p="${p/#\~/$HOME}"; \
    [ -x "$p" ] || echo "없음/실행불가: $p"; done

# ② 실제로 막히는가 — exit=2 면 정상
printf '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}' \
  | ~/.claude/hooks/guard-bulk-staging.sh >/dev/null 2>&1; echo "exit=$?"
```

> ⚠️ `guard-hook-files.sh`를 배선하면 **그 시점부터 AI가 `~/.claude/hooks/`·`.claude/settings.json`·`.githooks/`를 편집할 수 없습니다.** 가드가 자기 자신을 보호하는 의도된 동작입니다. 훅을 고칠 때는 사람이 직접 편집하거나, 이 훅을 배선에서 잠시 빼세요.

## ⚠️ 이 레포는 세척된 사본입니다

원본은 제 개인 환경에서 돌던 훅이라, 공개하면서 **사람·조직을 특정할 수 있는 값을 전부 제거했습니다.**

- **실명·GitHub 로그인·팀원 아이디** → 삭제 (`guard-outbound-text.sh`의 금지어 목록은 **빈 채로** 두었습니다)
- **개인 절대경로**(`/Users/<이름>/...`) → `$HOME` 또는 placeholder
- **내부 문서명·사내 브랜치명·프로젝트 고유 규칙** → 삭제
- **보호 대상 파일 경로** → `guard-protected-files.sh`의 패턴은 예시만 남김

즉 **그대로 복사하면 일부 훅은 아무것도 막지 않습니다.** `# TODO:` 표시가 있는 자리를 본인 값으로 채워야 동작합니다. 특히:

| 파일 | 채워야 할 것 |
|---|---|
| `guard-outbound-text.sh` | `BANNED` 목록 — 외부로 나가면 안 되는 이름·문서명·도구명 |
| `guard-protected-files.sh` | `PROTECTED` 패턴 — 덮어쓰기 전에 물어야 할 정본 파일 |
| `guard-ai-traces.sh` | (선택) `EXTRA_TERMS` — 산출물에 나오면 안 되는 도구명. 비워두면 커밋 서명 차단만 동작 |
| `guard-bash-danger.sh` | (선택) 절대 push 금지할 브랜치명, 절대 지우면 안 되는 경로 |
| `settings.example.json` | **메시징 MCP matcher** — `mcp__<메시징서버>__...` 를 실제 도구 이름으로. 안 바꾸면 matcher가 아무것도 매칭하지 않아 `gate-outbound-message.sh`가 **조용히 안 돕니다** |

## 새 훅 추가하기

1. `hooks/`에 스크립트를 하나 추가합니다. 파일 맨 위에 **왜 만들었는지(어떤 사고를 막는지)** 를 주석으로 남깁니다 — 이게 이 레포의 규칙입니다.
2. 위 표에 한 줄 추가합니다.
3. `settings.example.json`에 배선을 추가합니다.

## 훅 계약 (Claude Code)

- stdin으로 JSON이 들어옵니다: `tool_name`, `tool_input`, `session_id` 등
- **`exit 2`** = 차단. stderr에 쓴 내용이 모델에게 전달됩니다 → **왜 막혔는지와 대신 뭘 해야 하는지**를 쓰세요
- `exit 0` + stdout JSON으로 `permissionDecision: "ask" | "deny" | "allow"` 를 돌려줄 수도 있습니다
- `PostToolUse`는 **도구가 실제로 실행됐을 때만** 돕니다 → "사용자가 승인했다"는 신호로 쓸 수 있습니다

## 라이선스

MIT
