#!/bin/bash

# Paddle-Lite iOS 프레임워크 다운로드 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_RUNNER="$PROJECT_ROOT/ios/Runner"
FRAMEWORKS_DIR="$IOS_RUNNER/Frameworks"

echo "🚀 Paddle-Lite iOS 프레임워크 다운로드를 시작합니다..."

# Frameworks 디렉토리 생성
mkdir -p "$FRAMEWORKS_DIR"

echo ""
echo "📋 Paddle-Lite 프레임워크는 다음 방법 중 하나로 다운로드할 수 있습니다:"
echo ""
echo "방법 1: GitHub Releases에서 직접 다운로드 (권장)"
echo "   1. 브라우저에서 열기: https://github.com/PaddlePaddle/Paddle-Lite/releases"
echo "   2. 최신 릴리즈 선택"
echo "   3. Assets에서 'PaddleLite.framework.zip' 또는 'PaddleLite.xcframework.zip' 다운로드"
echo "   4. 압축 해제 후 $FRAMEWORKS_DIR 에 복사"
echo ""
echo "방법 2: 소스 코드에서 빌드 (고급)"
echo "   현재 프로젝트에 Paddle-Lite 소스가 있으므로 빌드 가능합니다."
echo "   하지만 시간이 오래 걸리고 복잡합니다."
echo ""
echo "⚠️  현재 상태:"
echo "   - Paddle-Lite 소스 코드: ✅ 있음 ($PROJECT_ROOT/Paddle-Lite)"
echo "   - 프레임워크 파일: ❌ 없음"
echo "   - iOS 프로젝트 연결: ❌ 안 됨"
echo ""
echo "다음 단계:"
echo "   1. 위 방법 1로 프레임워크 다운로드"
echo "   2. Xcode에서 프레임워크를 프로젝트에 추가"
echo "   3. 'PADDLEOCR_FRAMEWORK_GUIDE.md' 가이드 참고"
