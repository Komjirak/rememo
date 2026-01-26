#!/bin/bash

# 앱 아이콘 생성 스크립트
# assets/icon.png 파일이 1024x1024 크기로 준비되어 있어야 합니다.

echo "🎨 앱 아이콘 생성 시작..."
echo ""

# 아이콘 파일 확인
if [ ! -f "assets/icon.png" ]; then
    echo "❌ 오류: assets/icon.png 파일을 찾을 수 없습니다."
    echo "   먼저 1024x1024 크기의 icon.png 파일을 assets/ 폴더에 저장해주세요."
    exit 1
fi

echo "✅ 아이콘 파일 확인: assets/icon.png"
echo ""

# Flutter Launcher Icons 실행
echo "📱 플랫폼별 아이콘 생성 중..."
flutter pub run flutter_launcher_icons

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 아이콘 생성 완료!"
    echo ""
    echo "생성된 플랫폼:"
    echo "  📱 iOS - ios/Runner/Assets.xcassets/AppIcon.appiconset/"
    echo "  🤖 Android - android/app/src/main/res/"
    echo "  💻 macOS - macos/Runner/Assets.xcassets/AppIcon.appiconset/"
    echo ""
    echo "다음 단계:"
    echo "  1. 앱을 완전히 종료하고 재시작하세요"
    echo "  2. 홈 화면/Dock에서 새 아이콘을 확인하세요"
    echo "  3. 필요시 앱을 삭제하고 재설치하세요"
else
    echo ""
    echo "❌ 아이콘 생성 실패"
    echo "   flutter pub get을 먼저 실행해보세요: flutter pub get"
    exit 1
fi
