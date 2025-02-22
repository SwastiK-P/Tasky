import SwiftUI

struct TodoRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    let todo: TodoItem
    let toggleAction: () -> Void
    @ObservedObject var viewModel: TodoListViewModel
    @StateObject private var workSessionViewModel = WorkSessionViewModel()
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
    @State private var showingWorkSession = false
    @State private var showingDetails = false
    @State private var showingLocationSheet = false
    @State private var selectedLocation: TodoItem.Location?
    
    var body: some View {
        mainContent
            .onChange(of: workSessionViewModel.isActive) { isActive in
                if isActive {
                    showingWorkSession = true
                }
            }
            .onChange(of: workSessionViewModel.isPaused) { isPaused in
                if isPaused {
                    showingWorkSession = true
                }
            }
            .sheet(isPresented: $showingLocationSheet) {
                if let location = selectedLocation {
                    LocationDetailView(location: location)
                }
            }
    }
    
    private var mainContent: some View {
        Button {
            showingDetails = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                checkmarkButton
                contentStack
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetails = true
        }
        .padding(.vertical, 4)
        .listRowBackground(rowBackground)
        .contextMenu { contextMenuContent }
        .sheet(isPresented: $showingEditSheet) {
            EditTodoView(todo: todo, viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingWorkSession) {
            WorkSessionView(workSessionViewModel: workSessionViewModel, todoViewModel: viewModel, todo: todo)
        }
        .sheet(isPresented: $showingDetails) {
            TodoDetailsView(todo: todo, viewModel: viewModel, imageViewerData: $imageViewerData)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            shouldAnimate = false
            detectURLInNotes()
            if workSessionViewModel.isActive || workSessionViewModel.isPaused {
                showingWorkSession = true
            }
        }
        .onChange(of: todo.notes) { _ in
            detectURLInNotes()
        }
        .onPreferenceChange(ImageFramePreferenceKey.self) { frames in
            selectedImageFrame = frames[selectedImageIndex]
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            if !todo.isCompleted {
                HapticManager.shared.impact(style: .medium)
                showingWorkSession = true
            }
        }
    }
    
    private var checkmarkButton: some View {
        Button(action: {
            handleTodoCompletion()
        }) {
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(.gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(todo.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
                .animatedStrikethrough(isActive: shouldAnimate)
            
            if let url = detectedURL {
                urlPreview(url)
            } else if let note = todo.notes, !note.isEmpty {
                if !note.isEmpty && note.count > 75 {
                    HStack(spacing: 3) {
                        Image(systemName: "note.text")
                        Text("Note")
                    }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.secondary)
                        .background(Color(.gray).opacity(0.2))
                        .cornerRadius(8)
                } else {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let images = todo.images, !images.isEmpty, images.contains(where: { !$0.isEmpty }) {
                imageScrollView(images)
            }
            tagsRow
        }
    }
    
    private var tagsRow: some View {
        HStack(spacing: 8) {
            categoryTag
            if let dueDate = todo.dueDate {
                if todo.priority != .high || todo.location == nil {
                    dueDateTag(dueDate)
                }
            }
            if todo.priority == .high {
                priorityTag
            }
            if todo.location != nil {
                locationTag
            }
        }
    }
    
    private var categoryTag: some View {
        Text(todo.category.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(todo.category.color.opacity(0.2))
            .foregroundColor(todo.category.color)
            .cornerRadius(8)
    }
    
    private func dueDateTag(_ date: Date) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar")
            Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
        }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .font(.caption)
            .foregroundStyle(.secondary)
            .background(Color(.gray).opacity(0.2))
            .cornerRadius(8)
    }
    
    private var priorityTag: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Priority")
        }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .font(.caption)
            .foregroundStyle(.red)
            .background(Color(.red).opacity(0.2))
            .cornerRadius(8)
    }
    
    private var locationTag: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
            Text("Location")
        }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .font(.caption)
            .foregroundStyle(.blue)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            .onTapGesture {
                if let location = todo.location {
                    showLocationDetail(location)
                }
            }
    }
    
    private func showLocationDetail(_ location: TodoItem.Location) {
        selectedLocation = location
        showingLocationSheet = true
    }
    
    private func urlPreview(_ url: URL) -> some View {
        Button(action: {
            UIApplication.shared.open(url)
        }) {
            CompactLinkPreviewView(url: url)
        }
    }
    
    private func imageScrollView(_ images: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(images.prefix(5).enumerated()), id: \.element) { index, imageName in
                    if let image = loadImage(named: imageName) {
                        imageButton(image: image, index: index)
                    }
                }
            }
            .padding(.vertical, 4)
        }.scrollDisabled(true)
    }
    
    private func imageButton(image: UIImage, index: Int) -> some View {
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
    
    private var rowBackground: some View {
        todo.category.color.opacity(colorScheme == .dark ? 0.25 : 0.10)
    }
    
    private var contextMenuContent: some View {
        Group {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                showingDetails = true
            } label: {
                Label("Show Details", systemImage: "doc.richtext")
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
            
            if !todo.isCompleted {
                Button {
                    showingWorkSession = true
                } label: {
                    Label("Start Working", systemImage: "timer")
                }
            }
            
            Button(role: .destructive) {
                viewModel.deleteTodo(todo)
            } label: {
                Label("Delete", systemImage: "trash")
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            toggleAction()
            isStrikingThrough = false
            shouldAnimate = false
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
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: notes, options: [], range: NSRange(location: 0, length: notes.utf16.count))
        
        if let firstMatch = matches?.first,
           let range = Range(firstMatch.range, in: notes),
           let url = URL(string: String(notes[range])) {
            detectedURL = url
        } else {
            detectedURL = nil
        }
    }
}

struct ImageFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
