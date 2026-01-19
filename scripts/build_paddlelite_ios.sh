#!/bin/bash

# Paddle-Lite iOS 프레임워크 빌드 스크립트
# 이미 클론된 Paddle-Lite 소스에서 iOS 프레임워크를 빌드합니다.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PADDLE_LITE_DIR="$PROJECT_ROOT/Paddle-Lite"
IOS_RUNNER="$PROJECT_ROOT/ios/Runner"
FRAMEWORKS_DIR="$IOS_RUNNER/Frameworks"

echo "🚀 Paddle-Lite iOS 프레임워크 빌드를 시작합니다..."
echo ""

# Paddle-Lite 디렉토리 확인
if [ ! -d "$PADDLE_LITE_DIR" ]; then
    echo "❌ Paddle-Lite 디렉토리를 찾을 수 없습니다: $PADDLE_LITE_DIR"
    echo "   먼저 git clone을 실행하세요:"
    echo "   git clone https://github.com/PaddlePaddle/Paddle-Lite.git"
    exit 1
fi

cd "$PADDLE_LITE_DIR"

echo "📋 현재 위치: $(pwd)"
echo ""

# 빌드 스크립트 확인
if [ ! -f "lite/tools/build.sh" ]; then
    echo "❌ 빌드 스크립트를 찾을 수 없습니다: lite/tools/build.sh"
    exit 1
fi

echo "⚠️  주의: Paddle-Lite iOS 빌드는 시간이 오래 걸릴 수 있습니다 (30분~1시간 이상)"
echo ""
echo "빌드 옵션:"
echo "  1. iOS 64-bit (arm64) - iPhone/iPad용"
echo "  2. iOS 32-bit (armv7) - 구형 기기용 (선택사항)"
echo ""

read -p "빌드를 계속하시겠습니까? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "빌드가 취소되었습니다."
    exit 0
fi

echo ""
echo "🔨 iOS 64-bit (arm64) 프레임워크 빌드 시작..."
echo ""

# iOS 64-bit 빌드
# 참고: 실제 빌드 명령어는 Paddle-Lite 버전에 따라 다를 수 있습니다
# 아래 명령어는 일반적인 예시입니다

# iOS 전용 빌드 스크립트 사용
if [ -f "lite/tools/build_ios.sh" ]; then
    echo "iOS 전용 빌드 스크립트 사용..."
    echo ""
    echo "빌드 옵션:"
    echo "  --arch=armv8 (64-bit, 권장) 또는 armv7 (32-bit)"
    echo "  --with_extra=ON (OCR 등 시퀀스 모델에 필요)"
    echo "  --with_cv=ON (컴퓨터 비전 함수, OCR에 필요)"
    echo "  --with_exception=ON (에러 처리)"
    echo "  --ios_deployment_target=15.5 (최소 iOS 버전)"
    echo ""
    
    # 실제 빌드 실행
    # OCR을 위해 with_extra와 with_cv가 필요합니다
    ./lite/tools/build_ios.sh \
        --arch=armv8 \
        --with_extra=ON \
        --with_cv=ON \
        --with_exception=ON \
        --ios_deployment_target=15.5
else
    echo "❌ iOS 빌드 스크립트를 찾을 수 없습니다."
    exit 1
fi

echo ""
echo "✅ 빌드 완료!"
echo ""

# 빌드 결과 확인
# Paddle-Lite iOS 빌드는 build.ios.ios64.armv8 또는 build.ios.ios.armv7 디렉토리에 생성됩니다
BUILD_DIR=$(find . -type d -name "build.ios.*" | head -1)
if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR=$(find . -type d -name "inference_lite_lib.ios*" | head -1)
fi

if [ -z "$BUILD_DIR" ]; then
    echo "⚠️  빌드 결과 디렉토리를 찾을 수 없습니다."
    echo "   수동으로 확인해주세요:"
    echo "   cd $PADDLE_LITE_DIR"
    echo "   find . -name '*ios*' -type d"
    exit 1
fi

echo "📦 빌드 결과 위치: $BUILD_DIR"
echo ""

# 프레임워크 파일 찾기
FRAMEWORK_FILE=$(find "$BUILD_DIR" -name "*.framework" -o -name "*.xcframework" | head -1)

if [ -z "$FRAMEWORK_FILE" ]; then
    echo "⚠️  프레임워크 파일을 찾을 수 없습니다."
    echo "   빌드된 라이브러리 파일(.a)을 찾았습니다:"
    find "$BUILD_DIR" -name "*.a" | head -5
    echo ""
    echo "   .a 파일을 .framework로 변환해야 할 수 있습니다."
    echo "   또는 Paddle-Lite 문서를 참고하여 프레임워크 생성 방법을 확인하세요."
else
    echo "✅ 프레임워크 파일 발견: $FRAMEWORK_FILE"
    echo ""
    
    # Frameworks 디렉토리 생성
    mkdir -p "$FRAMEWORKS_DIR"
    
    # 프레임워크 복사
    echo "📋 프레임워크를 프로젝트에 복사 중..."
    cp -R "$FRAMEWORK_FILE" "$FRAMEWORKS_DIR/"
    
    echo "✅ 프레임워크 복사 완료: $FRAMEWORKS_DIR"
    echo ""
    echo "다음 단계:"
    echo "  1. Xcode에서 ios/Runner.xcworkspace 열기"
    echo "  2. 프레임워크를 프로젝트에 드래그 앤 드롭"
    echo "  3. General → Frameworks, Libraries, and Embedded Content → Embed & Sign 설정"
    echo "  4. PADDLEOCR_FRAMEWORK_GUIDE.md 가이드 참고"
fi
