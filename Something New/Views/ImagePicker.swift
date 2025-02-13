import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var showingImagePicker = false
    
    var body: some View {
        Button {
            showingImagePicker = true
        } label: {
            Text("Add Images")
                .foregroundStyle(.blue)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImages: $selectedImages)
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 4
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            self.parent.dismiss()
            
            guard !results.isEmpty else { return }
            
            let group = DispatchGroup()
            var images: [UIImage] = []
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) { [weak self] in
                self?.parent.selectedImages = images
            }
        }
    }
} 