# Google AI Agent 요청문 · 텍스트 앱 복원 후 npm 설치 실패

[상세 교안](../docs/deployment/text-sharing-build-failures.md) · [3일차](../lessons/day03.md)

아래 내용을 **자기 앱의 편집 대화**에 복사합니다. 실제 비밀값이나 사내 자료를 공개 댓글에 넣지 마세요. AI에게 파일 변경과 실행 근거를 요구하고, 수정 권한이 없는 시스템 영역은 미해결로 남깁니다.

```text
현재 앱의 Cloud Run 배포가 아래 단계에서 실패합니다. 설명만 하지 말고, 이 프로젝트에서 수정 가능한 파일을 실제로 수정해 주세요.

오류:
Step 6/25 : RUN npm install
npm error Cannot read properties of null (reading 'edgesOut')
환경: node:20-slim, npm 10.8.2, 루트와 frontend/backend의 package.json을 복사한 후 루트 npm install 실행.

우리는 Cloud Build 시스템이나 자동 생성 배포 설정을 직접 편집할 수 없으므로, 당신이 접근 가능한 프로젝트 파일과 배포 설정 범위에서 해결해야 합니다.

1. 먼저 루트 package.json, frontend/package.json, backend/package.json, 기존 lockfile, Dockerfile 및 실제 배포 파일 생성 경로를 확인하세요. root workspaces가 frontend/backend를 사용하는지, workspace 간 로컬 의존성이 있는지 확인하세요. 업무 UI·자료·조회 규칙·모델·API 키·인증 경로는 바꾸지 마세요.

2. 이번 로그는 npm 업그레이드 실패가 아니라 의존성 설치 중 내부 오류입니다. 새 버전 알림만 보고 npm 12로 무조건 올리지 마세요. 현재 Node/npm 버전과 패키지 engines/peerDependencies를 확인하세요. npm 10.8.2에서 lockfile 생성이 같은 오류로 실패하면, 생성 작업만 호환되는 npm 11 버전에서 수행할 수 있는지 확인하고 실제 사용 버전을 기록하세요. 환경을 변경할 수 없다면 변경했다고 말하지 마세요.

3. 이 학생 프로젝트 자신의 package.json들을 기준으로 실제 npm 명령을 실행해 완전한 package-lock.json을 생성하세요. 예: npm install --package-lock-only --ignore-scripts --no-audit --no-fund. lockfile의 resolved·integrity·전이 의존성을 손으로 지어내거나 일부만 작성하지 마세요. 첨부된 예제 lockfile은 별도 프로젝트 참고용이며, 현재 manifest와 일치하는지 확인 없이 덮어쓰지 마세요.

4. 루트 workspaces 구조를 유지한다면 루트 package-lock.json 하나와 두 하위 package.json의 정합성을 유지하세요. 루트 설치와 독립 하위 설치의 lockfile을 혼용하지 마세요. latest 의존성의 이번 실제 해석 버전은 lockfile에 고정하고, 필요할 때만 검증된 직접 의존성 버전으로 manifest를 조정하세요. 정상 lockfile을 배포 때 다시 생성하거나 npm update로 덮어쓰지 마세요. 패키지명만 같다는 이유로 다른 프로젝트의 lockfile을 사용하지 마세요.

5. 수정 가능한 배포 Dockerfile이 있다면 설치 전에 루트 package.json과 package-lock.json, frontend/package.json, backend/package.json을 올바른 위치에 COPY하고, 빌드 단계의 RUN npm install을 RUN npm ci --include=dev --no-audit --no-fund로 바꾸세요. Vite 빌드 전에 devDependencies를 제외하지 마세요. 기존 다중 단계 빌드, 산출물 경로, backend/server.js 실행, PORT와 0.0.0.0 바인딩은 실제 코드에 맞춰 유지하세요. Vite 등이 요구하는 Node 버전을 확인하고, 이미지 수정이 가능하면 호환되는 Node 22 버전을 사용하세요.

6. Dockerfile이 플랫폼에서 자동 생성되어 편집할 수 없다면, 해당 제약을 명시하세요. 프로젝트의 lockfile이 내보내기 ZIP과 실제 Cloud Build 소스에 포함되는지 확인하고, 고정된 npm install 경로에서도 그 lockfile을 사용해 재현되는지 가능한 범위에서 검증하세요. 소스 화면에 파일만 생긴 것을 배포에 적용된 것으로 보고하지 마세요. 자동 생성 시스템이 lockfile을 제외하거나 설치 명령을 강제한다면, 그 지점을 해결되지 않은 플랫폼 제약으로 보고하세요.

7. 검증 가능한 환경에서 다음을 실행하고 실제 종료 코드와 로그를 보여 주세요.
- node --version 및 npm --version
- npm ci --include=dev --no-audit --no-fund
- npm run build --workspace=frontend (실제 workspaces 구성에 맞춰 조정)
- 기존 백엔드의 기동 확인. 로컬 .env.local이 Cloud Run에 없을 수 있으므로 기존 설정 방식을 확인하되 키나 비밀값을 코드에 넣거나 출력하지 마세요.
--force나 --legacy-peer-deps를 기본 해결책으로 사용하지 마세요. 충돌이 있으면 정확한 패키지와 호환 버전을 먼저 확인하세요.

8. 변경 파일 목록, lockfile 생성에 사용한 Node/npm 버전, 설치·프런트 빌드·백엔드 기동·Cloud Build 재배포의 성공/실패/미실행 상태를 각각 보고하세요. 실제 배포 소스 ZIP에 package-lock.json이 포함됐는지도 확인하세요. 명령 실행이나 배포 도구가 없으면 미실행으로 명시하고, 검증 성공이나 배포 성공을 추정해서 쓰지 마세요.

참고: 강사 보관 제품이력 예제에서는 npm 11.12.1로 lockfileVersion 3을 생성했고, Windows의 Node 22.22.0 + npm 10.8.2로 npm ci 및 Vite 빌드를 확인했습니다. 이 결과는 학생 프로젝트의 동일 성공이나 Linux Cloud Build 성공을 보장하지 않습니다.
```

## 텍스트 공유 복원에 추가할 요청

```text
이번 앱은 여러 파일을 BEGIN FILE / END FILE 구분자로 묶은 전체코드 텍스트를 참고해 복원했습니다.
먼저 전달 파일 목록과 현재 프로젝트 파일을 대조하고, 구분자·설명문을 코드 파일에 넣지 않았는지 확인하세요.
긴 파일이나 package.json 내용을 요약·생략하지 마세요. 새로 바꾼 패키지와 원본의 차이를 보고하세요.
lockfile·Dockerfile이 전달 자료에 없으면 누락과 플랫폼 자동 생성 여부를 구분하세요.
.env.local 등의 실제 값은 공개 소스에 복사하지 말고 새 프로젝트의 환경 설정으로 별도 관리하세요.
파일 복원 완료, 설치 성공, 프런트 빌드 성공, 서버 기동, Cloud Build, 서비스 응답을 각각 구분해서 보고하세요.
```
