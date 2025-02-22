import SwiftUI

struct ImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    let image: UIImage
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation {
                                    scale = scale > 1 ? 1 : 2
                                    if scale == 1 {
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
            }
            .navigationTitle("Image")
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentColor)
                    }
                }
            }
        }
    }
}

#Preview {
    ImageViewer(image: UIImage(systemName: "photo")!)
        .environmentObject(ThemeManager.shared)
} 
