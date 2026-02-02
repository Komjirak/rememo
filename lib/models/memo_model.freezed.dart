// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memo_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MemoModel _$MemoModelFromJson(Map<String, dynamic> json) {
  return _MemoModel.fromJson(json);
}

/// @nodoc
mixin _$MemoModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get processedAt => throw _privateConstructorUsedError;
  String get provider =>
      throw _privateConstructorUsedError; // "foundation" or "enhanced"
  DetectedDataModel get detectedData => throw _privateConstructorUsedError;
  String? get explanation =>
      throw _privateConstructorUsedError; // AI 설명 (About This Screenshot)
  List<String> get insights =>
      throw _privateConstructorUsedError; // Key Insights
  List<String> get tags => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;
  String? get refinedText => throw _privateConstructorUsedError;
  String get sourceType =>
      throw _privateConstructorUsedError; // "screenshot", "link", "photo", "share"
  String get contentType => throw _privateConstructorUsedError;

  /// Serializes this MemoModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoModelCopyWith<MemoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoModelCopyWith<$Res> {
  factory $MemoModelCopyWith(MemoModel value, $Res Function(MemoModel) then) =
      _$MemoModelCopyWithImpl<$Res, MemoModel>;
  @useResult
  $Res call({
    String id,
    String title,
    String text,
    DateTime createdAt,
    DateTime processedAt,
    String provider,
    DetectedDataModel detectedData,
    String? explanation,
    List<String> insights,
    List<String> tags,
    bool isArchived,
    String? refinedText,
    String sourceType,
    String contentType,
  });

  $DetectedDataModelCopyWith<$Res> get detectedData;
}

/// @nodoc
class _$MemoModelCopyWithImpl<$Res, $Val extends MemoModel>
    implements $MemoModelCopyWith<$Res> {
  _$MemoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? text = null,
    Object? createdAt = null,
    Object? processedAt = null,
    Object? provider = null,
    Object? detectedData = null,
    Object? explanation = freezed,
    Object? insights = null,
    Object? tags = null,
    Object? isArchived = null,
    Object? refinedText = freezed,
    Object? sourceType = null,
    Object? contentType = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            processedAt: null == processedAt
                ? _value.processedAt
                : processedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            provider: null == provider
                ? _value.provider
                : provider // ignore: cast_nullable_to_non_nullable
                      as String,
            detectedData: null == detectedData
                ? _value.detectedData
                : detectedData // ignore: cast_nullable_to_non_nullable
                      as DetectedDataModel,
            explanation: freezed == explanation
                ? _value.explanation
                : explanation // ignore: cast_nullable_to_non_nullable
                      as String?,
            insights: null == insights
                ? _value.insights
                : insights // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isArchived: null == isArchived
                ? _value.isArchived
                : isArchived // ignore: cast_nullable_to_non_nullable
                      as bool,
            refinedText: freezed == refinedText
                ? _value.refinedText
                : refinedText // ignore: cast_nullable_to_non_nullable
                      as String?,
            sourceType: null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                      as String,
            contentType: null == contentType
                ? _value.contentType
                : contentType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of MemoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DetectedDataModelCopyWith<$Res> get detectedData {
    return $DetectedDataModelCopyWith<$Res>(_value.detectedData, (value) {
      return _then(_value.copyWith(detectedData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MemoModelImplCopyWith<$Res>
    implements $MemoModelCopyWith<$Res> {
  factory _$$MemoModelImplCopyWith(
    _$MemoModelImpl value,
    $Res Function(_$MemoModelImpl) then,
  ) = __$$MemoModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String text,
    DateTime createdAt,
    DateTime processedAt,
    String provider,
    DetectedDataModel detectedData,
    String? explanation,
    List<String> insights,
    List<String> tags,
    bool isArchived,
    String? refinedText,
    String sourceType,
    String contentType,
  });

  @override
  $DetectedDataModelCopyWith<$Res> get detectedData;
}

/// @nodoc
class __$$MemoModelImplCopyWithImpl<$Res>
    extends _$MemoModelCopyWithImpl<$Res, _$MemoModelImpl>
    implements _$$MemoModelImplCopyWith<$Res> {
  __$$MemoModelImplCopyWithImpl(
    _$MemoModelImpl _value,
    $Res Function(_$MemoModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MemoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? text = null,
    Object? createdAt = null,
    Object? processedAt = null,
    Object? provider = null,
    Object? detectedData = null,
    Object? explanation = freezed,
    Object? insights = null,
    Object? tags = null,
    Object? isArchived = null,
    Object? refinedText = freezed,
    Object? sourceType = null,
    Object? contentType = null,
  }) {
    return _then(
      _$MemoModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        processedAt: null == processedAt
            ? _value.processedAt
            : processedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        provider: null == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                  as String,
        detectedData: null == detectedData
            ? _value.detectedData
            : detectedData // ignore: cast_nullable_to_non_nullable
                  as DetectedDataModel,
        explanation: freezed == explanation
            ? _value.explanation
            : explanation // ignore: cast_nullable_to_non_nullable
                  as String?,
        insights: null == insights
            ? _value._insights
            : insights // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isArchived: null == isArchived
            ? _value.isArchived
            : isArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
        refinedText: freezed == refinedText
            ? _value.refinedText
            : refinedText // ignore: cast_nullable_to_non_nullable
                  as String?,
        sourceType: null == sourceType
            ? _value.sourceType
            : sourceType // ignore: cast_nullable_to_non_nullable
                  as String,
        contentType: null == contentType
            ? _value.contentType
            : contentType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoModelImpl extends _MemoModel {
  const _$MemoModelImpl({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
    required this.processedAt,
    required this.provider,
    required this.detectedData,
    this.explanation,
    final List<String> insights = const [],
    final List<String> tags = const [],
    this.isArchived = false,
    this.refinedText,
    this.sourceType = 'screenshot',
    this.contentType = 'general',
  }) : _insights = insights,
       _tags = tags,
       super._();

  factory _$MemoModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String text;
  @override
  final DateTime createdAt;
  @override
  final DateTime processedAt;
  @override
  final String provider;
  // "foundation" or "enhanced"
  @override
  final DetectedDataModel detectedData;
  @override
  final String? explanation;
  // AI 설명 (About This Screenshot)
  final List<String> _insights;
  // AI 설명 (About This Screenshot)
  @override
  @JsonKey()
  List<String> get insights {
    if (_insights is EqualUnmodifiableListView) return _insights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_insights);
  }

  // Key Insights
  final List<String> _tags;
  // Key Insights
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final bool isArchived;
  @override
  final String? refinedText;
  @override
  @JsonKey()
  final String sourceType;
  // "screenshot", "link", "photo", "share"
  @override
  @JsonKey()
  final String contentType;

  @override
  String toString() {
    return 'MemoModel(id: $id, title: $title, text: $text, createdAt: $createdAt, processedAt: $processedAt, provider: $provider, detectedData: $detectedData, explanation: $explanation, insights: $insights, tags: $tags, isArchived: $isArchived, refinedText: $refinedText, sourceType: $sourceType, contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.detectedData, detectedData) ||
                other.detectedData == detectedData) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation) &&
            const DeepCollectionEquality().equals(other._insights, _insights) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.refinedText, refinedText) ||
                other.refinedText == refinedText) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    text,
    createdAt,
    processedAt,
    provider,
    detectedData,
    explanation,
    const DeepCollectionEquality().hash(_insights),
    const DeepCollectionEquality().hash(_tags),
    isArchived,
    refinedText,
    sourceType,
    contentType,
  );

  /// Create a copy of MemoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoModelImplCopyWith<_$MemoModelImpl> get copyWith =>
      __$$MemoModelImplCopyWithImpl<_$MemoModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoModelImplToJson(this);
  }
}

abstract class _MemoModel extends MemoModel {
  const factory _MemoModel({
    required final String id,
    required final String title,
    required final String text,
    required final DateTime createdAt,
    required final DateTime processedAt,
    required final String provider,
    required final DetectedDataModel detectedData,
    final String? explanation,
    final List<String> insights,
    final List<String> tags,
    final bool isArchived,
    final String? refinedText,
    final String sourceType,
    final String contentType,
  }) = _$MemoModelImpl;
  const _MemoModel._() : super._();

  factory _MemoModel.fromJson(Map<String, dynamic> json) =
      _$MemoModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get text;
  @override
  DateTime get createdAt;
  @override
  DateTime get processedAt;
  @override
  String get provider; // "foundation" or "enhanced"
  @override
  DetectedDataModel get detectedData;
  @override
  String? get explanation; // AI 설명 (About This Screenshot)
  @override
  List<String> get insights; // Key Insights
  @override
  List<String> get tags;
  @override
  bool get isArchived;
  @override
  String? get refinedText;
  @override
  String get sourceType; // "screenshot", "link", "photo", "share"
  @override
  String get contentType;

  /// Create a copy of MemoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoModelImplCopyWith<_$MemoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectedDataModel _$DetectedDataModelFromJson(Map<String, dynamic> json) {
  return _DetectedDataModel.fromJson(json);
}

/// @nodoc
mixin _$DetectedDataModel {
  List<String> get urls => throw _privateConstructorUsedError;
  List<String> get phoneNumbers => throw _privateConstructorUsedError;
  List<String> get emails => throw _privateConstructorUsedError;

  /// Serializes this DetectedDataModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetectedDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectedDataModelCopyWith<DetectedDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectedDataModelCopyWith<$Res> {
  factory $DetectedDataModelCopyWith(
    DetectedDataModel value,
    $Res Function(DetectedDataModel) then,
  ) = _$DetectedDataModelCopyWithImpl<$Res, DetectedDataModel>;
  @useResult
  $Res call({
    List<String> urls,
    List<String> phoneNumbers,
    List<String> emails,
  });
}

/// @nodoc
class _$DetectedDataModelCopyWithImpl<$Res, $Val extends DetectedDataModel>
    implements $DetectedDataModelCopyWith<$Res> {
  _$DetectedDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectedDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? urls = null,
    Object? phoneNumbers = null,
    Object? emails = null,
  }) {
    return _then(
      _value.copyWith(
            urls: null == urls
                ? _value.urls
                : urls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            phoneNumbers: null == phoneNumbers
                ? _value.phoneNumbers
                : phoneNumbers // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            emails: null == emails
                ? _value.emails
                : emails // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DetectedDataModelImplCopyWith<$Res>
    implements $DetectedDataModelCopyWith<$Res> {
  factory _$$DetectedDataModelImplCopyWith(
    _$DetectedDataModelImpl value,
    $Res Function(_$DetectedDataModelImpl) then,
  ) = __$$DetectedDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> urls,
    List<String> phoneNumbers,
    List<String> emails,
  });
}

/// @nodoc
class __$$DetectedDataModelImplCopyWithImpl<$Res>
    extends _$DetectedDataModelCopyWithImpl<$Res, _$DetectedDataModelImpl>
    implements _$$DetectedDataModelImplCopyWith<$Res> {
  __$$DetectedDataModelImplCopyWithImpl(
    _$DetectedDataModelImpl _value,
    $Res Function(_$DetectedDataModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DetectedDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? urls = null,
    Object? phoneNumbers = null,
    Object? emails = null,
  }) {
    return _then(
      _$DetectedDataModelImpl(
        urls: null == urls
            ? _value._urls
            : urls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        phoneNumbers: null == phoneNumbers
            ? _value._phoneNumbers
            : phoneNumbers // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        emails: null == emails
            ? _value._emails
            : emails // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectedDataModelImpl implements _DetectedDataModel {
  const _$DetectedDataModelImpl({
    final List<String> urls = const [],
    final List<String> phoneNumbers = const [],
    final List<String> emails = const [],
  }) : _urls = urls,
       _phoneNumbers = phoneNumbers,
       _emails = emails;

  factory _$DetectedDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectedDataModelImplFromJson(json);

  final List<String> _urls;
  @override
  @JsonKey()
  List<String> get urls {
    if (_urls is EqualUnmodifiableListView) return _urls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_urls);
  }

  final List<String> _phoneNumbers;
  @override
  @JsonKey()
  List<String> get phoneNumbers {
    if (_phoneNumbers is EqualUnmodifiableListView) return _phoneNumbers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_phoneNumbers);
  }

  final List<String> _emails;
  @override
  @JsonKey()
  List<String> get emails {
    if (_emails is EqualUnmodifiableListView) return _emails;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_emails);
  }

  @override
  String toString() {
    return 'DetectedDataModel(urls: $urls, phoneNumbers: $phoneNumbers, emails: $emails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectedDataModelImpl &&
            const DeepCollectionEquality().equals(other._urls, _urls) &&
            const DeepCollectionEquality().equals(
              other._phoneNumbers,
              _phoneNumbers,
            ) &&
            const DeepCollectionEquality().equals(other._emails, _emails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_urls),
    const DeepCollectionEquality().hash(_phoneNumbers),
    const DeepCollectionEquality().hash(_emails),
  );

  /// Create a copy of DetectedDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectedDataModelImplCopyWith<_$DetectedDataModelImpl> get copyWith =>
      __$$DetectedDataModelImplCopyWithImpl<_$DetectedDataModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectedDataModelImplToJson(this);
  }
}

abstract class _DetectedDataModel implements DetectedDataModel {
  const factory _DetectedDataModel({
    final List<String> urls,
    final List<String> phoneNumbers,
    final List<String> emails,
  }) = _$DetectedDataModelImpl;

  factory _DetectedDataModel.fromJson(Map<String, dynamic> json) =
      _$DetectedDataModelImpl.fromJson;

  @override
  List<String> get urls;
  @override
  List<String> get phoneNumbers;
  @override
  List<String> get emails;

  /// Create a copy of DetectedDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectedDataModelImplCopyWith<_$DetectedDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
