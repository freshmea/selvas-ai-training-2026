# Hello World 배포 실패 재현과 빌드 환경 수정

2026-10-21. Google Cloud Agent Studio 앱 빌더의 실제 배포 ZIP을 기준으로 조사했다. 별도 Google AI Studio 사이트와 구분한다.

## 원인과 조사 근거

Hello World 화면도 기본 배포의 Docker `RUN npm install`에서 `Cannot read properties of null (reading 'edgesOut')`로 실패했다. 이 단계는 화면 코드 빌드 및 Agent 실행 전이다. 제품이력 업무 코드나 subagent는 오류를 재현하는 데 필요하지 않았다.

실제 ZIP에는 Node 20 기반 Dockerfile, frontend/backend workspace, `latest` 프런트엔드 의존성이 있었고 루트 lockfile은 없었다. 이전에 성공한 직접 배포본은 Node 22와 별도 설치 설정을 사용했으므로 동일한 배포 조건이 아니었다. 기존 두 서비스의 Dockerfile은 각각 `npm install --prefix frontend`와 backend 별도 설치를 사용했다. 이 두 서비스 모두가 `npm ci`로 배포됐다고 설명하면 부정확하다. 이후 교육생 검증 ZIP에는 Node 22.22.0·lockfile·`npm ci`를 적용했다.

npm 공식 [이슈 #8261](https://github.com/npm/cli/issues/8261) 및 [수정 PR #8448](https://github.com/npm/cli/pull/8448)은 Arborist의 재귀적인 `loadPeerSet`에서 부모가 없어진 노드를 참조하는 결함을 다룬다. PR은 2025-08-28 병합됐으며 npm 11.6.0 릴리스 PR에 연결된다. [후속 이슈 #9787](https://github.com/npm/cli/issues/9787)에는 최신 패키지 조합에서도 같은 오류와 여러 버전별 재현 결과가 보고돼 있다. 같은 문구가 모두 동일 원인이라는 뜻은 아니며, 무조건 최신 npm으로 바꾸면 모든 조합이 해결된다는 보장은 없다.

이번과 앞선 동일 환경의 로컬 재현은 `loadPeerSet` 스택과 일치한다. 자동 생성 템플릿의 구형 npm과 현재 의존성 그래프의 조합이 알려진 결함을 유발한다는 설명에 부합한다. Google이 앱 빌더 전체의 동일 결함을 공식 인정하거나 수정했다고 확인한 것은 아니다.

## 실제 수정

먼저 실패한 실제 소스 ZIP을 Cloud Shell에서 `gcloud storage cp`로 받아 별도 폴더에 압축을 풀었다. 제품이력 앱과 서비스는 변경하지 않았다.

1. Dockerfile의 두 `FROM node:20-slim`을 `FROM node:22.22.0-slim`으로 교체했다.
2. 빌드 단계의 프로젝트 설치 전에 `RUN npm install --global npm@11.12.1`을 추가했다.
3. 화면 소스, workspace 구조, 세 package.json의 의존성 목록을 유지한 대조 빌드에서 패키지 설치·Vite 빌드·이미지 생성이 성공했다.
4. 재현성을 위해 루트 `package-lock.json`을 생성하고 프로젝트 설치 명령을 `RUN npm ci --include=dev --no-audit --no-fund`로 변경했다. 원래 `COPY package*.json ./`가 lockfile도 복사한다. 프런트엔드와 백엔드 manifest도 설치 전에 복사해야 한다.

첫 성공은 Node와 npm을 함께 바꾼 결과다. 이 대조만으로 Node 변경과 npm 변경 각각의 기여도를 분리해 확정하지 않는다. lockfile 생성만으로 구형 npm 결함이 항상 해결된다고 가르치지 않는다. `--ignore-scripts`는 lockfile 생성에만 사용했으며 실제 컨테이너 설치에는 적용하지 않았다.

## gcloud 대조 실험에 사용한 요청문

아래는 앞서 성공한 수동 대조 실험을 재현하기 위한 기록이다. 이후 사용자는 기본 Cloud Run 배포 버튼만 사용하도록 결정했다. 현재 진행 지침은 아래의 기본 버튼 조사와 Google 오류 신고이며, 이 요청문으로 수동 배포를 다시 수행해 인수 시험을 대체하지 않는다.

```text
Hello World 화면과 기존 기능은 유지하고 실제 Cloud Build 입력 파일만 수정해 주세요.
편집기 안의 파일이 아니라, 배포에 실제 사용된 ZIP의 Dockerfile과 package.json을 확인하세요.
원본 ZIP과 Dockerfile은 별도 보관하세요. 키·토큰·환경변수 값은 출력하거나 공개 저장소에 넣지 마세요.

기본 Dockerfile이 node:20-slim과 루트 workspace npm install을 사용하고 edgesOut으로 실패합니다.
두 Docker 단계의 Node 이미지를 node:22.22.0-slim으로 고정하고,
빌드 단계에서 npm@11.12.1을 명시적으로 설치한 뒤 버전을 로그로 확인하세요.
업무 코드와 의존성 목록은 우선 바꾸지 말고 설치와 Vite 빌드가 통과하는지 확인하세요.

통과하면 루트 workspace package-lock.json을 생성하고,
세 package.json 및 루트 lockfile을 Docker 설치 전에 복사한 다음
npm ci --include=dev --no-audit --no-fund를 사용하세요.
수정된 파일로 실제 Linux Cloud Build를 다시 실행하고,
성공한 이미지를 기존 Hello World Cloud Run 서비스에 배포해 Ready 상태와 공개 HTTP의 Hello, world를 확인하세요.
로컬 설치 성공, 원격 빌드 성공, Cloud Run 배포 성공을 구분해 기록하세요.

앱 빌더가 파일을 재생성해 수정이 적용되지 않으면 적용됐다고 주장하지 마세요.
Cloud Shell의 수정 소스를 gcloud builds submit으로 빌드하고 gcloud run deploy --image로 배포하세요.
앱 빌더 기본 배포 버튼이 영구적으로 수정된 것은 아니라는 점을 명시하세요.
```

## 유지할 한계

Google의 [Agent Studio 배포 안내](https://docs.cloud.google.com/gemini-enterprise-agent-platform/agent-studio/deploy-vais-prompt)는 콘솔 밖에서 수정한 배포본을 Studio에서 다시 배포하면 덮어쓸 수 있다고 설명한다. 이 문서는 프롬프트 웹 앱 안내이며 App Builder 전체 템플릿 결함의 확인 문서는 아니다. 이번 외부 수정 성공을 앱 빌더 기본 버튼의 영구 수정으로 표현하지 않는다.

[Cloud Run 공식 문서](https://docs.cloud.google.com/run/docs/deploying-source-code)는 Dockerfile이 있으면 이를 사용하며, 빌드 제어가 필요하면 `gcloud builds submit` 후 `gcloud run deploy --image`를 사용할 수 있다고 안내한다. `npm ci`의 lockfile 요구사항은 [npm 공식 문서](https://docs.npmjs.com/cli/v11/commands/npm-ci/)를 따른다.

## gcloud 수정본 검증 결과

- 원본 기본 배포: 37초 후 npm 설치에서 실패.
- Node 22.22.0/npm 11.12.1 대조 빌드: Cloud Build SUCCESS, 161개 패키지 설치 및 Vite 빌드 성공.
- 루트 lockfile + `npm ci` 최종 빌드: Cloud Build SUCCESS, 실행 이미지 생성 완료.
- 원본 ZIP 대조: Dockerfile을 제외한 기존 파일의 바이트 변경 목록 `[]`. 세 package.json과 화면 소스는 원본 유지. 루트 lockfile은 새 파일로 추가.
- 최종 이미지를 digest로 기존 Hello World 서비스에 배포: Ready/ConfigurationsReady/RoutesReady 모두 True, 최신 리비전 트래픽 100%.
- 공개 브라우저: 로그인 없이 Hello, world 표시.
- 별도 외부 HTTP: 인증 헤더 없이 200, 응답 HTML에 Hello, world 포함 확인.

따라서 gcloud로 수정한 이 소스의 빌드·공개 실행은 확인됐다. 앱 빌더 자동 템플릿의 영구 수정이나 제품이력 앱의 동일 수정 완료를 뜻하지 않는다. 계정별 실제 URL·빌드 ID·원시 화면은 비공개 실험 기록에 보관했다.

## 필수 인수 시험: 프롬프트 수정 후 기본 버튼 재배포 — 실패

사용자는 베이스라인의 완료 조건을 **앱 빌더 프롬프트로 Hello, world → Edited world 수정 → 앱 업데이트 버튼 → 빌드 성공 → 공개 URL에서 변경 확인**으로 명확히 했다. 앞의 gcloud 직접 배포 성공만으로 이 조건을 충족하지 못한다.

2026-10-21 23:00 KST 실제 결과:

1. gemini-3.7-flash와 gemini-3.5-flash-lite 수정 요청은 Resource exhausted로 롤백됐다. gemini-2.5-pro에서는 프롬프트 수정과 체크포인트 저장이 성공했다. 직접 코드 편집은 하지 않았다.
2. 미리보기에서 Edited world를 확인하고 앱 빌더의 배포 → Cloud Run → 앱으로 배포 → 앱 업데이트 → 확인으로 진행했다.
3. 실제 새 Linux Cloud Build는 **36초 후 동일한 edgesOut 오류로 실패**했다.
4. 새 빌드의 실제 ZIP을 gcloud로 내려받아 확인했다. index.html·App.tsx에는 Edited world가 들어갔지만, Dockerfile은 다시 두 단계 모두 node:20-slim과 루트 npm install을 사용했고 **lockfile 목록은 빈 배열**이었다. 앞서 수정한 Node/npm/lockfile 설정은 기본 버튼의 생성 결과에 유지되지 않았다.
5. 공개 URL을 다시 확인하니 HTTP 200이지만 **Hello, world 유지 / Edited world 없음**이었다. HTTP 200만으로 새 배포 성공을 판정하면 안 된다.

**판정: 요청한 바이브 코딩 베이스라인은 아직 미완성.** 새 문구의 프롬프트 수정과 저장은 성공했지만 기본 버튼의 빌드 설정 유지가 실패했다. 앱 설정 화면에서 확인한 항목은 생성 모델·리전·지침·연결 리소스이며, 배포 Docker/npm 버전의 영구 설정 경로는 확보하지 못했다. 이 경로를 확보하거나 플랫폼 템플릿이 수정되어 같은 인수 시험을 통과하기 전에는 교육생용 정상 베이스라인이라고 배포하지 않는다. gcloud로 Edited world를 다시 게시하는 방법으로 이 시험을 대신하지 않았다.

## 버튼 구조를 추적한 추가 조사

현재 콘솔 페이지가 로드한 공개 JavaScript를 읽어, 버튼의 실제 생성·요청 경로를 확인했다. 콘솔 코드나 패키지 승인 필터를 변경하지 않았다.

- 배포 파일 생성 함수는 두 단계 Node 20 Dockerfile과 루트 workspace manifest를 문자열 상수로 만든다. 현재 템플릿 리비전도 2026-09-02 상수다.
- 프런트엔드 수집기는 index.html importmap 값에서 패키지 이름만 추출하고 버전을 제거한 뒤 모두 latest로 지정한다. 사용자 파일을 복사한 후 frontend/package.json과 Vite 설정을 다시 생성한다.
- 재배포는 새 ZIP의 storageSource와 빈 dockerBuild 설정을 deploySource로 전달한다. 확인한 경로에는 기존 서비스의 사용자 Node/npm/buildConfig를 합치는 분기가 없다.
- 모델의 index.html 패치는 승인 패키지 목록으로 importmap을 정규화한다. 실제 프롬프트로 요청한 Vitest/provider 항목은 제거됐고 주석만 남았다. 별도 TS 파일은 배포 수집 대상이 아니었다.

실제 기본 이미지 버전을 출력하니 **Node 20.20.2/npm 10.8.2**였다. 과거 Windows Node 20.18.1 대조만으로 동일 환경이라고 보면 안 된다. Node 20.20.2로 맞춘 재현에서는 기본형, Vitest 단독, Vitest+native binding 모두 실패했다. Vitest와 @vitest/browser-webdriverio를 함께 명시한 별도 Linux 빌드는 설치·Vite 빌드·이미지 생성에 성공했다. 다만 이 조합은 승인 패키지 정규화 때문에 모델 편집본에 유지되지 않아 **기본 버튼 해결책으로 적용 완료했다고 보고하지 않았다**. 승인된 관련 패키지의 metadata도 확인했지만 해당 peer 충돌을 제어하는 근거 있는 대체 구성은 찾지 못했다.

GitHub 게시와 고정 CI를 통한 별도 배포 경로도 제안했으나, 사용자는 **앱 빌더의 기존 Cloud Run 배포 버튼을 사용하는 방식만 진행**하도록 명확히 했다. 이 대안은 채택하지 않았고 새 저장소·트리거·IAM 역할을 생성하지 않았다. 아래 후속 조사는 기본 버튼을 유지하는 지원 설정이 있는지 확인한 결과다.

## 기본 Cloud Run 버튼 설정의 후속 확인

| 확인 대상 | 실제 확인 결과와 의미 |
| --- | --- |
| 현재 영어 콘솔의 공개 코드 | 현재 영어 페이지가 제공하는 공개 번들도 Node 20 기반 설치, 루트 workspace `npm install`, 템플릿 리비전 2026-09-02를 사용했다. 언어를 영어로 바꾸면 수정된 템플릿을 받는다는 가설을 뒷받침하지 않았다. 로그인 세션이나 콘솔 코드는 변경하지 않았다. |
| Docker 빌드 API | Google 공식 proto에서 `SubmitBuildRequest.DockerBuild`는 필드가 없는 메시지다. Node 이미지나 npm 옵션을 지정하는 필드는 없고, `base_image`·`environment_variables`는 `BuildpacksBuild`에 정의되어 있다. [공식 proto](https://github.com/googleapis/googleapis/blob/master/google/cloud/run/v2/build.proto) |
| 빌드 환경변수 | 공식 문서는 buildpacks에 전달하는 설정이라고 설명한다. 현재 기본 버튼이 명시적으로 선택하는 Docker 빌드의 설치 명령을 영구 변경하는 수단으로 확인되지 않았다. 실행 시 환경변수와도 구분한다. [빌드 환경변수 안내](https://docs.cloud.google.com/run/docs/configuring/services/build-environment-variables) |
| 기존 서비스의 buildConfig | 공식 API의 `Service.buildConfig`는 Cloud Run 함수 빌드 설정으로 설명된다. 현재 버튼의 새 ZIP·빈 Docker 빌드 요청이 기존 사용자 Node/npm 설정을 상속하는 분기는 확인하지 못했다. 기존 서비스에 값을 넣으면 다음 버튼 배포가 고쳐진다고 제시하지 않는다. [Service API](https://docs.cloud.google.com/run/docs/reference/rest/v2/projects.locations.services) |
| 앱 안의 `.npmrc` | 앱 빌더의 파일은 `frontend/` 아래로 수집된다. 기본 Docker 빌드는 설치 전 루트 manifest와 frontend/backend의 package.json만 복사하고, 나머지 파일은 설치 후 복사한다. 따라서 앱 파일로 추가한 `.npmrc`는 실패하는 최초 설치 시점에 존재하지 않는다. lockfile을 앱 안에 넣는 것만으로 루트 설치 전 복사가 보장되지 않는 이유도 같다. |
| 공개 수정 공지 | 조사한 공식 릴리스 노트에서 이 App Builder npm 오류의 수정이나 Node/npm 템플릿 선택 기능을 찾지 못했다. 공개 문서에 없다는 사실만으로 모든 내부 기능이 없다고 단정하지 않는다. [릴리스 노트](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes) |

**현재 판정:** 기본 버튼으로 프롬프트 수정본을 빌드·게시하는 인수 시험은 여전히 실패 상태다. 확인한 코드와 공식 설정 범위에서는 영구 고정 방법을 확보하지 못했으며, Google이 생성하는 배포 템플릿의 수정이 필요한 차단점으로 판단한다. 수동 gcloud 성공이나 화면의 HTTP 200으로 이 판정을 대신하지 않는다. 패키지 승인 필터 우회, 콘솔 코드 변조, 빌드 소스 교체는 해결 절차로 사용하지 않는다.

## Google 오류 신고 상태

Cloud 콘솔의 의견 보내기와 재시도에서 모두 **“의견을 보낼 수 없습니다”**가 표시됐다. 따라서 이 경로로 Google이 신고를 접수했다고 기록하지 않는다.

이후 공식 Vertex AI Studio Issue Tracker의 `componentid:1849271 edgesOut` 검색에서 일치 항목을 찾지 못했다. 이는 해당 검색 조건에서의 결과이며 기존 신고가 전혀 없다는 뜻은 아니다. 사용자는 약관과 민감정보를 제거한 공개 신고에 동의했고, 약관 확인과 제목·본문 작성까지 마쳤다. Google의 로봇 확인 단계에서 사용자가 직접 처리하기로 선택해 **현재 사용자 CAPTCHA 완료를 기다리는 상태**다. Create 실행과 이슈 등록은 아직 완료되지 않았으며 이슈 ID도 없다. [공식 이슈 검색](https://issuetracker.google.com/issues?q=componentid%3A1849271%20edgesOut)

로봇 확인 후 실제 등록 완료 화면이나 이슈 ID가 확인되면 접수 상태를 갱신한다. Google의 수정 일정·답변·공식 원인 인정은 아직 없다.

공개 교육용 신고 요약은 다음과 같다. 실제 프로젝트 식별자·계정 이메일·배포 주소·토큰·비밀값이 포함된 원시 파일은 이 문서에 싣지 않는다.

```text
제목: Agent Studio App Builder의 기본 Cloud Run 배포가 Hello World에서도 npm edgesOut 오류로 실패

기대 결과:
앱 빌더 프롬프트로 Hello, world를 Edited world로 수정한 뒤,
기존 Cloud Run 배포/업데이트 버튼으로 빌드와 게시를 완료할 수 있어야 합니다.

재현:
1. Google Cloud Agent Studio 앱 빌더에서 단순 Hello World 앱을 생성합니다.
2. 미리보기를 확인한 뒤 기본 Cloud Run 배포 버튼을 누릅니다.
3. 실제 Cloud Build는 화면 빌드 전에 루트 workspace npm install에서
   Cannot read properties of null (reading 'edgesOut')로 실패합니다.
4. 프롬프트 수정본의 미리보기와 저장은 성공하지만 버튼 업데이트도 같은 지점에서 실패합니다.

확인한 조건:
기본 생성 환경은 Node 20.20.2/npm 10.8.2, latest 의존성, 루트 lockfile 없음입니다.
원래 업무 소스와 세 package.json을 유지하고 Node 22.22.0/npm 11.12.1로
바꾼 별도 Linux 대조 빌드는 성공했습니다. 이 대조는 두 버전을 함께 바꾼 결과입니다.
다음 기본 버튼 요청은 Node 20/npm install 구조를 다시 생성해 수정 설정이 유지되지 않습니다.
현재 영어 공개 번들도 같은 설치 구조와 템플릿 리비전 2026-09-02를 사용합니다.

요청:
기본 버튼의 생성 빌드 템플릿과 npm 의존성 해결 오류를 조사해 주세요.
지원되는 영구 설정이 있다면 안내해 주시고, 없다면 템플릿을 수정해 주세요.
별도 CI나 수동 배포가 아니라 기본 버튼의 프롬프트 수정→업데이트 흐름이 필요합니다.
```
