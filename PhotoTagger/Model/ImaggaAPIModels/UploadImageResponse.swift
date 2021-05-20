import Foundation

struct UploadImageResponse: Codable {
  let result: UploadResponseResult
  let status: UploadResponseStatus
  
  struct UploadResponseResult: Codable {
    let uploadID: String
    
    enum CodingKeys: String, CodingKey {
      case uploadID = "upload_id"
    }
  }
  
  struct UploadResponseStatus: Codable {
    let text: String
    let type: String
  }
}
