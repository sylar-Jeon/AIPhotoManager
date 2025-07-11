
import Vision
import CoreML
import UIKit

// MARK: - ImageClassificationService

/// 이미지 분류를 위한 서비스
/// Vision 프레임워크와 Core ML 모델을 사용하여 이미지의 특징을 식별합니다.
struct ImageClassificationService {
    /// 주어진 `UIImage`를 분류하여 가장 가능성 높은 식별자를 반환합니다.
    /// - Parameters:
    ///   - image: 분류할 `UIImage`
    ///   - completion: 분류 결과를 처리할 클로저. `Result<String, Error>`를 인자로 받습니다.
    func classifyImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // 이미지를 CIImage로 변환
        guard let ciImage = CIImage(image: image) else {
            completion(.failure(ClassificationError.imageConversionFailed))
            return
        }

        // Core ML 모델 로드
        guard let model = try? VNCoreMLModel(for: ResNet50_Int8_LUT().model) else {
            completion(.failure(ClassificationError.modelLoadingFailed))
            return
        }

        // Vision 요청 생성
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            // 분류 결과 처리
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                completion(.failure(ClassificationError.noResults))
                return
            }

            // 가장 신뢰도 높은 결과의 식별자를 반환
            completion(.success(topResult.identifier))
        }

        // Vision 요청 핸들러 실행
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - ClassificationError

enum ClassificationError: Error, LocalizedError {
    case imageConversionFailed
    case modelLoadingFailed
    case noResults

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "이미지를 변환하는 데 실패했습니다."
        case .modelLoadingFailed:
            return "Core ML 모델을 로드하는 데 실패했습니다."
        case .noResults:
            return "분류 결과를 찾을 수 없습니다."
        }
    }
}
