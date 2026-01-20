#!/bin/bash

# Gemma 2B Core ML 모델 다운로드 스크립트
# Apple의 공식 Core ML 변환 버전 다운로드

set -e

echo "🤖 Gemma 2B Core ML 모델 다운로드 시작..."
echo ""

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ 에러: pubspec.yaml을 찾을 수 없습니다.${NC}"
    echo "   프로젝트 루트 디렉토리에서 실행하세요."
    exit 1
fi

# 디렉토리 생성
echo -e "${YELLOW}📁 디렉토리 생성 중...${NC}"
mkdir -p ios/Runner/MLModels

# Hugging Face에서 다운로드
echo ""
echo -e "${YELLOW}⬇️  Gemma 2B 모델 다운로드 중...${NC}"
echo "   출처: https://huggingface.co/apple/coreml-gemma-2b-instruct"
echo "   크기: ~2.5GB (시간이 걸릴 수 있습니다)"
echo ""

# 모델 파일 URL (Apple 공식)
MODEL_URL="https://huggingface.co/apple/coreml-gemma-2b-instruct/resolve/main/gemma-2b-it-q4.mlpackage.zip"

# 다운로드
cd ios/Runner/MLModels

if command -v wget &> /dev/null; then
    wget -O gemma-2b-it.mlpackage.zip "$MODEL_URL" --progress=bar:force 2>&1
elif command -v curl &> /dev/null; then
    curl -L -o gemma-2b-it.mlpackage.zip "$MODEL_URL" --progress-bar
else
    echo -e "${RED}❌ wget 또는 curl이 필요합니다.${NC}"
    echo "   설치: brew install wget"
    exit 1
fi

# 압축 해제
echo ""
echo -e "${YELLOW}📦 압축 해제 중...${NC}"
unzip -q gemma-2b-it.mlpackage.zip

# 압축 파일 삭제
rm gemma-2b-it.mlpackage.zip

# 파일 이름 변경 (필요시)
if [ -d "gemma-2b-it-q4.mlpackage" ]; then
    mv gemma-2b-it-q4.mlpackage gemma-2b-it.mlpackage
fi

echo ""
echo -e "${GREEN}✅ Gemma 2B 모델 다운로드 완료!${NC}"
echo ""
echo -e "${YELLOW}📝 다음 단계:${NC}"
echo "   1. Xcode에서 ios/Runner.xcworkspace 열기"
echo "   2. Project Navigator에서 Runner 선택"
echo "   3. File → Add Files to \"Runner\" 선택"
echo "   4. ios/Runner/MLModels/gemma-2b-it.mlpackage 선택"
echo "   5. \"Copy items if needed\" 체크"
echo "   6. Target \"Runner\" 선택"
echo ""
echo -e "${GREEN}🎉 준비 완료! flutter run으로 앱을 실행하세요.${NC}"
echo ""

cd ../../..
