# 4일차: ZIP 다운로드 → 명령어 생성 → 업로드·배포

**앱 빌더에서 수정하고, ZIP을 받은 뒤, 같은 명령으로 다시 올립니다.** 강사가 처음 한 번 본인용 배포 환경과 PC의 Google Cloud CLI 설치·로그인을 준비하면 아래 3단계만 반복합니다. 기존 서비스·Agent 연결·빌드 설정은 유지합니다.

## 1. ZIP 파일 다운로드

앱 빌더에서 프롬프트로 수정 → 미리보기 확인 → 저장 완료 → **배포 → 다운로드**를 선택합니다. PC에서 ZIP을 `app-update.zip` 같은 **고정된 이름·위치**로 저장하세요. 다음 수정본도 같은 파일을 덮어쓰면 됩니다.

## 2. 명령어 생성 — 처음 한 번

아래 템플릿의 설정을 채워 AI에게 전달하세요. 설정값은 강사가 확인해 준 **본인의 설정 카드**를 사용합니다. 생성된 명령 블록을 저장하면 다음부터 다시 생성할 필요가 없습니다. ZIP 경로나 프로젝트·서비스가 바뀔 때만 새로 만듭니다.

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

생성된 최종 명령에는 실제 값이 들어 있어야 하며, `본인-프로젝트-ID`, `<입력>` 같은 빈칸을 남기면 안 됩니다. [템플릿 별도 파일](../../prompts/zip-deploy-command-template.md)도 제공됩니다.

## 3. 명령어로 업로드·배포 — 수정할 때마다

**PC의 Windows PowerShell**을 열고, 2단계에서 저장한 **최종 명령 블록 전체를 한 번에** 실행하세요. 브라우저의 Cloud Shell 터미널에 붙여 넣지 않습니다.

명령은 **PC ZIP → Cloud Shell 복사 → 화면 반영 → 빌드 → 기존 Cloud Run 업데이트 → URL 출력**까지 진행합니다. 업로드나 빌드가 실패하면 다음 배포를 진행하지 않습니다. 완료되면 출력된 URL에서 새 문구·기능과 실제 Agent 응답을 확인하세요.

**다음 수정도 동일합니다: 프롬프트 수정 → 미리보기 → 같은 ZIP 파일로 저장 → 저장한 명령 다시 실행.** `day4-01`을 `day4-02`로 바꿔 올리면 변경 반영을 쉽게 확인할 수 있습니다.

---

강사용 최초 준비·오류 대응은 [별도 참고 자료](app-builder-zip-gcloud-reference.md)에 두었습니다. 이 절차는 기존에 검증된 본인 배포 원본을 업데이트하는 템플릿이며, 첫 환경 구축이나 앱 빌더 기본 배포 버튼의 오류 수정 완료를 뜻하지 않습니다.
