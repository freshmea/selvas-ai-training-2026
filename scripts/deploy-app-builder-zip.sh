#!/usr/bin/env bash
# Run in the student's Cloud Shell. Updates an existing, verified deployment.
set -euo pipefail

fail() { printf '중단: %s\n' "$*" >&2; exit 1; }
PROJECT_ID='' REGION='' SERVICE_NAME='' REPOSITORY='' DEPLOY_REL='' ZIP_REL=''
while (($#)); do
  (($# >= 2)) || fail '옵션 값이 빠졌습니다.'
  case "$1" in
    --project) PROJECT_ID="$2" ;;
    --region) REGION="$2" ;;
    --service) SERVICE_NAME="$2" ;;
    --repository) REPOSITORY="$2" ;;
    --deploy-dir) DEPLOY_REL="$2" ;;
    --zip) ZIP_REL="$2" ;;
    *) fail "알 수 없는 옵션: $1" ;;
  esac
  shift 2
done
[[ "$PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,61}[a-z0-9]$ ]] || fail '프로젝트 ID를 확인하세요.'
[[ "$REGION" =~ ^[a-z]+-[a-z]+[0-9]+$ ]] || fail '리전을 확인하세요.'
[[ "$SERVICE_NAME" =~ ^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || fail '서비스 이름을 확인하세요.'
[[ "$REPOSITORY" =~ ^[a-z][a-z0-9-]{0,62}$ ]] || fail '이미지 저장소 이름을 확인하세요.'
[[ -n "$DEPLOY_REL" && -n "$ZIP_REL" ]] || fail '검증 폴더와 ZIP 경로가 필요합니다.'
for program in gcloud python3 flock; do
  command -v "$program" >/dev/null || fail "$program 명령이 없습니다. 강사에게 초기 준비를 요청하세요."
done

# Paths are relative to this student's home. Never accept a shared root directory.
mapfile -t RESOLVED < <(python3 - "$DEPLOY_REL" "$ZIP_REL" <<'PY'
from pathlib import Path
import sys
home = Path.home().resolve()
for raw in sys.argv[1:]:
    p = Path(raw)
    if p.is_absolute():
        raise SystemExit('Cloud Shell 홈 기준의 상대 경로를 입력하세요.')
    p = (home / p).resolve()
    if p == home or not p.is_relative_to(home):
        raise SystemExit('Cloud Shell 홈 안의 개별 폴더/파일만 사용할 수 있습니다.')
    print(p)
PY
)
[[ ${#RESOLVED[@]} -eq 2 ]] || fail '폴더 또는 ZIP 경로가 올바르지 않습니다.'
DEPLOY_DIR="${RESOLVED[0]}" ZIP_PATH="${RESOLVED[1]}"
[[ -d "$DEPLOY_DIR" && -s "$ZIP_PATH" ]] || fail '검증된 배포 폴더 또는 업로드한 ZIP이 없습니다.'
[[ -f "$DEPLOY_DIR/Dockerfile" && -f "$DEPLOY_DIR/frontend/package.json" && -f "$DEPLOY_DIR/backend/package.json" ]] || fail '검증된 배포 원본이 아닙니다. 강사에게 초기 준비를 요청하세요.'
if [[ ! -s "$DEPLOY_DIR/package-lock.json" ]]; then
  [[ -s "$DEPLOY_DIR/frontend/package-lock.json" && -s "$DEPLOY_DIR/backend/package-lock.json" ]] || fail '검증 원본의 lockfile이 없습니다.'
fi
grep -q 'npm ci' "$DEPLOY_DIR/Dockerfile" || fail 'npm ci를 쓰는 검증된 Dockerfile이 필요합니다.'
if grep -Eq '^FROM[[:space:]]+node:20([.-]|[[:space:]]|$)' "$DEPLOY_DIR/Dockerfile"; then
  fail '이전 Node 20 템플릿입니다. 강사에게 빌드 환경 준비를 요청하세요.'
fi

# Serialize deployments within this Cloud Shell; no IAM or runtime settings change.
exec 9>"$HOME/.training-app-deploy.lock"
flock -n 9 || fail '다른 배포가 진행 중입니다. 완료 후 다시 실행하세요.'
gcloud run services describe "$SERVICE_NAME" --project="$PROJECT_ID" --region="$REGION" --format='value(metadata.name)' >/dev/null || fail '기존 서비스 또는 접근 권한을 확인하세요.'
gcloud artifacts repositories describe "$REPOSITORY" --project="$PROJECT_ID" --location="$REGION" >/dev/null || fail '이미지 저장소 또는 접근 권한을 확인하세요.'

# Inspect first, back up the old files, then overlay UI only. No ZIP extractall/delete.
python3 - "$ZIP_PATH" "$DEPLOY_DIR" <<'PY'
from pathlib import Path, PurePosixPath
from zipfile import ZipFile
from datetime import datetime, timezone
import hashlib, json, shutil, stat, sys, uuid

archive, deploy = map(Path, sys.argv[1:])
excluded = {'node_modules', 'dist', '.git', '__pycache__'}
kept = {'package.json', 'package-lock.json', 'npm-shrinkwrap.json', '.npmrc',
        'vite.config.ts', 'vite.config.js', 'vite.config.mts',
        'vertex-ai-proxy-interceptor.js'}
with ZipFile(archive) as z:
    infos = [i for i in z.infolist() if not i.is_dir()]
    if sum(i.file_size for i in infos) > 100 * 1024 * 1024:
        raise SystemExit('중단: ZIP의 압축 해제 크기가 100 MiB를 넘습니다.')
    for i in infos:
        p = PurePosixPath(i.filename)
        if p.is_absolute() or '..' in p.parts or '\\' in i.filename or stat.S_ISLNK(i.external_attr >> 16):
            raise SystemExit('중단: ZIP 안에 허용하지 않는 경로가 있습니다.')
    names = {i.filename for i in infos}
    roots = [str(PurePosixPath(n).parent) for n in names
             if PurePosixPath(n).name == 'index.html'
             and str(PurePosixPath(n).parent / 'package.json') in names]
    roots = [r for r in roots if not (set(PurePosixPath(r).parts) & excluded)]
    if len(roots) != 1:
        raise SystemExit('중단: 화면 소스 폴더를 하나로 찾을 수 없습니다. 강사에게 ZIP을 보여주세요.')
    root = PurePosixPath(roots[0])
    target = (deploy / 'frontend').resolve()
    if not target.is_relative_to(deploy.resolve()):
        raise SystemExit('중단: 화면 폴더가 검증 원본 밖을 가리킵니다.')
    pending = []
    for i in infos:
        p = PurePosixPath(i.filename)
        if not p.is_relative_to(root):
            continue
        rel = p.relative_to(root)
        if set(rel.parts) & excluded or any(part.startswith('.env') for part in rel.parts):
            continue
        if len(rel.parts) == 1 and rel.name in kept:
            continue
        dest = target.joinpath(*rel.parts)
        if not dest.resolve().is_relative_to(target) or dest.is_dir():
            raise SystemExit('중단: 기존 화면 폴더에 경로 충돌이 있습니다.')
        pending.append((rel, dest, z.read(i)))
    if not pending:
        raise SystemExit('중단: 반영할 화면 파일이 없습니다.')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8]
    backup = Path.home() / '.training-deploy-backups' / stamp
    backup.mkdir(parents=True)
    record = {'zip_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
              'deploy_dir': str(deploy), 'files': [str(rel) for rel, _, _ in pending]}
    (backup / 'record.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
    for rel, dest, data in pending:
        if dest.exists():
            old = backup.joinpath(*rel.parts)
            old.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dest, old)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
    print(f'화면 파일 {len(pending)}개 반영. 백업: {backup}')
PY

cd "$DEPLOY_DIR"
TAG="zip-$(date -u +%Y%m%d-%H%M%S)-$RANDOM"
IMAGE_URI="$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/$SERVICE_NAME:$TAG"
printf '빌드 시작: %s / %s\n' "$PROJECT_ID" "$SERVICE_NAME"
gcloud builds submit . --project="$PROJECT_ID" --region="$REGION" --tag="$IMAGE_URI"
gcloud run deploy "$SERVICE_NAME" --project="$PROJECT_ID" --region="$REGION" --image="$IMAGE_URI" --quiet
printf '\n배포 완료. 아래 URL에서 수정 내용과 Agent 응답을 확인하세요.\n'
gcloud run services describe "$SERVICE_NAME" --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)'
