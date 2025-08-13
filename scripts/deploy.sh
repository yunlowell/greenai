#!/bin/bash
set -e

# 환경 변수 로드
source .env

# 로컬 Docker 이미지 빌드
echo "[1/4] Docker 이미지 빌드..."
docker build -t $APP_NAME .

# Docker 이미지 tar 파일로 저장
rm -f ${APP_NAME}.tar
echo "[2/4] Docker 이미지 tar 파일로 저장..."
docker save $APP_NAME -o ${APP_NAME}.tar

# Lightsail 서버로 전송
echo "[3/4] Lightsail 서버로 전송..."
scp -i $PEM_PATH ${APP_NAME}.tar ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/

# 서버에서 컨테이너 실행
echo "[4/4] 서버에서 컨테이너 실행..."
ssh -i $PEM_PATH ${REMOTE_USER}@${REMOTE_HOST} << EOF
    set -e
    cd ${REMOTE_PATH}
    docker stop ${APP_NAME} || true
    docker rm ${APP_NAME} || true
    docker rmi ${APP_NAME} || true
    docker load -i ${APP_NAME}.tar
    docker run -d -p 80:8000 --name ${APP_NAME} ${APP_NAME}
    echo "배포 완료: http://${REMOTE_HOST}"
EOF