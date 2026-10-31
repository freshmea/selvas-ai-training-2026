# ZIP 업로드·배포 명령 생성 템플릿

아래 입력란을 본인 설정으로 채워 AI에게 전달한다. 생성된 명령은 **내 PC의 Windows PowerShell**에서 실행한다. Cloud Shell의 Bash에 붙이는 명령이 아니다. 강사가 처음 한 번 PC의 Google Cloud CLI 로그인과 본인용 배포 원본·기존 서비스·이미지 저장소를 준비한다.

```text
아래 설정으로 ZIP 업로드와 기존 Cloud Run 서비스 업데이트를 한 번에 수행하는
Windows PowerShell 명령 블록 하나를 만들어 주세요.

[내 설정 — 강사가 확인한 값을 입력]
PC ZIP 전체 경로: <예: C:\Users\내이름\Downloads\app-update.zip>
Google Cloud 프로젝트 ID: <입력>
Cloud Run 리전: <입력>
기존 Cloud Run 서비스 이름: <입력>
Artifact Registry Docker 저장소 이름: <입력>
Cloud Shell 홈 아래의 검증 배포 폴더: <예: hello-world-fix-20261021>

[명령 생성 규칙]
- 빈 항목이나 예시만 있으면 실제 값을 추측하지 말고 필요한 값만 먼저 물어보세요.
- PowerShell 블록 하나만 출력하세요. 모든 설정은 실제 값으로 명령 안에 직접 넣으세요.
  다른 터미널에서 설정한 PROJECT_ID 같은 변수에 의존하지 마세요.
- gcloud cloud-shell scp로 PC ZIP을 cloudshell:~/app-update.zip에 업로드하세요.
  로컬 파일에는 localhost: 접두사를 쓰고, 공백·한글·괄호가 있는 경로도 인용하세요.
- 업로드 다음 줄에 if ($LASTEXITCODE -ne 0) { throw 'ZIP 업로드 실패' }를 넣으세요.
- 다음은 gcloud cloud-shell ssh --authorize-session으로 원격 배포를 실행하세요.
  scp와 ssh 모두 --project에 위 프로젝트 ID를 명시하세요.
- ssh의 --command에는 다음 순서를 하나의 문자열로 넣으세요.
  curl -fsSL로 아래 고정 버전 스크립트를 /tmp/training-zip-deploy.sh에 저장한 뒤,
  && bash /tmp/training-zip-deploy.sh로 실행하세요.
  https://raw.githubusercontent.com/freshmea/selvas-ai-training-2026/be5626b4aa4f70fb7ab7978a9ce4910cbeaf80d5/scripts/deploy-app-builder-zip.sh
- 스크립트 인수는 --project <프로젝트ID> --region <리전> --service <서비스이름>
  --repository <저장소이름> --deploy-dir <검증폴더> --zip app-update.zip 입니다.
  검증폴더는 Cloud Shell 홈 기준 상대 경로입니다. 원격 Bash에서도 각 값을 안전하게 인용하세요.
- PowerShell이 원격 문자열의 $변수 등을 먼저 해석하지 않도록 인용하세요.
- 마지막에 if ($LASTEXITCODE -ne 0) { throw '배포 실패: 위 오류를 확인하세요.' }를 넣으세요.
- 인증을 제거하거나 공개 설정·IAM·Agent ID·서버·실행 계정을 바꾸지 마세요.
  이 스크립트는 검증된 원본의 화면만 업데이트합니다.
- 같은 PC ZIP 경로와 같은 설정으로 다음 수정본도 올릴 수 있게 만들어 주세요.
```

작동 방식과 강사 준비 항목은 [3단계 실습 안내](../docs/deployment/app-builder-zip-gcloud.md)를 참고한다. API 키·비밀번호·서비스 계정 키는 입력하지 않는다.
