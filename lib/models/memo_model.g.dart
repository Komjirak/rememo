// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemoModelImpl _$$MemoModelImplFromJson(Map<String, dynamic> json) =>
    _$MemoModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: DateTime.parse(json['processedAt'] as String),
      provider: json['provider'] as String,
      detectedData: DetectedDataModel.fromJson(
        json['detectedData'] as Map<String, dynamic>,
      ),
      explanation: json['explanation'] as String?,
      insights:
          (json['insights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      isArchived: json['isArchived'] as bool? ?? false,
      refinedText: json['refinedText'] as String?,
      sourceType: json['sourceType'] as String? ?? 'screenshot',
      contentType: json['contentType'] as String? ?? 'general',
    );

Map<String, dynamic> _$$MemoModelImplToJson(_$MemoModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'text': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'processedAt': instance.processedAt.toIso8601String(),
      'provider': instance.provider,
      'detectedData': instance.detectedData,
      'explanation': instance.explanation,
      'insights': instance.insights,
      'tags': instance.tags,
      'isArchived': instance.isArchived,
      'refinedText': instance.refinedText,
      'sourceType': instance.sourceType,
      'contentType': instance.contentType,
    };

_$DetectedDataModelImpl _$$DetectedDataModelImplFromJson(
  Map<String, dynamic> json,
) => _$DetectedDataModelImpl(
  urls:
      (json['urls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  phoneNumbers:
      (json['phoneNumbers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  emails:
      (json['emails'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$DetectedDataModelImplToJson(
  _$DetectedDataModelImpl instance,
) => <String, dynamic>{
  'urls': instance.urls,
  'phoneNumbers': instance.phoneNumbers,
  'emails': instance.emails,
};
