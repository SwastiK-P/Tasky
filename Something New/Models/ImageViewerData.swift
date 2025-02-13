import SwiftUI

struct ImageViewerData: Equatable {
    let image: UIImage
    let frame: CGRect
    
    static func == (lhs: ImageViewerData, rhs: ImageViewerData) -> Bool {
        lhs.image === rhs.image && lhs.frame == rhs.frame
    }
} 