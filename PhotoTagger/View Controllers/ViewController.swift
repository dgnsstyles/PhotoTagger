import UIKit
import Alamofire

class ViewController: UIViewController {
  
  // MARK: - IBOutlets
  @IBOutlet var takePictureButton: UIButton!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var progressView: UIProgressView!
  @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
  @IBOutlet weak var downloadSampleImageButton: UIButton!
  
  
  // MARK: - Properties
  private var tags: [String]?
  private var colors: [PhotoColor]?
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if !UIImagePickerController.isSourceTypeAvailable(.camera) {
      takePictureButton.setTitle("Select Photo", for: .normal)
    }
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    imageView.image = nil
  }
  
  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    
    if segue.identifier == "ShowResults",
      let controller = segue.destination as? TagsColorsViewController {
      controller.tags = tags
      controller.colors = colors
    }
  }
  
  // MARK: - IBActions
  @IBAction func takePicture(_ sender: UIButton) {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.allowsEditing = false
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      picker.sourceType = .camera
    } else {
      picker.sourceType = .photoLibrary
      picker.modalPresentationStyle = .fullScreen
    }
    
    present(picker, animated: true)
  }
  
  @IBAction func downloadSampleImage(_ sender: UIButton) {
    takePictureButton.isHidden = true
    downloadSampleImageButton.isHidden = true
    progressView.progress = 0.0
    progressView.isHidden = false
    activityIndicatorView.startAnimating()
    downloadSampleImage(progressCompletion: { [unowned self] percent in
      self.progressView.setProgress(percent, animated: true)
    }) { [unowned self] tags, colors in
      self.takePictureButton.isHidden = false
      self.downloadSampleImageButton.isHidden = false
      self.progressView.isHidden = true
      self.activityIndicatorView.stopAnimating()
      
      self.tags = tags
      self.colors = colors
      self.performSegue(withIdentifier: "ShowResults", sender: self)
    }
  }
  
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
  {
    guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
      print("Info did not have the required UIImage for the Original Image")
      dismiss(animated: true)
      return
    }
    
    imageView.image = image
    
    takePictureButton.isHidden = true
    downloadSampleImageButton.isHidden = true
    progressView.progress = 0.0
    progressView.isHidden = false
    activityIndicatorView.startAnimating()
    
    upload(image: image,
           progressCompletion: { [unowned self] percent in
            self.progressView.setProgress(percent, animated: true)
      },
           completion: { [unowned self] tags, colors in
            self.takePictureButton.isHidden = false
            self.downloadSampleImageButton.isHidden = false
            self.progressView.isHidden = true
            self.activityIndicatorView.stopAnimating()
            
            self.tags = tags
            self.colors = colors
            
            self.performSegue(withIdentifier: "ShowResults", sender: self)
    })
    
    dismiss(animated: true)
  }
}

// MARK: - Networking calls
extension ViewController {
  func upload(image: UIImage,
              progressCompletion: @escaping (_ percent: Float) -> Void,
              completion: @escaping (_ tags: [String]?, _ colors: [PhotoColor]?) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.5) else {
      print("Could not get JPEG representation of UIImage")
      return
    }
    NetworkClient.upload(multipartFormData: { multipartFormData in
      multipartFormData.append(imageData, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
    }, with: ImaggaRouter.upload)
      .uploadProgress { progress in
        progressCompletion(Float(progress.fractionCompleted))
      }.responseDecodable(of: UploadImageResponse.self) { response in
        switch response.result {
        case .failure(let error):
          print("Error uploading file: \(error)")
          completion(nil, nil)
        case .success(let uploadResponse):
          let resultID = uploadResponse.result.uploadID
          print("Content uploaded with ID: \(resultID)")
          self.downloadTags(contentID: resultID) { tags in
            self.downloadColors(contentID: resultID) { colors in
              completion(tags, colors)
            }
          }
        }
    }
  }
  
  func downloadTags(contentID: String, completion: @escaping ([String]?) -> Void) {
    NetworkClient.request(ImaggaRouter.tags(contentID))
      .responseDecodable(of: PhotoTagsResponse.self) { response in
        switch response.result {
        case .failure(let error):
          print("Error while fetching tags: \(String(describing: error))")
          completion(nil)
          return
        case.success(let tagsResponse):
          let tags = tagsResponse.result.tags.map { $0.tag.en }
          completion(tags)
        }
    }
  }
  
  func downloadColors(contentID: String, completion: @escaping ([PhotoColor]?) -> Void) {
    NetworkClient.request(ImaggaRouter.colors(contentID))
      .responseDecodable(of: PhotoColorsResponse.self) { response in
        switch response.result {
        case .failure(let error):
          print("Error while fetching colors: \(String(describing: error))")
          completion(nil)
          return
        case .success(let colorsResponse):
          let imageColors = colorsResponse.result.colors.imageColors.map { PhotoColor(red: $0.red, green: $0.green, blue: $0.blue, colorName: $0.closestPaletteColor) }
          completion(imageColors)
          return
        }
    }
  }
  
  func downloadSampleImage(progressCompletion: @escaping (_ percent: Float) -> Void,
                           completion: @escaping (_ tags: [String]?, _ colors: [PhotoColor]?) -> Void) {
    let imageURL = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Wikipedia-logo-v2-en.svg/1200px-Wikipedia-logo-v2-en.svg.png"
    NetworkClient.download(imageURL).downloadProgress { progress in
      progressCompletion(Float(progress.fractionCompleted))
    }.responseData { response in
      switch response.result {
      case .failure(let error):
        print("Error while fetching the image: \(error)")
        completion(nil, nil)
      case .success(let photoData):
        guard let image = UIImage(data: photoData) else {
          print("Error while converting the image data to a UIImage")
          completion(nil, nil)
          return
        }
        self.upload(image: image, progressCompletion: progressCompletion, completion: completion)
      }
    }
  }
}
