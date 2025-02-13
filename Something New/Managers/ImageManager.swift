import Foundation
import SharedModels
import SwiftUI

class ImageManager: ObservableObject {
    @Published var selectedImages: [UIImage] = []
    
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    func clearImages() {
        selectedImages.removeAll()
    }
} 