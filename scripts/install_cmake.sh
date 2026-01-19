#!/bin/bash

# CMake 설치 스크립트

set -e

echo "🔍 CMake 설치 확인 중..."

# CMake 확인
if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -n 1)
    echo "✅ CMake가 이미 설치되어 있습니다: $CMAKE_VERSION"
    exit 0
fi

echo "❌ CMake가 설치되어 있지 않습니다."
echo ""

# Homebrew 확인
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew가 설치되어 있지 않습니다."
    echo ""
    echo "Homebrew 설치 방법:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    echo "Homebrew 설치 후 이 스크립트를 다시 실행하세요."
    exit 1
fi

echo "📦 Homebrew를 사용하여 CMake 설치 중..."
echo ""

# CMake 설치
brew install cmake

echo ""
echo "✅ CMake 설치 완료!"
echo ""

# 설치 확인
if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -n 1)
    echo "설치된 버전: $CMAKE_VERSION"
    echo ""
    echo "이제 Paddle-Lite 빌드를 다시 시도할 수 있습니다:"
    echo "  bash ./scripts/build_paddlelite_ios.sh"
else
    echo "❌ CMake 설치에 실패했습니다."
    exit 1
fi
