import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = TodoListViewModel()
    @State private var selectedImage: ImageViewerData?
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ContentView(
                viewModel: viewModel,
                imageViewerData: $selectedImage
            )
            
            if let imageData = selectedImage {
                Color.black
                    .ignoresSafeArea()
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isAnimating)
                
                ImageViewerTransition(
                    image: imageData.image,
                    frame: imageData.frame,
                    isPresented: Binding(
                        get: { selectedImage != nil },
                        set: { if !$0 { dismissImage() } }
                    )
                )
            }
        }
        .onChange(of: selectedImage) { newValue in
            if newValue != nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func dismissImage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedImage = nil
        }
    }
} 