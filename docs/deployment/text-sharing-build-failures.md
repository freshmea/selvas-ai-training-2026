# 텍스트로 공유한 앱을 다시 배포할 때: npm 설치 실패 진단

**사례 기준일: 2026-10-21**

[3일차 활동 안내](../../lessons/day03.md) · [Google AI Agent 수정 요청문](../../prompts/fix-npm-install.md) · [검증 기록지](../../worksheets/day03-deployment-checklist.md)

## 1. 어떤 상황인가

한 사람이 App Builder에서 만든 앱의 전체 소스를 텍스트로 공유하고, 교육생이 그 텍스트를 Google AI Agent에 전달해 자기 앱을 복원·배포하려는 상황입니다. 교육생은 Cloud Build 시스템과 자동 생성 배포 설정을 직접 수정할 수 없어서 AI에게 프롬프트로 변경을 요청합니다.

전달 텍스트는 참고·분석 자료가 될 수 있습니다. 하지만 AI가 비슷하게 만든 앱은 원본 프로젝트의 정확한 복제와 다를 수 있습니다. **소스 텍스트 전달, 파일 복원, 의존성 설치, Cloud Run 배포는 별개의 단계**입니다.

## 2. 제공 자료에서 확인한 사실

| 근거 | 확인 내용 | 여기서 단정하면 안 되는 것 |
| --- | --- | --- |
| 교육생이 제공한 Cloud Build 로그 | 소스 ZIP 다운로드·압축 해제·Node 이미지 확보·파일 복사 후 `RUN npm install`에서 실패 | React 코드, Gemini 키, Agent 권한이 원인이라고 단정 |
| 제공된 전체코드 텍스트 | `BEGIN FILE`/`END FILE` 경계로 22개 파일 수록 | 이 텍스트와 실패한 빌드의 소스가 바이트 단위로 같다고 단정 |
| 텍스트의 파일 목록 | 루트·frontend·backend의 package.json은 있고 package-lock.json과 Dockerfile은 없음 | 원본 서비스에 Dockerfile이 전혀 없었다고 단정. 플랫폼이 생성할 수도 있음 |
| 의존성 설정 | 루트 workspaces는 frontend/backend. 루트 1개·frontend 9개의 직접 의존성이 `latest` | 모든 latest 조합이 실패한다거나 lockfile만으로 모든 npm 오류가 사라진다고 단정 |
| 환경 설정 | backend/.env.local도 텍스트에 포함 | 전체 텍스트가 외부 공개에 적합하다고 간주 |
| 이전 생성 예제와 비교 | 첨부 텍스트의 package.json 3개가 참고 lockfile 생성 기준과 JSON 구조상 일치 | 다른 교육생 앱의 수정된 manifest까지 같다고 간주 |

전체코드 텍스트 원문과 `.env.local` 값, 앱에 포함된 데이터·계정별 실행 정보는 이 공개 저장소에 올리지 않았습니다. 공개 자료에는 설명·프롬프트·의존성 참고 JSON만 포함합니다.

## 3. 로그를 정확히 읽기

핵심 부분만 추리면 다음과 같습니다.

```text
Step 6/25 : RUN npm install
npm error Cannot read properties of null (reading 'edgesOut')
npm notice New major version of npm available! 10.8.2 -> 12.2.0
The command '/bin/sh -c npm install' returned a non-zero code: 1
```

**실패는 npm 업그레이드가 아니라 의존성 설치입니다.** 마지막 줄의 새 npm 버전 안내는 알림이며, npm 12 설치를 시도하다 실패했다는 기록이 아닙니다.

`edgesOut`은 npm 내부의 의존성 관계 계산에 등장하는 속성입니다. npm 공식 저장소에도 같은 오류 보고가 있습니다. 그러나 상세 debug 로그와 실제 패키지 조합을 확인하지 않고 이번 사례의 정확한 유발 패키지나 하나의 원인을 확정할 수는 없습니다. [npm 공식 오류 보고](https://github.com/npm/cli/issues/8261)

| 단계 | 이번 로그 | 다음 확인 |
| --- | --- | --- |
| 소스 가져오기 | 성공 | 실제 배포 ZIP의 파일 목록 |
| 의존성 설치 | 실패 | package.json, lockfile, Node/npm 버전, peer 충돌 |
| `vite build` 등 앱 번들 생성 | 미도달 | 설치가 해결된 뒤 컴파일·import 오류 확인 |
| 컨테이너 서버 시작 | 미도달 | 진입 파일·정적 파일 경로·PORT·환경변수 |
| Gemini/Agent 호출 | 미도달 | 서버 인증·모델·리전·API 접근 권한 |

이번 실패를 고치려고 먼저 IAM 역할을 넓히거나 앱을 공개로 바꿀 근거는 없습니다. 다음 단계에서 별도의 권한 오류가 나면 그 로그에 따라 진단합니다.

## 4. 텍스트 공유에서 달라질 수 있는 네 가지

### 파일 경로와 경계

`BEGIN FILE: frontend/package.json` 같은 구분자는 설명용입니다. 해당 구분자까지 코드 파일에 붙이면 JSON이나 TypeScript 문법이 깨질 수 있습니다. 반대로 AI가 내용을 요약하거나 긴 constants 파일을 생략하면 앱이 원본과 달라집니다. 파일 목록과 실제 경로를 대조합니다.

### 의존성 버전

package.json에 `latest`가 있으면 설치 시점에 따라 해석 버전이 달라질 수 있습니다. 상위 패키지 이름만 같아도 간접 의존성이나 peer 관계가 달라질 수 있습니다. lockfile은 실제 설치 트리를 기록하므로 같은 manifest와 함께 보존합니다. [npm lockfile 설명](https://docs.npmjs.com/cli/v11/configuring-npm/package-lock-json/)

### 빌드·실행 환경

원본에서 성공한 Node/npm, Dockerfile, 빌드 명령과 새 앱의 자동 생성 환경이 다를 수 있습니다. 화면 Preview 성공이 Linux 컨테이너 빌드 성공을 보장하지 않습니다. 이번 텍스트에 Dockerfile이 없다는 점과 Cloud Build에는 Dockerfile 단계가 있다는 점도 구분해야 합니다.

### 계정별 설정과 외부 자원

Cloud 프로젝트·리전·Agent ID·서비스 계정·Sheets 권한은 다른 계정으로 자동 복사되지 않습니다. `.env.local`이 포함돼 있다고 새 프로젝트에서 원본 자원에 접근할 수 있는 것은 아닙니다. 소스·환경 설정·외부 자원·허용 권한을 별도로 인계하고 비밀값은 공개 공유하지 않습니다.

## 5. 권장 전달 방식

| 방식 | 용도 | 함께 확인할 것 |
| --- | --- | --- |
| 전체코드 TXT | 검토·설명·AI 수정 요청의 참고 | 전체 파일 경계와 누락 여부. 실행 가능한 프로젝트 그 자체가 아님 |
| 소스 ZIP | 파일 구조를 보존한 전달 | lockfile 포함, 생성 파일 누락, 환경 설정·자료의 공유 범위 |
| Git 저장소와 커밋 | 같은 버전의 파일을 추적하고 수정 사항 비교 | 정확한 commit, 비밀값 제외, 설치·빌드 검증 기록 |

ZIP이나 Git도 환경·권한까지 자동 복제하지 않습니다. 텍스트만 전달할 때에는 파일 목록과 검증된 의존성·명령·미완료 사항을 반드시 같이 보냅니다.

## 6. lockfile을 적용할 때

루트 workspace 설치를 유지한다면 기본 구조는 다음과 같습니다.

```text
project/
  package.json
  package-lock.json
  frontend/
    package.json
  backend/
    package.json
```

루트 lockfile을 frontend 폴더에 복사해서 독립 설치용으로 사용하지 않습니다. 반대로 독립 설치로 전환하면 각 설치 경로와 lockfile 구성을 함께 다시 설계해야 합니다.

AI가 실행 도구를 가지고 있다면 현재 프로젝트의 manifest로 생성합니다.

```sh
npm install --package-lock-only --ignore-scripts --no-audit --no-fund
npm ci --include=dev --no-audit --no-fund
npm run build --workspace=frontend
```

명령은 실제 프로젝트의 workspaces 구성에 맞춰 조정합니다. `npm ci`는 lockfile이 필요하고 package.json과 맞지 않으면 실패합니다. 생성 단계의 `--ignore-scripts`와 실제 빌드용 설치를 혼동하지 않습니다. 기본적으로 필요한 설치 스크립트를 막아 놓은 상태만으로 배포 검증을 끝내지 않습니다. [npm ci 공식 안내](https://docs.npmjs.com/cli/v11/commands/npm-ci/)

lockfile의 수천 줄, resolved·integrity 값을 AI에게 추정해서 쓰게 하지 않습니다. 실제 npm이 생성해야 합니다. `--force`나 `--legacy-peer-deps`도 기본 해결책으로 쓰지 말고, 먼저 충돌 패키지와 호환성을 확인합니다.

**실제 배포 입력에 포함되는지가 중요합니다.** 새 빌드의 압축 해제 목록에 `/workspace/package-lock.json`이 있는지, 설치 전에 컨테이너로 복사하는지, 최종 실행 명령이 lockfile을 사용하는지 확인합니다. 화면에서 파일이 보이는 것과 플랫폼이 배포에 포함하는 것은 다릅니다.

## 7. 시스템을 직접 수정할 수 없을 때

[Google AI Agent 요청문](../../prompts/fix-npm-install.md)을 해당 교육생의 앱 편집 대화에 복사합니다. 현재 오류 로그와 현재 파일 목록을 함께 제공합니다.

수정 가능한 Dockerfile이라면 lockfile·workspace manifest를 설치 전에 COPY하고 빌드 단계에 `npm ci --include=dev`를 쓰도록 요청합니다. 실제 서버 진입 파일과 정적 파일 경로는 유지해야 하므로 다른 앱의 Dockerfile 전체를 무작정 덮어쓰지 않습니다.

자동 생성 Dockerfile을 수정할 수 없다면 AI도 그 시스템 영역을 바꿀 수 있다고 보장할 수 없습니다. AI가 프로젝트 lockfile을 저장했더라도 플랫폼이 제외하거나 고정된 설치 과정을 강제할 수 있습니다. AI에게 **변경 가능한 파일, 실제 실행 명령, 배포 ZIP 포함 여부, 해결되지 않은 플랫폼 제약**을 구분해 보고하게 합니다.

명령 실행 도구가 없는 AI가 '빌드 성공'이라고 답하면 실행 로그를 요청합니다. 실행하지 않은 단계는 미실행으로 기록해야 합니다.

## 8. 이번에 생성하고 검증한 참고 파일

[의존성 참고 폴더](../../examples/deployment-lock/README.md)에 루트 lockfile과 기준 manifest 3개를 제공합니다. 앱 전체 소스나 배포 완료본이 아닙니다.

| 항목 | 실제 확인 |
| --- | --- |
| lockfile 생성 | Windows / Node 24.14.0 / npm 11.12.1, lockfileVersion 3 |
| 기준 package.json 3개와 lockfile | dependencies·devDependencies·workspaces 정합성 확인 |
| 제공된 전체코드 텍스트와 기준 manifest | 3개 모두 JSON 구조상 일치 |
| Node 22.22.0 + npm 10.8.2 | `npm ci --include=dev` 통과 |
| 같은 환경의 프런트 빌드 | Vite 8.3.4 빌드 종료 코드 0 |
| 시스템 npm 업그레이드 | 하지 않음. 격리된 도구 캐시에서 추가 버전 실행 |
| Linux Docker / 학생 Cloud Build | 미검증. 로컬 Docker Linux daemon이 실행되지 않았음 |
| 백엔드 기동·모델 호출·학생 서비스 URL | 이번 참고 파일 작업에서는 미검증 |

같은 npm 10.8.2에서도 이 참고 lockfile의 설치가 성공했다는 사실은 업데이트 알림 자체가 원인이 아님을 보여 줍니다. 하지만 실패 당시의 전체 의존성 조합을 재현한 통제 실험은 아니므로 'lockfile 하나가 유일한 해결 원인이었다'고 주장하지 않습니다.

## 9. 교육생이 남길 증거

[기록지](../../worksheets/day03-deployment-checklist.md)에 다음을 작성합니다.

1. 전달 파일 목록과 실제 프로젝트 목록의 차이.
2. Node/npm 버전, 루트 workspace 여부와 lockfile 위치.
3. AI가 수정한 파일과 실제 실행 명령·종료 코드.
4. 설치, 프런트 빌드, 서버 기동, Cloud Build, URL 응답 각각의 상태.
5. 같은 가상 질문의 기대 답·실제 답·원천 근거와 지연.

설치만 성공한 상태를 배포 성공으로, 웹 화면이 열린 상태를 Agent 응답 성공으로 기록하지 않습니다. Chat 앱 등록 계정 요건도 npm 설치 오류와 별개의 주제입니다.

## 확인 문제

- `npm notice New major version`이 있으면 npm 업그레이드에 실패했다는 뜻인가?
- 텍스트에 Dockerfile이 없는데 빌드 로그에는 Docker 단계가 있는 이유는 무엇일 수 있는가?
- 다른 프로젝트의 lockfile을 복사하기 전에 무엇이 일치해야 하는가?
- AI에게 '고쳐줘'만 요청하는 것보다 변경 파일·실행 로그·미완료 항목을 요구해야 하는 이유는 무엇인가?
- Windows의 프런트 빌드 성공이 학생 Cloud Run 서비스 정상 동작의 증거가 아닌 이유는 무엇인가?

## 강사 해설

업데이트 알림과 실패를 구분합니다. 플랫폼이 배포 파일을 생성했을 수 있고, 그 생성 과정은 별도 확인해야 합니다. lockfile은 현재 프로젝트의 manifest·설치 구조와 일치해야 합니다. AI의 답변만으로 실제 실행을 입증할 수 없으므로 로그와 종료 코드를 확인합니다. 마지막으로 운영체제·Node/npm·진입점·환경변수·외부 자원 권한과 서비스 응답을 단계별로 검증해야 합니다.
