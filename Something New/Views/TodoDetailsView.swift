import SwiftUI
import LinkPresentation
import MapKit

struct TodoDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    // Core properties
    private let originalTodo: TodoItem
    @ObservedObject var viewModel: TodoListViewModel
    
    // State properties
    @State private var updatedTodo: TodoItem
    @State private var detectedURL: URL?
    @State private var metadata: LPLinkMetadata?
    @State private var showingEditSheet = false
    @State private var showingWorkSession = false
    @State private var selectedImageIndex: Int = 0
    @State private var selectedImageFrame: CGRect?
    @Binding var imageViewerData: ImageViewerData?
    @State private var localImageViewerData: ImageViewerData?
    @StateObject private var workSessionViewModel = WorkSessionViewModel()
    @State private var isNotesExpanded = false
    
    init(todo: TodoItem, viewModel: TodoListViewModel, imageViewerData: Binding<ImageViewerData?>) {
        self.originalTodo = todo
        self.viewModel = viewModel
        self._updatedTodo = State(initialValue: todo)
        self._imageViewerData = imageViewerData
    }
    
    // MARK: - View Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                mainList
                bottomButtons
            }
            .navigationTitle(updatedTodo.title)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTodoView(todo: updatedTodo, viewModel: viewModel)
        }
        
        .fullScreenCover(isPresented: $showingWorkSession) {
            WorkSessionView(workSessionViewModel: workSessionViewModel, todoViewModel: viewModel, todo: updatedTodo)
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhaseChange(phase)
        }
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
        .onChange(of: viewModel.todos) { _ in
            updateTodoIfNeeded()
        }
        .onAppear {
            setupOnAppear()
        }
        .onPreferenceChange(ImageFramePreferenceKey.self) { frames in
            selectedImageFrame = frames[selectedImageIndex]
        }
        .sheet(item: $localImageViewerData) { data in
            ImageViewer(image: data.image)
        }
    }
    
    // MARK: - Main Content Views
    private var mainList: some View {
        List {
            Section("Details") {
                statusRow
                if let completedDate = updatedTodo.completedDate {
                    completedDateRow
                }
                if let workSessions = updatedTodo.workSessions, !workSessions.isEmpty, updatedTodo.isCompleted {
                    totalTimeRow
                }
                if let dueDate = updatedTodo.dueDate {
                    dueDateRow
                }
                priorityRow
                categoryRow
            }
            
            if let url = detectedURL {
                Section("Link") {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        if let metadata = metadata {
                            LinkPreviewView(metadata: metadata)
                        } else {
                            CompactLinkPreviewView(url: url)
                        }
                    }
                }
            }
            
            if let notes = updatedTodo.notes, !notes.isEmpty {
                if detectedURL == nil {
                    Section("Notes") {
                        VStack(alignment: .leading) {
                            Text(isNotesExpanded ? notes : String(notes.prefix(100)) + (notes.count > 100 ? "..." : ""))
                                .foregroundStyle(.secondary)
                                .animation(.easeInOut, value: isNotesExpanded)
                            
                            if notes.count > 100 {
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        FeedbackManager.shared.playHaptic(style: .light)
                                        isNotesExpanded.toggle()
                                    }
                                }) {
                                    Text(isNotesExpanded ? "Read Less" : "Read More")
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                }
            }
            
            if let images = updatedTodo.images, !images.isEmpty {
                Group {
                    Section("Images") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(images.prefix(5).enumerated()), id: \.element) { index, imageName in
                                    if let image = loadImage(named: imageName) {
                                        imageButton(image: image, index: index)
                                            .frame(width: 80, height: 80)
                                            .aspectRatio(contentMode: .fill)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .scrollDisabled(images.count != 4)
                    }
                }
            }
            
            if let location = updatedTodo.location {
                Section("Location") {
                    VStack(spacing: 12) {
                        LocationMapView(
                            location: location,
                            allowsInteraction: false,
                            position: .constant(.camera(MapCamera(
                                centerCoordinate: CLLocationCoordinate2D(
                                    latitude: location.latitude,
                                    longitude: location.longitude
                                ),
                                distance: 1000
                            )))
                        )
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(location.name)
                                .font(.headline)
                            
                            Text(location.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            openInMaps(location)
                        } label: {
                            HStack {
                                Text("Open in Maps")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            if let workSessions = updatedTodo.workSessions, !workSessions.isEmpty {
                Section("Work Sessions") {
                    ForEach(workSessions.reversed()) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(session.startTime, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(session.duration >= session.plannedDuration ? "Completed" : "Incomplete")
                                    .font(.caption)
                                    .foregroundStyle(session.duration >= session.plannedDuration ? .green : .red)
                            }
                            
                            HStack {
                                Text("Planned:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatDuration(session.plannedDuration))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                
                                Text("Worked:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatDuration(session.duration))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        if let workSessions = updatedTodo.workSessions {
                            let reversedSessions = Array(workSessions.reversed())
                            indexSet.forEach { index in
                                let session = reversedSessions[index]
                                viewModel.removeWorkSession(session.id, from: updatedTodo)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                editButton
                if !updatedTodo.isCompleted {
                    startWorkingButton
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Methods
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if workSessionViewModel.isActive || workSessionViewModel.isPaused {
                DispatchQueue.main.async {
                    showingWorkSession = true
                }
            }
            updateTodoIfNeeded()
        case .background, .inactive:
            break
        @unknown default:
            break
        }
    }
    
    private func updateTodoIfNeeded() {
        if let updated = viewModel.todos.first(where: { $0.id == originalTodo.id }) {
            updatedTodo = updated
        }
    }
    
    private func setupOnAppear() {
        detectURLInNotes()
        if let url = detectedURL {
            fetchLinkMetadata(for: url)
        }
        if workSessionViewModel.isActive || workSessionViewModel.isPaused {
            showingWorkSession = true
        }
        updateTodoIfNeeded()
    }
    
    private func fetchLinkMetadata(for url: URL) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            DispatchQueue.main.async {
                if let metadata = metadata {
                    self.metadata = metadata
                }
            }
        }
    }
    
    private func imageButton(image: UIImage, index: Int) -> some View {
        Button(action: {
            selectedImageIndex = index
            if let frame = selectedImageFrame {
                withAnimation {
                    localImageViewerData = ImageViewerData(image: image, frame: frame)
                }
            }
        }) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
    
    private var todoStatus: String {
        if updatedTodo.isCompleted {
            return "Completed"
        } else if let sessions = updatedTodo.workSessions, !sessions.isEmpty {
            return "In Progress"
        } else {
            return "Not Started"
        }
    }
    
    private var statusColor: Color {
        if updatedTodo.isCompleted {
            return .green
        } else if let sessions = updatedTodo.workSessions, !sessions.isEmpty {
            return .blue
        } else {
            return .secondary
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
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
        guard let notes = updatedTodo.notes else {
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
    
    private func isPastDue(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)
        return dueDay < today
    }
    
    private var statusRow: some View {
        HStack {
            Text("Status")
            Spacer()
            Text(todoStatus)
                .foregroundStyle(statusColor)
        }
    }
    
    private var completedDateRow: some View {
        HStack {
            Text("Completed On")
            Spacer()
            Text(updatedTodo.completedDate!, style: .date)
                .foregroundStyle(.secondary)
        }
    }
    
    private var totalTimeRow: some View {
        HStack {
            Text("Total Time")
            Spacer()
            Text(formatDuration(updatedTodo.workSessions!.reduce(0) { $0 + $1.duration }))
                .foregroundStyle(.secondary)
        }
    }
    
    private var dueDateRow: some View {
        HStack {
            Text("Due Date")
            Spacer()
            Text(updatedTodo.dueDate!, style: .date)
                .foregroundStyle(isPastDue(updatedTodo.dueDate!) && !updatedTodo.isCompleted ? .red : .secondary)
        }
    }
    
    private var priorityRow: some View {
        HStack {
            Text("Priority")
            Spacer()
            Text(updatedTodo.priority.rawValue.capitalized)
                .foregroundStyle(.secondary)
        }
    }
    
    private var categoryRow: some View {
        HStack {
            Text("Category")
            Spacer()
            Text(updatedTodo.category.rawValue)
                .foregroundStyle(.secondary)
        }
    }
    
    private var editButton: some View {
        Button {
            showingEditSheet = true
            FeedbackManager.shared.playHaptic(style: .light)
        } label: {
            HStack {
                Text("Edit")
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var startWorkingButton: some View {
        Button {
            showingWorkSession = true
            FeedbackManager.shared.playHaptic(style: .light)
        } label: {
            HStack {
                Text("Start Working")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
        }
        .buttonStyle(.borderedProminent)
        .tint(updatedTodo.category.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func openInMaps(_ location: TodoItem.Location) {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        mapItem.openInMaps()
    }
}

struct LinkPreviewView: View {
    let metadata: LPLinkMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = metadata.title {
                Text(title)
                    .font(.headline)
            }
            
            HStack {
                if let iconProvider = metadata.iconProvider {
                    IconView(iconProvider: iconProvider)
                        .frame(width: 20, height: 20)
                }
                
                Text(metadata.originalURL?.host ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct IconView: UIViewRepresentable {
    let iconProvider: NSItemProvider
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        iconProvider.loadObject(ofClass: UIImage.self) { image, error in
            if let image = image as? UIImage {
                DispatchQueue.main.async {
                    uiView.image = image
                }
            }
        }
    }
}

struct AttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.textContainer.lineFragmentPadding = 0
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = attributedText.string
        
        // Calculate and set the height based on content
        let fixedWidth = uiView.frame.size.width
        let newSize = uiView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        // Only update height if needed
        if uiView.frame.size.height != newSize.height {
            uiView.frame.size.height = newSize.height
            uiView.layoutIfNeeded()
        }
    }
} 
