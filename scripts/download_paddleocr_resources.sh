#!/bin/bash

# PaddleOCR 리소스 다운로드 스크립트
# 이 스크립트는 필요한 모델 파일과 딕셔너리 파일을 다운로드합니다.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_RUNNER="$PROJECT_ROOT/ios/Runner"
PADDLEOCR_DIR="$IOS_RUNNER/PaddleOCR"

echo "🚀 PaddleOCR 리소스 다운로드를 시작합니다..."

# PaddleOCR 디렉토리 생성
mkdir -p "$PADDLEOCR_DIR"
mkdir -p "$PADDLEOCR_DIR/models"
mkdir -p "$PADDLEOCR_DIR/dict"

# 1. ppocr_keys_v1.txt 다운로드 (문자 사전)
echo "📥 ppocr_keys_v1.txt 다운로드 중..."
curl -L -o "$PADDLEOCR_DIR/dict/ppocr_keys_v1.txt" \
  "https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/ppocr_keys_v1.txt"

if [ -f "$PADDLEOCR_DIR/dict/ppocr_keys_v1.txt" ]; then
    echo "✅ ppocr_keys_v1.txt 다운로드 완료"
    echo "   위치: $PADDLEOCR_DIR/dict/ppocr_keys_v1.txt"
else
    echo "❌ ppocr_keys_v1.txt 다운로드 실패"
    exit 1
fi

# 2. 한국어 딕셔너리 (선택사항)
echo "📥 korean_dict.txt 다운로드 중..."
curl -L -o "$PADDLEOCR_DIR/dict/korean_dict.txt" \
  "https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/dict/korean_dict.txt" || echo "⚠️  korean_dict.txt는 선택사항입니다"

# 3. 영어 딕셔너리 (선택사항)
echo "📥 en_dict.txt 다운로드 중..."
curl -L -o "$PADDLEOCR_DIR/dict/en_dict.txt" \
  "https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/dict/en_dict.txt" || echo "⚠️  en_dict.txt는 선택사항입니다"

echo ""
echo "📋 다음 단계:"
echo "1. 모델 파일(.nb)을 수동으로 다운로드해야 합니다:"
echo "   - PP-OCR 모바일 모델: https://github.com/PaddlePaddle/PaddleOCR/blob/release/2.7/deploy/lite/README.md"
echo "   - 다운로드한 모델 파일을 $PADDLEOCR_DIR/models/ 에 복사하세요"
echo ""
echo "2. Paddle-Lite 프레임워크 다운로드:"
echo "   - https://github.com/PaddlePaddle/Paddle-Lite/releases"
echo "   - iOS용 .framework 또는 .xcframework 파일을 다운로드하세요"
echo ""
echo "✅ 딕셔너리 파일 다운로드 완료!"
echo "   위치: $PADDLEOCR_DIR/dict/"
