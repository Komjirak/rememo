// lib/models/memo_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_model.freezed.dart';
part 'memo_model.g.dart';

@freezed
class MemoModel with _$MemoModel {
  const MemoModel._();
  
  const factory MemoModel({
    required String id,
    required String title,
    required String text,
    required DateTime createdAt,
    required DateTime processedAt,
    required String provider,  // "foundation" or "enhanced"
    required DetectedDataModel detectedData,
    String? explanation,  // AI 설명 (About This Screenshot)
    @Default([]) List<String> insights,  // Key Insights
    @Default([]) List<String> tags,
    @Default(false) bool isArchived,
    String? refinedText,
    @Default('screenshot') String sourceType,  // "screenshot", "link", "photo", "share"
    @Default('general') String contentType,  // "news", "blog", "restaurant", etc.
  }) = _MemoModel;

  factory MemoModel.fromJson(Map<String, dynamic> json) => _$MemoModelFromJson(json);
  
  // 출처 표시용 태그
  String get sourceTag {
    switch (sourceType) {
      case 'screenshot':
        return '스크린샷';
      case 'link':
        return '링크';
      case 'photo':
        return '사진';
      case 'share':
        return '공유';
      default:
        return '콘텐츠';
    }
  }
  
  // 콘텐츠 타입 표시용 태그
  String get styleTag {
    switch (contentType) {
      case 'news':
      case 'article':
        return '📰 뉴스';
      case 'blog':
        return '📝 블로그';
      case 'restaurant':
      case 'place':
        return '🍽️ 맛집';
      case 'product':
        return '🛍️ 쇼핑';
      case 'education':
        return '📚 교육';
      case 'social':
        return '💬 SNS';
      default:
        return '📄 일반';
    }
  }
}

@freezed
class DetectedDataModel with _$DetectedDataModel {
  const factory DetectedDataModel({
    @Default([]) List<String> urls,
    @Default([]) List<String> phoneNumbers,
    @Default([]) List<String> emails,
  }) = _DetectedDataModel;

  factory DetectedDataModel.fromJson(Map<String, dynamic> json) => 
      _$DetectedDataModelFromJson(json);
}
