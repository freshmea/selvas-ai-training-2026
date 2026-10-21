# 셀바스헬스케어 AI 실습 교실

Cloud Agent Designer로 기업용 제품 이력 에이전트를 만드는 PBL 교육자료입니다.
비개발자도 **문제 정의 → 작은 실험 → 원천 대조 → 개선 기록** 순서로 참여합니다.

**[노션 교육 홈](https://app.notion.com/p/freshmea/3f9123060ee780ddb01ee56de869e9ea)** · **[전체 자료 ZIP](https://github.com/freshmea/selvas-ai-training-2026/archive/refs/heads/main.zip)** · **[질문 등록](https://github.com/freshmea/selvas-ai-training-2026/issues/new/choose)**

## 처음 오셨나요?

1. [시작 안내](docs/start.md)에서 계정과 준비물을 확인합니다.
2. [5일 학습 로드맵](docs/curriculum.md)을 읽습니다.
3. [1일차 실습](lessons/day01.md)을 열고 [가상 데이터](samples/products.csv)와 [기록지](worksheets/day01-pbl.md)를 내려받습니다.
4. 보충 실습은 [NotebookLM × Google Drive](notebooklm/README.md)에서 시작합니다.

Git 설치 없이 파일을 열어 읽거나 상단 **Code → Download ZIP**으로 내려받을 수 있습니다.
개별 파일은 파일 화면의 다운로드 메뉴를 이용합니다.

## 자료실

| 자료 | 내용 | 상태 |
| --- | --- | --- |
| [교육 안내](docs/start.md) | 계정 준비와 공유 방식 | 이용 가능 |
| [5일 커리큘럼](docs/curriculum.md) | 외부 코칭 5일 × 4시간 | 운영안 |
| [1일차](lessons/day01.md) | 데이터 규칙·Agent 지침·Preview·새 세션 실험 | 이용 가능 |
| [3일차 보충 실습](lessons/day03.md) | 텍스트 앱 공유·npm 설치 실패·배포 재현성 | 이용 가능 |
| [4일차 진행 기록](lessons/day04.md) | Cloud Agent로 교육 전환·배포 문제와 대응·주요 대화·실측·내일 계획 | 2026-10-21 실제 기록 |
| [4일차 베이스라인·질문 기록지](worksheets/day04-baseline-and-questions.md) | 계정별 시작 상태·고정 정답·기능 추가 전후 비교 | 작성용 양식 |
| [앱 빌더 기능 생성 프롬프트](prompts/product-history-from-scratch.md) | 전체 코드 복사 없이 제품이력 조회·문맥·실제 Agent 연결 요구 | 프롬프트 제공·실행 상태 문서 참조 |
| [배포 오류 진단 교안](docs/deployment/text-sharing-build-failures.md) | 사례 분석·AI 수정 요청문·lockfile·검증 기록지 | 이용 가능 |
| [가상 데이터](samples/README.md) | 기본·정제 실습 CSV, 각 24행 | 이용 가능 |
| [NotebookLM](notebooklm/README.md) | 가상 문서 4종, 질문 10개, 갱신 미션 | 이용 가능 |
| [활동지](worksheets/) | PBL 기록지·NotebookLM 활동지·제출 양식 | 이용 가능 |
| 2·5일차 저장소 상세 교안 및 나머지 강의 슬라이드 | 수업 진행에 맞추어 추가 | 작성 예정 |

## 공유 원칙

이 저장소의 제품·정책·연락체계는 교육용 가상 자료입니다. 실제 ERP 원본, 고객정보, 개인 계정 실행 기록은 포함하지 않습니다.
질문과 실습 결과는 가상 번호로 작성하며 실제 업무 결과는 강사가 지정한 내부 공간에 제출합니다.
빈 값과 중복은 추정으로 채우지 않고 원천 확인이 필요한 상태로 기록합니다.
교육자료와 실습 시제품은 실제 회사 환경에서의 운영 완료를 의미하지 않습니다.

자료 기준일: 2026-10-14. 수업 일정과 도구 접근 권한은 강사 안내를 따릅니다.

2026-10-21 추가: 텍스트로 전달한 앱의 파일·의존성·환경 누락을 점검하는 [배포 재현성 자료](docs/deployment/text-sharing-build-failures.md)를 공개했습니다. 텍스트 공유 자체가 반드시 오류를 만든다는 뜻은 아니며, 확인한 사실과 원인 가설을 구분합니다.

2026-10-21 4일차 기록: 남은 교육을 Google Cloud Agent 중심으로 진행하고 공통 베이스라인에서 기능 추가·질문 검증을 시작한다는 오전 안내를 반영했습니다. [진행 기록](lessons/day04.md)은 기존 배포 앱의 성공과 새 앱 빌더의 미완료를 구분합니다. 전원 동일 환경 검증 완료를 의미하지 않습니다.
