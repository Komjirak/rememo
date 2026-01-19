//
//  PaddleOCRWrapper.mm
//  Runner
//
//  Paddle-Lite C++ API를 Swift에서 사용하기 위한 Objective-C++ 래퍼
//

#import "PaddleOCRWrapper.h"
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <cmath>
#include "paddle_api.h"
#include "paddle_use_ops.h"
#include "paddle_use_kernels.h"
#include "paddle_image_preprocess.h"

using namespace paddle::lite_api;
using namespace paddle::lite::utils::cv;

@implementation OCRResult
@end

@interface PaddleOCRWrapper ()
@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, strong) NSString *detModelPath;
@property (nonatomic, strong) NSString *recModelPath;
@property (nonatomic, strong) NSString *dictPath;
@property (nonatomic, strong) NSArray<NSString *> *dictionary;
@property (nonatomic, assign) std::shared_ptr<PaddlePredictor> detPredictor;
@property (nonatomic, assign) std::shared_ptr<PaddlePredictor> recPredictor;
@end

@implementation PaddleOCRWrapper

+ (instancetype)shared {
    static PaddleOCRWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PaddleOCRWrapper alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isInitialized = NO;
    }
    return self;
}

- (BOOL)initializeWithDetModel:(NSString *)detModelPath
                       recModel:(NSString *)recModelPath
                      dictionary:(NSString *)dictPath {
    if (self.isInitialized) {
        NSLog(@"⚠️ PaddleOCR가 이미 초기화되어 있습니다.");
        return YES;
    }
    
    self.detModelPath = detModelPath;
    self.recModelPath = recModelPath;
    self.dictPath = dictPath;
    
    // 딕셔너리 로드
    if (![self loadDictionary:dictPath]) {
        NSLog(@"❌ 딕셔너리 파일 로드 실패: %@", dictPath);
        return NO;
    }
    
    // Detection 모델 로드
    if (![self loadDetectionModel:detModelPath]) {
        NSLog(@"❌ Detection 모델 로드 실패: %@", detModelPath);
        return NO;
    }
    
    // Recognition 모델 로드
    if (![self loadRecognitionModel:recModelPath]) {
        NSLog(@"❌ Recognition 모델 로드 실패: %@", recModelPath);
        return NO;
    }
    
    self.isInitialized = YES;
    NSLog(@"✅ PaddleOCR 초기화 완료");
    return YES;
}

- (BOOL)loadDictionary:(NSString *)dictPath {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:dictPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    if (error || !content) {
        NSLog(@"❌ 딕셔너리 파일 읽기 실패: %@", error.localizedDescription);
        return NO;
    }
    
    NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
    NSMutableArray<NSString *> *dict = [NSMutableArray array];
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            [dict addObject:trimmed];
        }
    }
    
    self.dictionary = dict;
    NSLog(@"✅ 딕셔너리 로드 완료: %lu개 문자", (unsigned long)dict.count);
    return YES;
}

- (BOOL)loadDetectionModel:(NSString *)modelPath {
    try {
        MobileConfig config;
        config.set_model_from_file([modelPath UTF8String]);
        config.set_power_mode(LITE_POWER_HIGH);
        config.set_threads(4);
        
        self.detPredictor = CreatePaddlePredictor<MobileConfig>(config);
        if (!self.detPredictor) {
            NSLog(@"❌ Detection 모델 생성 실패");
            return NO;
        }
        
        NSLog(@"✅ Detection 모델 로드 완료");
        return YES;
    } catch (const std::exception &e) {
        NSLog(@"❌ Detection 모델 로드 예외: %s", e.what());
        return NO;
    }
}

- (BOOL)loadRecognitionModel:(NSString *)modelPath {
    try {
        MobileConfig config;
        config.set_model_from_file([modelPath UTF8String]);
        config.set_power_mode(LITE_POWER_HIGH);
        config.set_threads(4);
        
        self.recPredictor = CreatePaddlePredictor<MobileConfig>(config);
        if (!self.recPredictor) {
            NSLog(@"❌ Recognition 모델 생성 실패");
            return NO;
        }
        
        NSLog(@"✅ Recognition 모델 로드 완료");
        return YES;
    } catch (const std::exception &e) {
        NSLog(@"❌ Recognition 모델 로드 예외: %s", e.what());
        return NO;
    }
}

- (void)recognizeTextFromImage:(UIImage *)image
                    completion:(void (^)(NSArray<OCRResult *> * _Nullable, NSError * _Nullable))completion {
    if (!self.isInitialized) {
        NSError *error = [NSError errorWithDomain:@"PaddleOCR" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"PaddleOCR가 초기화되지 않았습니다."}];
        completion(nil, error);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @autoreleasepool {
            // 1. 이미지 전처리
            UIImage *processedImage = [self preprocessImage:image];
            if (!processedImage) {
                NSError *error = [NSError errorWithDomain:@"PaddleOCR" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"이미지 전처리 실패"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
                return;
            }
            
            // 2. Detection 실행
            NSArray<NSValue *> *boxes = [self detectTextBoxes:processedImage];
            if (boxes.count == 0) {
                NSLog(@"⚠️ 텍스트 박스를 찾을 수 없습니다.");
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@[], nil);
                });
                return;
            }
            
            // 3. Recognition 실행
            NSMutableArray<OCRResult *> *results = [NSMutableArray array];
            for (NSValue *boxValue in boxes) {
                CGRect box = [boxValue CGRectValue];
                UIImage *croppedImage = [self cropImage:processedImage rect:box];
                if (croppedImage) {
                    NSString *text = [self recognizeText:croppedImage];
                    if (text && text.length > 0) {
                        OCRResult *result = [[OCRResult alloc] init];
                        result.text = text;
                        result.confidence = 1.0; // TODO: 실제 confidence 계산
                        result.boundingBox = box;
                        [results addObject:result];
                    }
                }
            }
            
            // 4. 결과 반환
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([results copy], nil);
            });
        }
    });
}

- (void)recognizeTextFromImage:(UIImage *)image
                textCompletion:(void (^)(NSString * _Nullable))completion {
    [self recognizeTextFromImage:image completion:^(NSArray<OCRResult *> * _Nullable results, NSError * _Nullable error) {
        if (error) {
            completion(nil);
            return;
        }
        
        // 결과를 위치 순서대로 정렬 (상단→하단, 왼쪽→오른쪽)
        NSArray<OCRResult *> *sortedResults = [results sortedArrayUsingComparator:^NSComparisonResult(OCRResult * _Nonnull obj1, OCRResult * _Nonnull obj2) {
            CGFloat y1 = obj1.boundingBox.origin.y;
            CGFloat y2 = obj2.boundingBox.origin.y;
            if (fabs(y1 - y2) > 10) {
                return y1 < y2 ? NSOrderedAscending : NSOrderedDescending;
            }
            CGFloat x1 = obj1.boundingBox.origin.x;
            CGFloat x2 = obj2.boundingBox.origin.x;
            return x1 < x2 ? NSOrderedAscending : NSOrderedDescending;
        }];
        
        // 텍스트 합치기
        NSMutableArray<NSString *> *texts = [NSMutableArray array];
        for (OCRResult *result in sortedResults) {
            if (result.text.length > 0) {
                [texts addObject:result.text];
            }
        }
        
        NSString *finalText = [texts componentsJoinedByString:@"\n"];
        completion(finalText);
    }];
}

#pragma mark - Image Processing

- (UIImage *)preprocessImage:(UIImage *)image {
    // 이미지 크기 조정 (최대 2048px)
    CGFloat maxDimension = 2048;
    CGSize size = image.size;
    CGFloat scale = MIN(maxDimension / MAX(size.width, size.height), 1.0);
    
    if (scale < 1.0) {
        CGSize newSize = CGSizeMake(size.width * scale, size.height * scale);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return resizedImage;
    }
    
    return image;
}

- (UIImage *)cropImage:(UIImage *)image rect:(CGRect)rect {
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    if (!imageRef) return nil;
    
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

#pragma mark - Detection

- (NSArray<NSValue *> *)detectTextBoxes:(UIImage *)image {
    if (!self.detPredictor) {
        NSLog(@"❌ Detection 모델이 로드되지 않았습니다.");
        return @[];
    }
    
    try {
        // 1. UIImage를 RGBA 데이터로 변환
        CGImageRef cgImage = image.CGImage;
        size_t width = CGImageGetWidth(cgImage);
        size_t height = CGImageGetHeight(cgImage);
        size_t bytesPerPixel = 4;
        size_t bytesPerRow = bytesPerPixel * width;
        size_t bitsPerComponent = 8;
        
        std::vector<uint8_t> imageData(width * height * bytesPerPixel);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(imageData.data(), width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        // 2. 이미지 전처리 (Detection 모델 입력 형식에 맞춤)
        // PP-OCR Detection 모델은 보통 640x640 또는 동적 크기 입력을 받음
        int targetWidth = 640;
        int targetHeight = 640;
        
        // 이미지 리사이즈 (비율 유지하면서 패딩 추가)
        float scale = MIN((float)targetWidth / width, (float)targetHeight / height);
        int newWidth = (int)(width * scale);
        int newHeight = (int)(height * scale);
        
        std::vector<uint8_t> resizedData(targetWidth * targetHeight * 3, 114); // 회색 패딩
        
        // 이미지 리사이즈 및 BGR 변환
        ImagePreprocess preprocess(RGBA, BGR, TransParam{static_cast<int>(height), static_cast<int>(width),
                                                          targetHeight, targetWidth, XY, 0});
        
        // 패딩 계산
        int padTop = (targetHeight - newHeight) / 2;
        int padLeft = (targetWidth - newWidth) / 2;
        
        // 리사이즈된 이미지 데이터 준비 (BGR 형식, 패딩은 회색 114)
        // 간단한 bilinear 리사이즈
        for (int y = 0; y < targetHeight; y++) {
            for (int x = 0; x < targetWidth; x++) {
                int dstIdx = (y * targetWidth + x) * 3;
                
                if (y >= padTop && y < padTop + newHeight &&
                    x >= padLeft && x < padLeft + newWidth) {
                    // 실제 이미지 영역
                    float srcX = (x - padLeft) / scale;
                    float srcY = (y - padTop) / scale;
                    
                    int x1 = (int)srcX;
                    int y1 = (int)srcY;
                    int x2 = std::min(x1 + 1, (int)width - 1);
                    int y2 = std::min(y1 + 1, (int)height - 1);
                    
                    float fx = srcX - x1;
                    float fy = srcY - y1;
                    
                    // Bilinear interpolation
                    for (int c = 0; c < 3; c++) {
                        int cIdx = 2 - c; // BGR 순서
                        float p1 = imageData[(y1 * width + x1) * 4 + cIdx];
                        float p2 = imageData[(y1 * width + x2) * 4 + cIdx];
                        float p3 = imageData[(y2 * width + x1) * 4 + cIdx];
                        float p4 = imageData[(y2 * width + x2) * 4 + cIdx];
                        
                        float val = (1 - fx) * (1 - fy) * p1 +
                                   fx * (1 - fy) * p2 +
                                   (1 - fx) * fy * p3 +
                                   fx * fy * p4;
                        resizedData[dstIdx + c] = (uint8_t)val;
                    }
                } else {
                    // 패딩 영역 (회색)
                    resizedData[dstIdx] = 114;     // B
                    resizedData[dstIdx + 1] = 114; // G
                    resizedData[dstIdx + 2] = 114; // R
                }
            }
        }
        
        // 3. 텐서 준비 및 입력 설정
        auto inputTensor = self.detPredictor->GetInput(0);
        std::vector<int64_t> inputShape = {1, 3, targetHeight, targetWidth};
        inputTensor->Resize(inputShape);
        
        // 정규화 (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225] 또는 모델에 맞게)
        float mean[3] = {0.485f, 0.456f, 0.406f};
        float scale_values[3] = {1.0f / 0.229f, 1.0f / 0.224f, 1.0f / 0.225f};
        
        float* inputData = inputTensor->mutable_data<float>();
        for (int i = 0; i < targetHeight * targetWidth; i++) {
            for (int c = 0; c < 3; c++) {
                int idx = i * 3 + c;
                float pixel = resizedData[idx] / 255.0f;
                inputData[c * targetHeight * targetWidth + i] = (pixel - mean[c]) * scale_values[c];
            }
        }
        
        // 4. 모델 실행
        self.detPredictor->Run();
        
        // 5. 출력 텐서 가져오기
        auto outputTensor = self.detPredictor->GetOutput(0);
        auto outputShape = outputTensor->shape();
        const float* outputData = outputTensor->data<float>();
        
        // 6. 출력 파싱 (Detection 모델 출력 형식에 따라 다름)
        // PP-OCR Detection은 보통 [batch, 1, H, W] 형태의 probability map을 출력
        int outH, outW;
        if (outputShape.size() >= 4) {
            outH = outputShape[2];
            outW = outputShape[3];
        } else if (outputShape.size() == 3) {
            outH = outputShape[1];
            outW = outputShape[2];
        } else {
            outH = 1;
            outW = outputShape[1];
        }
        
        // Scale factor 계산 (원본 이미지 크기로 변환)
        float scaleX = image.size.width / (float)targetWidth;
        float scaleY = image.size.height / (float)targetHeight;
        
        // Threshold 적용하여 텍스트 영역 찾기
        float threshold = 0.3f;
        NSMutableArray<NSValue *> *boxes = [NSMutableArray array];
        
        // Probability map에서 텍스트 영역 찾기
        // 간단한 방법: 연속된 영역 찾기
        std::vector<std::vector<bool>> visited(outH, std::vector<bool>(outW, false));
        
        for (int y = 0; y < outH; y++) {
            for (int x = 0; x < outW; x++) {
                float prob = outputData[y * outW + x];
                if (prob > threshold && !visited[y][x]) {
                    // BFS로 연결된 영역 찾기
                    int minX = x, maxX = x, minY = y, maxY = y;
                    std::vector<std::pair<int, int>> queue;
                    queue.push_back({x, y});
                    visited[y][x] = true;
                    
                    while (!queue.empty()) {
                        std::pair<int, int> current = queue.back();
                        int cx = current.first;
                        int cy = current.second;
                        queue.pop_back();
                        
                        minX = std::min(minX, cx);
                        maxX = std::max(maxX, cx);
                        minY = std::min(minY, cy);
                        maxY = std::max(maxY, cy);
                        
                        // 4방향 탐색
                        int dx[] = {-1, 1, 0, 0};
                        int dy[] = {0, 0, -1, 1};
                        for (int i = 0; i < 4; i++) {
                            int nx = cx + dx[i];
                            int ny = cy + dy[i];
                            if (nx >= 0 && nx < outW && ny >= 0 && ny < outH && !visited[ny][nx]) {
                                float nProb = outputData[ny * outW + nx];
                                if (nProb > threshold) {
                                    visited[ny][nx] = true;
                                    queue.push_back({nx, ny});
                                }
                            }
                        }
                    }
                    
                    // 박스 크기 필터링 (너무 작은 박스 제거)
                    int boxWidth = maxX - minX + 1;
                    int boxHeight = maxY - minY + 1;
                    if (boxWidth > 10 && boxHeight > 10) {
                        // 원본 이미지 좌표로 변환
                        float origX = (minX - padLeft) * scaleX;
                        float origY = (minY - padTop) * scaleY;
                        float origW = boxWidth * scaleX;
                        float origH = boxHeight * scaleY;
                        
                        // 이미지 경계 내로 제한
                        origX = std::max(0.0f, std::min(origX, (float)image.size.width));
                        origY = std::max(0.0f, std::min(origY, (float)image.size.height));
                        origW = std::min(origW, (float)image.size.width - origX);
                        origH = std::min(origH, (float)image.size.height - origY);
                        
                        CGRect box = CGRectMake(origX, origY, origW, origH);
                        [boxes addObject:[NSValue valueWithCGRect:box]];
                    }
                }
            }
        }
        
        // 박스가 없으면 전체 이미지를 하나의 박스로 반환 (fallback)
        if (boxes.count == 0) {
            NSLog(@"⚠️ Detection에서 박스를 찾지 못했습니다. 전체 이미지를 사용합니다.");
            CGRect fullRect = CGRectMake(0, 0, image.size.width, image.size.height);
            [boxes addObject:[NSValue valueWithCGRect:fullRect]];
        }
        
        NSLog(@"✅ Detection 완료: %lu개 박스 발견", (unsigned long)boxes.count);
        return boxes;
        
    } catch (const std::exception &e) {
        NSLog(@"❌ Detection 실행 오류: %s", e.what());
        return @[];
    }
}

#pragma mark - Recognition

- (NSString *)recognizeText:(UIImage *)image {
    if (!self.recPredictor || !self.dictionary) {
        NSLog(@"❌ Recognition 모델 또는 딕셔너리가 로드되지 않았습니다.");
        return @"";
    }
    
    try {
        // 1. UIImage를 RGBA 데이터로 변환
        CGImageRef cgImage = image.CGImage;
        size_t width = CGImageGetWidth(cgImage);
        size_t height = CGImageGetHeight(cgImage);
        size_t bytesPerPixel = 4;
        size_t bytesPerRow = bytesPerPixel * width;
        size_t bitsPerComponent = 8;
        
        std::vector<uint8_t> imageData(width * height * bytesPerPixel);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(imageData.data(), width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        // 2. 이미지 전처리 (Recognition 모델 입력 형식에 맞춤)
        // PP-OCR Recognition 모델은 보통 높이 32px, 너비는 비율 유지
        int targetHeight = 32;
        int targetWidth = (int)((float)width * targetHeight / height);
        targetWidth = ((targetWidth / 32) + 1) * 32; // 32의 배수로 맞춤
        targetWidth = std::max(targetWidth, 32); // 최소 32
        
        // 이미지 리사이즈 및 BGR 변환
        std::vector<uint8_t> resizedData(targetWidth * targetHeight * 3, 0);
        
        float scaleX = (float)targetWidth / width;
        float scaleY = (float)targetHeight / height;
        
        // Bilinear interpolation으로 리사이즈
        for (int y = 0; y < targetHeight; y++) {
            for (int x = 0; x < targetWidth; x++) {
                float srcX = x / scaleX;
                float srcY = y / scaleY;
                
                int x1 = (int)srcX;
                int y1 = (int)srcY;
                int x2 = std::min(x1 + 1, (int)width - 1);
                int y2 = std::min(y1 + 1, (int)height - 1);
                
                float fx = srcX - x1;
                float fy = srcY - y1;
                
                int dstIdx = (y * targetWidth + x) * 3;
                
                // Bilinear interpolation
                for (int c = 0; c < 3; c++) {
                    int cIdx = 2 - c; // BGR 순서
                    float p1 = imageData[(y1 * width + x1) * 4 + cIdx];
                    float p2 = imageData[(y1 * width + x2) * 4 + cIdx];
                    float p3 = imageData[(y2 * width + x1) * 4 + cIdx];
                    float p4 = imageData[(y2 * width + x2) * 4 + cIdx];
                    
                    float val = (1 - fx) * (1 - fy) * p1 +
                               fx * (1 - fy) * p2 +
                               (1 - fx) * fy * p3 +
                               fx * fy * p4;
                    resizedData[dstIdx + c] = (uint8_t)std::max(0.0f, std::min(255.0f, val));
                }
            }
        }
        
        // 3. 텐서 준비 및 입력 설정
        auto inputTensor = self.recPredictor->GetInput(0);
        std::vector<int64_t> inputShape = {1, 3, targetHeight, targetWidth};
        inputTensor->Resize(inputShape);
        
        // 정규화 (PP-OCR Recognition 모델에 맞는 정규화)
        // 일반적으로 mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5] 또는 [1/0.5, 1/0.5, 1/0.5]
        float mean[3] = {0.5f, 0.5f, 0.5f};
        float scale_values[3] = {2.0f, 2.0f, 2.0f}; // 1.0 / 0.5
        
        float* inputData = inputTensor->mutable_data<float>();
        for (int i = 0; i < targetHeight * targetWidth; i++) {
            for (int c = 0; c < 3; c++) {
                int idx = i * 3 + c;
                float pixel = resizedData[idx] / 255.0f;
                inputData[c * targetHeight * targetWidth + i] = (pixel - mean[c]) * scale_values[c];
            }
        }
        
        // 4. 모델 실행
        self.recPredictor->Run();
        
        // 5. 출력 텐서 가져오기
        auto outputTensor = self.recPredictor->GetOutput(0);
        auto outputShape = outputTensor->shape();
        const float* outputData = outputTensor->data<float>();
        
        // 6. 출력 파싱 (Recognition 모델 출력 형식: [batch, seq_len, num_classes])
        int seqLen = outputShape[1];
        int numClasses = outputShape[2];
        
        // CTC 디코딩 또는 argmax로 문자 인덱스 추출
        std::vector<int> charIndices;
        for (int t = 0; t < seqLen; t++) {
            int maxIdx = 0;
            float maxProb = outputData[t * numClasses];
            for (int c = 1; c < numClasses; c++) {
                float prob = outputData[t * numClasses + c];
                if (prob > maxProb) {
                    maxProb = prob;
                    maxIdx = c;
                }
            }
            // CTC blank 제거 및 중복 제거
            if (maxIdx > 0 && (charIndices.empty() || charIndices.back() != maxIdx)) {
                charIndices.push_back(maxIdx);
            }
        }
        
        // 7. 딕셔너리로 텍스트 변환
        NSMutableString *resultText = [NSMutableString string];
        for (int idx : charIndices) {
            if (idx > 0 && idx <= (int)self.dictionary.count) {
                NSString *charStr = self.dictionary[idx - 1];
                [resultText appendString:charStr];
            }
        }
        
        NSLog(@"✅ Recognition 완료: %@", resultText);
        return [resultText copy];
        
    } catch (const std::exception &e) {
        NSLog(@"❌ Recognition 실행 오류: %s", e.what());
        return @"";
    }
}

@end
