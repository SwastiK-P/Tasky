import SwiftUI

struct TodoRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let todo: TodoItem
    let toggleAction: () -> Void
    @ObservedObject var viewModel: TodoListViewModel
    @State private var showingEditSheet = false
    @State private var shouldStrike = false
    @State private var isAnimatingStrike = false
    private let strikeHaptics = UIImpactFeedbackGenerator(style: .soft)
    @State private var selectedImage: IdentifiableImage?
    @State private var selectedImageFrame: CGRect?
    @State private var showingImageViewer = false
    @State private var selectedUIImage: UIImage?
    @State private var selectedImageIndex: Int = 0
    @Binding var imageViewerData: ImageViewerData?
    @State private var expandedImage: String?
    @State private var isImageExpanded = false
    @Namespace private var imageTransition
    @State private var detectedURL: URL?
    @State private var isStrikingThrough = false
    @State private var shouldAnimate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    handleTodoCompletion()
                }) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                        .animatedStrikethrough(isActive: shouldAnimate)
                    
                    if let url = detectedURL {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            CompactLinkPreviewView(url: url)
                        }
                    } else if let note = todo.notes {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let images = todo.images, !images.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(Array(images.prefix(4).enumerated()), id: \.element) { index, imageName in
                                    if let image = loadImage(named: imageName) {
                                        Button(action: {
                                            selectedImageIndex = index
                                            if let frame = selectedImageFrame {
                                                withAnimation {
                                                    imageViewerData = ImageViewerData(image: image, frame: frame)
                                                }
                                            }
                                        }) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 30, height: 30)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear
                                                    .preference(key: ImageFramePreferenceKey.self,
                                                              value: [index: geo.frame(in: .global)])
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(todo.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(todo.category.color.opacity(0.2))
                            .foregroundColor(todo.category.color)
                            .cornerRadius(8)
                        
                        if let dueDate = todo.dueDate {
                            Text(dueDate, style: .date)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .background(Color(.gray).opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        if todo.priority == .high {
                            Text("Priority")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .background(Color(.red).opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(
            todo.category.color.opacity(colorScheme == .dark ? 0.25 : 0.10)
        )
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                toggleAction()
            } label: {
                Label(todo.isCompleted ? "Mark Incomplete" : "Mark Complete",
                      systemImage: todo.isCompleted ? "circle" : "checkmark.circle")
            }
            
            if let url = detectedURL {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("Open Link", systemImage: "link")
                }
            }
            
            Button(role: .destructive) {
                viewModel.deleteTodo(todo)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTodoView(todo: todo, viewModel: viewModel)
        }
        .onAppear {
            shouldAnimate = false
            detectURLInNotes()
        }
        .onChange(of: todo.notes) { _ in
            detectURLInNotes()
        }
        .onPreferenceChange(ImageFramePreferenceKey.self) { frames in
            selectedImageFrame = frames[selectedImageIndex]
        }
        .overlay {
            if expandedImage != nil {
                Color.black
                    .opacity(isImageExpanded ? 0.9 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isImageExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            expandedImage = nil
                        }
                    }
                    .zIndex(0)
            }
        }
    }
    
    private func loadImage(named: String) -> UIImage? {
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let imagePath = documentsPath.appendingPathComponent(named)
            return UIImage(contentsOfFile: imagePath.path)
        }
        return nil
    }
    
    private func detectURLInNotes() {
        guard let notes = todo.notes else {
            detectedURL = nil
            return
        }
        
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let range = NSRange(location: 0, length: notes.utf16.count)
            let matches = detector.matches(in: notes, options: [], range: range)
            
            if let firstMatch = matches.first,
               let matchURL = firstMatch.url {
                detectedURL = matchURL
            } else {
                // Fallback for plain URLs
                if let url = URL(string: notes),
                   UIApplication.shared.canOpenURL(url) {
                    detectedURL = url
                } else {
                    detectedURL = nil
                }
            }
        }
    }
    
    private func handleTodoCompletion() {
        guard !isStrikingThrough else { return }
        guard !todo.isCompleted else {
            toggleAction()
            return
        }
        
        isStrikingThrough = true
        shouldAnimate = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            toggleAction()
            isStrikingThrough = false
            shouldAnimate = false
        }
    }
}

struct ImageFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
