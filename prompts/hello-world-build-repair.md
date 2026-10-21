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

## 프롬프트로 재현할 요청

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

## 최종 검증 결과

- 원본 기본 배포: 37초 후 npm 설치에서 실패.
- Node 22.22.0/npm 11.12.1 대조 빌드: Cloud Build SUCCESS, 161개 패키지 설치 및 Vite 빌드 성공.
- 루트 lockfile + `npm ci` 최종 빌드: Cloud Build SUCCESS, 실행 이미지 생성 완료.
- 원본 ZIP 대조: Dockerfile을 제외한 기존 파일의 바이트 변경 목록 `[]`. 세 package.json과 화면 소스는 원본 유지. 루트 lockfile은 새 파일로 추가.
- 최종 이미지를 digest로 기존 Hello World 서비스에 배포: Ready/ConfigurationsReady/RoutesReady 모두 True, 최신 리비전 트래픽 100%.
- 공개 브라우저: 로그인 없이 Hello, world 표시.
- 별도 외부 HTTP: 인증 헤더 없이 200, 응답 HTML에 Hello, world 포함 확인.

따라서 이 소스의 빌드·공개 실행 문제는 실제로 해결됐다. 앱 빌더 자동 템플릿의 영구 수정이나 제품이력 앱의 동일 수정 완료를 뜻하지 않는다. 계정별 실제 URL·빌드 ID·원시 화면은 비공개 실험 기록에 보관했다.
