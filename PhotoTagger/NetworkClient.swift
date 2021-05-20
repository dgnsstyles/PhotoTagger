import Foundation
import Alamofire

struct NetworkClient {
  
  struct NetworkClientRetrier: RequestInterceptor {
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
      if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 403 {
        completion(.retryWithDelay(1))
      } else {
        completion(.doNotRetryWithError(error))
      }
    }
  }
  
  struct Certificates {
    
    static let imagga = Certificates.certificate(filename: "imagga.com")
    static let wikimedia = Certificates.certificate(filename: "wikimedia.org")
    
    private static func certificate(filename: String) -> SecCertificate {
      let filePath = Bundle.main.path(forResource: filename, ofType: "der")!
      let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
      return SecCertificateCreateWithData(nil, data as CFData)!
    }
  }
  
  static let shared = NetworkClient()
  let session: Session
  let evaluators = [
    "api.imagga.com": PinnedCertificatesTrustEvaluator(certificates: [Certificates.imagga]),
    "upload.wikimedia.org": PinnedCertificatesTrustEvaluator(certificates: [Certificates.wikimedia])
  ]
  let retrier: RequestInterceptor
  
  init() {
    self.retrier = NetworkClientRetrier()
    self.session = Session(interceptor: retrier, serverTrustManager: ServerTrustManager(evaluators: evaluators))
  }
  
  static func request(_ convertible: URLRequestConvertible) -> DataRequest {
    shared.session.request(convertible).validate().authenticate(username: ImaggaCredentials.username, password: ImaggaCredentials.password)
  }
  
  static func download(_ url: String) -> DownloadRequest {
    shared.session.download(url).validate()
  }
  
  static func upload(multipartFormData: @escaping (MultipartFormData) -> Void, with convertible: URLRequestConvertible) -> UploadRequest {
    shared.session.upload(multipartFormData: multipartFormData, with: convertible).validate().authenticate(username: ImaggaCredentials.username, password: ImaggaCredentials.password)
  }
}
