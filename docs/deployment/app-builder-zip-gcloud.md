# 4일차 추가 실습: 미리보기 → ZIP → Cloud Shell → gcloud 배포

작성: 2026-10-22. 앱 제작·기능 수정은 Google Cloud Agent Studio 앱 빌더에서 계속하고, 배포는 Cloud Shell에서 진행하는 대체 절차다. 기본 Cloud Run 버튼의 오류가 해결됐다는 뜻은 아니다. [Google 신고 #576177987](https://issuetracker.google.com/issues/576177987)의 수정 여부와도 구분한다.

## 1. 먼저 구분할 두 ZIP

| 파일 | 용도 | 주의 |
| --- | --- | --- |
| 앱 빌더의 배포 → 다운로드 ZIP | 프롬프트로 수정한 최신 화면 소스 | 확인한 내보내기 파일은 로컬 실행용이었다. Dockerfile, 운영 화면 제공, 실제 Agent 서버가 모두 들어 있다고 가정하지 않는다. |
| 본인 앱의 검증된 배포 ZIP/폴더 | Cloud Run에서 실행할 기준 원본 | 이미 성공한 본인 배포본의 Dockerfile·backend·manifest·lockfile·Agent 연결을 유지한다. 다른 교육생의 ID가 든 ZIP을 그대로 사용하지 않는다. |

**이번 반복 실습의 준비물은 두 가지다.** 최신 앱 빌더 ZIP과, 강사가 제공한 본인용 검증 ZIP 또는 본인의 Cloud Shell에 이미 보관한 성공 배포 폴더다. 처음 배포하는 교육생은 본인의 Agent 연결이 확인된 배포 원본부터 준비한다. 준비물이 없으면 강사에게 본인용 원본을 받아야 한다. 다운로드 ZIP 하나만으로 전체 Agent 기능의 배포가 완성되는 절차는 아니다. 아래 8절에 기본 버튼의 실패 ZIP을 보정했던 절차도 별도로 기록했다.

실제 확인한 로컬 내보내기 backend는 기본적으로 `127.0.0.1:5000`과 `/api-proxy`를 사용했다. 반면 수업에서 검증한 별도 서버는 `PORT`/`0.0.0.0`, 화면 정적 파일, `/api/agent`를 처리했다. 따라서 **로컬 ZIP의 backend로 검증된 서버를 덮어쓰면 안 된다.** [Cloud Run 실행 조건](https://docs.cloud.google.com/run/docs/container-contract)

## 2. 앱 빌더에서 미리보기 확인과 ZIP 다운로드

1. 교육생 본인의 회사 계정·프로젝트·저장 앱을 연다. 별도 Google AI Studio 사이트와 구분한다.
2. 프롬프트로 화면에 `배포 확인: day4-01`을 추가한다. 이번 첫 반복은 기존 패키지만 쓰는 문구·화면 수정으로 한정한다. 기존 Agent 연결 주소·API 경로·인증 방식은 유지하도록 요청한다.
3. 미리보기에서 표식, 더미 S/N 조회, 같은 장비 후속 질문, 새 대화를 확인한다. 실제 Agent 완료 응답인지도 확인하고 실패는 기록한다.
4. 자동저장/체크포인트 완료 후 **배포 → 다운로드**로 ZIP을 받는다. 로컬 파일 이름을 `app-update.zip`으로 정리한다.
5. 원본 ZIP은 보관한다. 미리보기 성공은 컨테이너 빌드·배포 성공을 뜻하지 않는다.

## 3. Cloud Shell에 업로드하고 본인 프로젝트 확인

Google Cloud 콘솔 상단의 Cloud Shell 아이콘을 누른다. 터미널의 **더보기(⋮) → 업로드**에서 `app-update.zip`을 올린다. 최초 실습이면 본인용 검증 배포 ZIP도 올린다. 업로드 위치는 홈 디렉터리다. 아래 명령은 Windows PowerShell이 아니라 **Cloud Shell의 Bash**에 붙여 넣는다. [파일 업로드 안내](https://docs.cloud.google.com/shell/docs/uploading-and-downloading-files)

아래 네 값을 본인 값으로 바꾼다. 서비스 이름은 영문 소문자·숫자·하이픈으로 정하고, 반복 배포에서도 같은 이름을 사용한다. 실습 중 기존 운영 서비스를 지우지 않는다.

```bash
set -euo pipefail
PROJECT_ID="본인-프로젝트-ID"
REGION="us-west1"
SERVICE_NAME="product-history-helper"
AR_REPOSITORY="training-apps"

gcloud auth list --filter=status:ACTIVE --format='value(account)'
gcloud config set project "$PROJECT_ID"
gcloud config get-value project
```

표시된 계정·프로젝트가 다르면 여기서 바로잡는다. Cloud Shell 승인 창이 나오면 본인 계정으로 승인한다. 비밀번호나 인증번호를 다른 사람에게 전달하지 않는다. 첫 줄은 명령 오류나 필수 변수 누락 시 진행을 멈추는 설정이다. 오류가 나면 다음 블록을 실행하지 말고 원인을 해결한다. 터미널이 새로 열렸다면 이 절의 변수부터 다시 설정한다.

**기존 서비스가 있는 경우에만** 다음으로 실행 서비스 계정을 확인한다.

```bash
RUNTIME_SA="$(gcloud run services describe "$SERVICE_NAME" \
  --project="$PROJECT_ID" --region="$REGION" \
  --format='value(spec.template.spec.serviceAccountName)')"
printf '앱 실행 계정: %s\n' "$RUNTIME_SA"
```

처음 만드는 서비스라면 위 조회를 실행하는 대신 강사가 승인한 실행 서비스 계정 이메일을 입력한다.

```bash
RUNTIME_SA="본인용-실행계정@본인-프로젝트-ID.iam.gserviceaccount.com"
```

`RUNTIME_SA`가 비어 있거나 조회가 실패했다면 여기서 멈춘다. 임의의 계정을 대신 넣거나 실행 계정 설정을 생략하지 않는다. 실제 Agent 호출 권한이 확인된 계정이어야 한다.

**Agent 연결 확인표:** 본인의 Agent 프로젝트 번호·Agent 리전·Runtime ID를 적고 배포 원본과 대조한다. 앱 저장 ID와 Agent Designer 편집 ID는 Runtime ID가 아니다. 검증 서버에 이 값들이 상수로 들어간 예제도 있으므로, 환경변수만 바꾸면 자동 변경된다고 가정하지 않는다. 다른 교육생의 서버 URL을 호출한 결과를 본인 Agent 성공으로 기록하지 않는다.

## 4. API·결제·권한·이미지 저장소 준비

결제 연결 상태는 콘솔 결제 화면에서 확인한다. 필요한 API는 다음과 같다. 이미 활성화돼 있으면 같은 명령을 다시 실행해도 된다.

```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com storage.googleapis.com \
  --project="$PROJECT_ID"

# 실제 Agent를 호출하는 앱에만 필요
gcloud services enable aiplatform.googleapis.com --project="$PROJECT_ID"

gcloud builds get-default-service-account \
  --project="$PROJECT_ID" --region="$REGION"

gcloud artifacts repositories list --project="$PROJECT_ID" \
  --location="$REGION" --format='table(name,format)'
```

목록에 위에서 정한 `training-apps` Docker 저장소가 **없을 때만** 만든다. 이미 있으면 생성 명령은 건너뛴다.

```bash
gcloud artifacts repositories create "$AR_REPOSITORY" \
  --project="$PROJECT_ID" --location="$REGION" \
  --repository-format=docker --description="Training application images"
```

`Permission denied`는 npm 설치 오류와 다르다. 다음 세 주체를 구분해 관리자에게 확인한다. Owner/Editor를 일괄 부여하는 방식으로 해결하지 않는다.

| 주체 | 확인할 권한 |
| --- | --- |
| 교육생 배포자 | Cloud Build 작업 제출, Cloud Run 배포, 이미지 읽기, 실행 서비스 계정 사용. 공개 접근 변경에는 별도 IAM 정책 변경 권한이 필요할 수 있음 |
| 위 명령으로 확인한 빌드 서비스 계정 | 소스 읽기, 해당 저장소에 이미지 쓰기, 로그 기록. 기본 계정 이름을 추측하지 않음 |
| 앱 실행 서비스 계정 | 본인 Agent 실행에 필요한 권한. 브라우저 사용자 로그인이나 API 활성화만으로 대체되지 않음 |

처음 만드는 전용 실행 계정을 관리해야 할 때만 IAM API와 계정 생성 절차를 추가한다. 서비스 계정 키 JSON을 ZIP·화면 코드에 넣지 않는다. 기존 검증 서버의 ADC 인증을 유지한다. [기본 빌드 계정 안내](https://docs.cloud.google.com/build/docs/cloud-build-service-account-updates)

## 5. 최신 화면을 검증된 배포 폴더에 반영

최초 한 번은 본인용 검증 배포 ZIP을 별도 폴더에 푼다. 예시 파일 이름은 `verified-deploy.zip`이다. 이미 성공한 배포 폴더가 있으면 새로 만들지 말고 그 폴더 경로를 사용한다.

```bash
DEPLOY_DIR="$HOME/day4-verified-deploy"
# 이미 성공한 폴더가 다른 곳에 있으면 위 경로를 그 폴더로 바꾼다.
if [[ -e "$DEPLOY_DIR" ]]; then
  printf '기존 배포 폴더를 사용합니다: %s\n' "$DEPLOY_DIR"
else
  if [[ ! -s "$HOME/verified-deploy.zip" ]]; then
    echo "본인용 verified-deploy.zip이 없습니다. 강사에게 받은 뒤 다시 진행하세요." >&2
    exit 1
  fi
  mkdir "$DEPLOY_DIR"
  unzip "$HOME/verified-deploy.zip" -d "$DEPLOY_DIR"
fi

EXPORT_DIR="$(mktemp -d "$HOME/day4-export-XXXXXX")"
unzip "$HOME/app-update.zip" -d "$EXPORT_DIR"
find "$EXPORT_DIR" -maxdepth 3 -name package.json -print
find "$DEPLOY_DIR" -maxdepth 3 -name Dockerfile -print
```

ZIP에 상위 폴더가 한 겹 더 있으면 `EXPORT_DIR`/`DEPLOY_DIR`를 **frontend·backend가 바로 보이는 폴더**로 바꾼다. 다음 조건을 확인한 후에만 복사한다.

```bash
if [[ ! -f "$EXPORT_DIR/frontend/package.json" || \
      ! -f "$DEPLOY_DIR/Dockerfile" || \
      ! -f "$DEPLOY_DIR/frontend/package.json" || \
      ! -f "$DEPLOY_DIR/backend/package.json" ]]; then
  echo "폴더 구조가 다릅니다. 경로와 본인용 검증 원본을 확인한 뒤 진행하세요." >&2
  exit 1
fi
for config_file in vite.config.ts vertex-ai-proxy-interceptor.js; do
  if [[ -f "$EXPORT_DIR/frontend/$config_file" && \
        ! -f "$DEPLOY_DIR/frontend/$config_file" ]]; then
    echo "검증 원본에 $config_file 파일이 없습니다. 복사 전에 강사에게 확인하세요." >&2
    exit 1
  fi
done
echo "폴더 구조 확인 완료"
```

복사 전 배포 원본을 백업한다. 다음은 **기존 의존성 안에서 수정한 화면 파일만 반영**하는 명령이다. 삭제 옵션은 쓰지 않는다. backend·Dockerfile·manifest·lockfile과 검증된 Vite·프록시 설정, 환경설정 파일은 유지한다.

```bash
cp -a "$DEPLOY_DIR" "${DEPLOY_DIR}-backup-$(date -u +%Y%m%d-%H%M%S)"
rsync -a \
  --exclude='package.json' --exclude='package-lock.json' \
  --exclude='node_modules' --exclude='dist' \
  --exclude='.env*' --exclude='vite.config.ts' \
  --exclude='vertex-ai-proxy-interceptor.js' \
  "$EXPORT_DIR/frontend/" "$DEPLOY_DIR/frontend/"
cd "$DEPLOY_DIR"
```

새 패키지를 추가한 프롬프트 수정은 이 단순 복사의 범위를 벗어난다. 새 import를 기존 package.json이 제공하는지 확인하고 필요한 **명시적 버전과 대응 lockfile**을 갱신한다. 다운로드본의 `latest` manifest만 덮거나 lockfile을 삭제해서 맞추지 않는다. 파일 삭제·이름 변경이 있으면 남은 예전 파일도 별도로 검토한다.

내보낼 때 생성되는 프록시 헤더 값은 backend 설정과 짝을 이룬다. 새 ZIP의 `vertex-ai-proxy-interceptor.js`만 복사하면 기존 backend와 헤더가 달라질 수 있어 위 명령에서 제외했다. `vite.config.ts`도 로컬 개발 프록시 설정을 담을 수 있으므로 검증 원본을 유지한다. 화면 코드가 다른 파일 이름이나 새 연결 방식을 요구하면 그대로 복사하지 말고 강사와 함께 연결 구성을 확인한다.

**중요:** 화면이 `/api/agent`를 호출한다면 배포 backend에 해당 경로가 있어야 한다. 미리보기에서 외부 서버 URL을 사용했다면 배포본도 본인의 올바른 서버를 호출하는지 확인하고, 필요한 경우 그 서버에 새 배포 URL의 정확한 출처를 허용한다. 전체 출처 허용이나 인증 제거로 해결하지 않는다. 이 연결이 준비되지 않았으면 화면 배포와 실제 Agent 검증을 구분한다.

## 6. gcloud로 빌드하고 같은 서비스에 배포

먼저 Dockerfile의 Node 이미지와 설치 명령, 그 명령이 읽는 lockfile을 확인한다. 수업 검증본에는 frontend/backend 개별 lockfile을 쓰는 형태와 루트 workspace lockfile을 쓰는 형태가 있었다. **서로 다른 구조의 lockfile을 섞지 않는다.** 이미 검증된 파일을 사용하면 8절의 workspace 변환을 추가로 적용하지 않는다.

```bash
grep -nE '^(FROM|COPY|RUN|CMD)' Dockerfile
find . -maxdepth 2 -name package-lock.json -not -path './node_modules/*' -print
gcloud meta list-files-for-upload
```

업로드 목록에 Dockerfile, frontend/backend manifest와 해당 Dockerfile이 읽는 lockfile이 포함되는지 확인한다. `node_modules`, 서비스 계정 키 JSON, 불필요한 비밀 파일이 보이면 멈추고 `.gcloudignore`를 수정한 뒤 다시 확인한다. `.gcloudignore`는 소스 업로드 목록을, `.dockerignore`는 Docker 빌드에 들어갈 파일을 제어한다. 필요한 파일이 빠져 있어도 그대로 진행하지 않는다.

```bash
RELEASE_TAG="$(date -u +%Y%m%d-%H%M%S)"
IMAGE_URI="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPOSITORY/$SERVICE_NAME:$RELEASE_TAG"
if ! gcloud builds submit . --project="$PROJECT_ID" \
    --region="$REGION" --tag="$IMAGE_URI"; then
  echo "빌드가 실패했습니다. 배포하지 말고 빌드 ID와 첫 오류를 확인하세요." >&2
  exit 1
fi
```

**Cloud Build가 SUCCESS일 때만** 다음으로 진행한다. 실패했다면 빌드 ID와 첫 오류를 기록한다. 기존 이미지가 정상이라는 이유로 이번 빌드도 성공했다고 판단하지 않는다.

다음은 수업에서 공개를 허용한 **교육용 더미 앱**의 예다. `--allow-unauthenticated`는 URL을 아는 사람이 이용할 수 있는 설정이며 Agent 호출 비용이 발생할 수 있다. 사내 실제 자료를 다루는 앱에는 이 공개 설정을 그대로 적용하지 않는다. 비공개 서비스는 공개 옵션을 제외하고 인증 경로를 별도로 확인한다. 기존 서비스가 이미 공개된 경우에는 옵션을 빼는 것만으로 비공개로 전환되지 않는다.

```bash
if [[ -z "${RUNTIME_SA:-}" ]]; then
  echo "RUNTIME_SA가 비었습니다. 3절에서 실행 계정을 확인한 뒤 진행하세요." >&2
  exit 1
fi
gcloud run deploy "$SERVICE_NAME" \
  --project="$PROJECT_ID" --region="$REGION" --image="$IMAGE_URI" \
  --service-account="$RUNTIME_SA" --allow-unauthenticated \
  --min-instances=0 --max-instances=1 --concurrency=10 \
  --cpu=1 --memory=512Mi --timeout=180
```

서비스 이름·리전·실행 서비스 계정을 재확인하고 실행한다. 기존 앱에 필요한 환경변수, Secret 참조, 네트워크 설정을 지우지 않는다. 처음 만들 때는 검증 원본에 필요한 설정을 등록한다. 자동 생성 서버의 환경변수 이름과 별도 검증 서버의 Agent 상수는 다를 수 있으므로, 실제 코드가 읽지 않는 변수만 추가해 연결이 바뀌었다고 판단하지 않는다.

## 7. 공개 URL·수정 반영·Agent·응답 시간 확인

```bash
gcloud run services describe "$SERVICE_NAME" \
  --project="$PROJECT_ID" --region="$REGION" \
  --format='yaml(status.conditions,status.latestReadyRevisionName,status.traffic,status.url)'

APP_URL="$(gcloud run services describe "$SERVICE_NAME" \
  --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)')"
printf '실행 URL: %s\n' "$APP_URL"
curl -sS -o /dev/null -w 'HTTP %{http_code}; document %{time_total}s\n' "$APP_URL/"
```

1. Ready=True, 새 리비전, 그 리비전으로 전달되는 트래픽을 확인한다. 이전 리비전만 실행 중이라면 업데이트 성공이 아니다.
2. URL을 브라우저로 열고 필요하면 강력 새로고침해 `day4-01`을 확인한다. React 문구는 JavaScript 번들에 포함될 수 있으므로 HTML 문자열 검색만으로 판정하지 않는다.
3. 본인의 Agent 카드, 실제 질문의 완료 응답, 원본 행과 답, 후속 질문, 새 대화를 확인한다. HTTP 200 안의 WORKING이나 오류도 정상 완료로 취급하지 않는다.
4. 같은 질문을 3회 이상 실행하고 첫 요청과 이어진 요청, 완료 시간, 실패, Agent 상태를 나누어 기록한다. 위 curl은 문서 조회 시간이며 Agent 답변 시간이 아니다.
5. 앱 빌더로 돌아가 프롬프트로 `day4-02`로 바꾼다. ZIP 다운로드 → 업로드 → 5~7절을 반복한다. **같은 서비스 URL**에 수정 화면이 나오고 Agent 시험도 통과해야 이번 대체 절차의 반복 검증이 성공한 것이다.

변경할 때마다 ZIP 이름·시각·화면 표식·이미지 태그·빌드 ID·리비전·질문과 결과를 남긴다. 앱 빌더가 Cloud Shell의 수정 내용을 자동으로 가져오는 것은 아니다. 기본 버튼을 다시 사용하면 다른 생성 설정으로 덮어쓸 수 있으므로 당분간 두 배포 절차를 혼용하지 않는다.

## 8. 선택 실습: Node 20 workspace 실패 ZIP 보정

이 절은 **기본 Cloud Run 버튼이 실제 빌드에 전달한 ZIP**에 전날 Hello World에서 성공한 수정을 재현하는 선택 실습이다. 1~7절의 검증 원본을 이미 갖고 있다면 진행하지 않는다. 일반 다운로드 ZIP에 없는 Dockerfile이나 운영 backend를 자동으로 만들어 주는 절차가 아니다.

Cloud Build의 실패 상세 화면에서 본인의 빌드 ID와 빌드 리전을 확인한다. 다음은 해당 빌드의 소스를 확인하는 예다. 마지막 실패 ZIP을 성공 원본과 혼동하지 않는다. 빌드 리전과 서비스 리전이 다른 경우에는 아래 명령에 실제 빌드 리전을 사용한다.

```bash
BUILD_ID="본인의-실패-빌드-ID"
gcloud builds describe "$BUILD_ID" --project="$PROJECT_ID" \
  --region="$REGION" --format='yaml(status,source.storageSource)'
```

표시된 bucket과 object를 사용해 `gcloud storage cp "gs://BUCKET/OBJECT" "$HOME/build-source.zip"`을 실행하고 새로운 전용 폴더에 압축을 푼다. 소스가 tar.gz 형식이면 unzip 대신 tar를 사용한다. 원본 압축 파일을 보관하고 루트 Dockerfile·루트 package.json·frontend/package.json·backend/package.json을 확인한다. 구조가 다르거나 로컬 실행용 서버라면 이 절을 적용하지 말고 강사에게 확인한다.

전날 확인한 두 단계 Node 20 템플릿과 일치할 때만 Cloud Shell Editor에서 Dockerfile을 수정한다. 두 FROM을 모두 `node:22.22.0-slim`으로 바꾸고 `RUN npm install`을 다음으로 교체한다. 다른 Google 프록시 설정, 화면, Agent 코드는 유지한다.

```dockerfile
RUN npm install --global npm@11.12.1
RUN node --version && npm --version
RUN npm ci --include=dev --no-audit --no-fund
```

아직 lockfile이 없으면 이 상태로 빌드하지 않는다. 대상 폴더의 루트에서 고정한 Node/npm으로 lockfile을 생성한다. 다음 컨테이너 방식은 Cloud Shell 호스트의 Node 버전 차이를 피하기 위한 예이며, 이 교안 작성 중 새로 클라우드에서 실행한 검증 결과는 아니다.

```bash
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$PWD:/app" -w /app node:22.22.0-slim \
  sh -c 'npx --yes npm@11.12.1 install --package-lock-only --ignore-scripts --no-audit --no-fund'
if [[ ! -s package-lock.json ]]; then
  echo "루트 lockfile 생성에 실패했습니다. 빌드하지 말고 오류를 확인하세요." >&2
  exit 1
fi
echo "루트 lockfile 생성 확인"
```

Dockerfile의 첫 설치 전에 루트 lockfile과 두 workspace의 manifest가 복사되어야 한다. 원래 템플릿의 `COPY package*.json ./`는 루트 lockfile도 포함한다.

```dockerfile
COPY package*.json ./
COPY frontend/package.json ./frontend/
COPY backend/package.json ./backend/
# 이 뒤에서 위의 npm 버전 고정과 npm ci를 실행
```

6~7절의 실제 빌드·URL·Agent 검증을 통과한 파일만 본인의 검증 원본으로 보관한다. Node/npm을 함께 바꾼 실험이며, lockfile만 만들면 모든 오류가 해결된다는 뜻은 아니다.

## 9. 막혔을 때 확인할 항목

| 증상 | 다음 확인 |
| --- | --- |
| Dockerfile 없음 | 로컬 실행용 ZIP만 사용했는지 확인. 본인용 검증 원본·실제 Cloud Run 빌드 ZIP과 구분 |
| edgesOut | 실제 Dockerfile의 Node/npm, workspace 또는 개별 설치 구조, lockfile 복사 시점 |
| npm ci 불일치 | package.json과 lockfile이 같은 버전인지, latest manifest만 복사했는지 확인 |
| 이미지 업로드 실패 | Artifact Registry 저장 위치·리전·빌드 서비스 계정의 쓰기 권한 |
| PORT·시작 실패 | 서버가 0.0.0.0과 PORT에서 기다리는지, 로컬용 127.0.0.1:5000인지 확인 |
| URL에서 404·이전 화면 | 정적 dist 포함과 제공, 새 리비전과 트래픽, 브라우저 캐시 |
| 화면 정상·Agent 실패 | 본인의 Runtime ID, 실행 서비스 계정, API 경로, 외부 URL/CORS, 실제 Task 상태 |
| 429 | 모델·Agent의 사용 한도. 빌드 성공이나 공개 접근과 별도로 기록 |
| 공개 설정 권한 오류 | 조직 정책과 IAM 변경 권한. 인증을 제거하는 것으로 모두 해결하려 하지 않음 |

참고: [Cloud Build submit](https://docs.cloud.google.com/sdk/gcloud/reference/builds/submit), [Cloud Run 이미지 배포](https://docs.cloud.google.com/run/docs/deploying), [npm ci](https://docs.npmjs.com/cli/v11/commands/npm-ci/). 이 추가 자료는 기존 성공 실험과 소스 대조, 공식 CLI 확인을 바탕으로 작성했다. 교육생 전원의 새 ZIP을 이번에 실행 검증한 기록은 아니다.
