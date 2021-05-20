import Foundation
import Alamofire

enum ImaggaRouter: URLRequestConvertible {
  enum Constants {
    static let baseURLPath = "https://api.imagga.com/v2"
  }
  
  case upload
  case tags(String)
  case colors(String)
  
  var method: HTTPMethod {
    switch self {
    case .upload:
      return .post
    case .tags, .colors:
      return .get
    }
  }
  
  var path: String {
    switch self {
    case .upload:
      return "/uploads"
    case .tags:
      return "/tags"
    case .colors:
      return "/colors"
    }
  }
  
  var parameters: [String: Any] {
    switch self {
    case .tags(let contentID):
      return ["image_upload_id": contentID]
    case .colors(let contentID):
      return ["image_upload_id": contentID, "extract_object_colors": 0]
    default:
      return [:]
    }
  }
  
  func asURLRequest() throws -> URLRequest {
    let url = try Constants.baseURLPath.asURL()
    var request = URLRequest(url: url.appendingPathComponent(path))
    request.httpMethod = method.rawValue
    request.timeoutInterval = TimeInterval(10*1000)
    return try URLEncoding.default.encode(request, with: parameters)
  }
}
