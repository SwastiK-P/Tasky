import SwiftUI

struct ImageViewerTransition: View {
    let image: UIImage
    let frame: CGRect
    @Binding var isPresented: Bool
    
    @State private var isAnimating = false
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(isAnimating ? (1 - Double(abs(dragOffset.height) / 300)) : 0)
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .scaleEffect(scale)
                    .offset(dragOffset)
                    .position(
                        x: isAnimating ? geometry.size.width/2 : frame.midX,
                        y: isAnimating ? geometry.size.height/2 : frame.midY
                    )
                    .scaleEffect(isAnimating ? 1 : frame.height/geometry.size.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                                let progress = abs(value.translation.height / geometry.size.height)
                                scale = 1 - progress * 0.2
                            }
                            .onEnded { value in
                                let progress = abs(value.translation.height / geometry.size.height)
                                if progress > 0.2 {
                                    close()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        dragOffset = .zero
                                        scale = 1
                                    }
                                }
                            }
                    )
                    .onTapGesture {
                        close()
                    }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isAnimating = true
            }
        }
    }
    
    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isAnimating = false
            dragOffset = .zero
            scale = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
} 