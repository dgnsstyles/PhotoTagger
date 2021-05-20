import Foundation

struct PhotoColorsResponse: Codable {
  let result: Result
  
  struct Result: Codable {
    let colors: PictureColors
    
    struct PictureColors: Codable {
      
      let imageColors: [Colors]
      
      enum CodingKeys: String, CodingKey {
          case imageColors = "image_colors"
      }
      
      struct Colors: Codable {
        let blue: Int
        let red: Int
        let green: Int
        let closestPaletteColor: String
        
        enum CodingKeys: String, CodingKey {
            case blue = "b"
            case red = "r"
            case green = "g"
            case closestPaletteColor = "closest_palette_color"
        }
      }
    }
  }
}
