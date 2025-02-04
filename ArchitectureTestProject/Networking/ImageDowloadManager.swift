import UIKit

class ImageDownloadManager {
    
    static let shared = ImageDownloadManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private var ongoingRequests = [UUID: URLSessionDataTask]()
    
    private init() {}
    
    func downloadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) -> UUID? {
        
        let uuid = UUID()
        
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            completion(.success(cachedImage))
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error {
                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }
                completion(.failure(error))
                return
            }
            
            guard let data, let image = UIImage(data: data) else {
                completion(.failure(NSError(domain: "ImageDownloadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"])))
                return
            }
            
            self?.cache.setObject(image, forKey: url.absoluteString as NSString)
            completion(.success(image))
        }
        task.resume()
        ongoingRequests[uuid] = task
        
        return uuid
    }
    
    func cancelDownload(uuid: UUID) {
        ongoingRequests[uuid]?.cancel()
        ongoingRequests.removeValue(forKey: uuid)
    }
}

class Sample2 {
    
    // Example URL
    let imageURL = URL(string: "https://example.com/image.jpg")!
    
    func start() {
        // Download the image
        if let uuid = ImageDownloadManager.shared.downloadImage(from: imageURL, completion: { result in
            switch result {
            case .success(let image):
                print("Image downloaded successfully")
                DispatchQueue.main.async {
                    // Update UI with the downloaded image
                    // imageView.image = image
                }
            case .failure(let error):
                print("Failed to download image: \(error.localizedDescription)")
            }
        }) {
            // Optionally, you can store the UUID to cancel the download later if needed
            // ImageDownloadManager.shared.cancelDownload(uuid)
        }
    }
}
