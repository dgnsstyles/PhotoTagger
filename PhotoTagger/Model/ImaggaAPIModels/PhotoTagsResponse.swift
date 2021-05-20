

import Foundation

struct PhotoTagsResponse: Codable {
  let result: TagsResults
  
  struct TagsResults: Codable {
    let tags: [Tag]
  }
  
  struct Tag: Codable {
    let confidence: Double
    let tag: TagInformation
    
    struct TagInformation: Codable {
      let en: String
    }
  }
}
