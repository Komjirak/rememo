//
//  PaddleOCRWrapper.h
//  Runner
//
//  Paddle-Lite C++ API를 Swift에서 사용하기 위한 Objective-C++ 래퍼
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCRResult : NSObject
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) float confidence;
@property (nonatomic, assign) CGRect boundingBox;
@end

@interface PaddleOCRWrapper : NSObject

+ (instancetype)shared;

/// PaddleOCR 초기화
/// @param detModelPath Detection 모델 경로
/// @param recModelPath Recognition 모델 경로
/// @param dictPath 딕셔너리 파일 경로
- (BOOL)initializeWithDetModel:(NSString *)detModelPath
                     recModel:(NSString *)recModelPath
                    dictionary:(NSString *)dictPath;

/// 이미지에서 텍스트 인식
/// @param image 입력 이미지
/// @param completion 결과 콜백 (텍스트 배열)
- (void)recognizeTextFromImage:(UIImage *)image
                    completion:(void (^)(NSArray<OCRResult *> * _Nullable results, NSError * _Nullable error))completion;

/// 이미지에서 텍스트 인식 (단순 문자열 반환)
- (void)recognizeTextFromImage:(UIImage *)image
                    textCompletion:(void (^)(NSString * _Nullable text))completion;

@end

NS_ASSUME_NONNULL_END
