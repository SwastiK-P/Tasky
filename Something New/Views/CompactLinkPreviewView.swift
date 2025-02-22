import SwiftUI
import LinkPresentation
import Foundation

struct CompactLinkPreviewView: View {
    let url: URL
    @State private var metadata: LPLinkMetadata?
    @State private var isLoading = true
    @State private var previewImage: UIImage?
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Spacer()
                    
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let metadata = metadata {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        if let image = previewImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 30, height: 30)
                        }
                        
                        Text(metadata.title ?? url.host ?? "Link")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text(url.host ?? url.absoluteString)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(6)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.bottom, 4)
        .task {
            await loadMetadata()
        }
    }
    
    private func loadMetadata() async {
        do {
            let provider = LPMetadataProvider()
            let metadata = try await provider.startFetchingMetadata(for: url)
            await MainActor.run {
                self.metadata = metadata
                if let imageProvider = metadata.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.previewImage = image
                            }
                        }
                    }
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}
