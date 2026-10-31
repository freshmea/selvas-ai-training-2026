# 배포 의존성 참고 파일

2026-10-21 생성. 이 폴더는 앱 전체 소스나 즉시 배포 가능한 프로젝트가 아닙니다.

- [package-lock.json](package-lock.json): 루트 workspace용, lockfileVersion 3.
- [루트 package.json](package.json), [frontend/package.json](frontend/package.json), [backend/package.json](backend/package.json): 이 lockfile을 생성한 기준 manifest.
- [validation.json](validation.json): 실제 실행 환경·명령·확인 한계.
- [Google AI Agent 요청문](../../prompts/fix-npm-install.md): 본인 앱의 실제 파일과 대조해 적용하도록 요청.

기준은 강사 보관 제품이력 예제입니다. 이후 제공된 22파일 전체코드 텍스트에서도 package.json 3개가 이 기준과 JSON 구조상 일치함을 확인했습니다. 다른 교육생이 패키지를 추가·삭제하거나 manifest를 변경했다면 이 lockfile을 그대로 적용하지 말고 해당 프로젝트에서 다시 생성해야 합니다.

## 검증한 범위

Windows의 Node 24.14.0 / npm 11.12.1로 실제 npm 명령을 실행해 생성했습니다. Node 22.22.0 / npm 10.8.2 환경에서도 `npm ci --include=dev`와 보관 프런트 소스의 Vite 빌드를 확인했습니다. 이 폴더에는 프런트 업무 코드나 서버 코드가 없으므로 폴더만 내려받아 앱 빌드를 실행하는 예제가 아닙니다.

Linux Docker / 학생 Cloud Build / 실제 백엔드 기동 / 모델 호출은 검증하지 않았습니다. 시스템 npm은 업그레이드하지 않았습니다. Node/npm·의존성 고정은 설치 재현성을 돕지만 모든 npm 버그나 런타임 오류를 제거하지 않습니다.

전체코드 TXT와 `.env.local`, API 키·토큰, 실제 업무 데이터는 포함하지 않습니다. 폴더째 학생 앱에 덮어쓰지 말고 [상세 교안](../../docs/deployment/text-sharing-build-failures.md)의 파일·설치 구조 대조부터 수행하세요.
