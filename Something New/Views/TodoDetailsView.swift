import SwiftUI
import LinkPresentation

struct TodoDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    let todo: TodoItem
    @ObservedObject var viewModel: TodoListViewModel
    @State private var detectedURL: URL?
    @State private var metadata: LPLinkMetadata?
    @State private var showingEditSheet = false
    @State private var showingWorkSession = false
    @StateObject private var workSessionViewModel = WorkSessionViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section("Details") {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(todoStatus)
                                .foregroundStyle(statusColor)
                        }
                        
                        if let completedDate = todo.completedDate {
                            HStack {
                                Text("Completed On")
                                Spacer()
                                Text(completedDate, style: .date)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let workSessions = todo.workSessions, !workSessions.isEmpty, todo.isCompleted {
                            HStack {
                                Text("Total Time")
                                Spacer()
                                Text(formatDuration(workSessions.reduce(0) { $0 + $1.duration }))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let dueDate = todo.dueDate {
                            HStack {
                                Text("Due Date")
                                Spacer()
                                Text(dueDate, style: .date)
                                    .foregroundStyle(isPastDue(dueDate) && !todo.isCompleted ? .red : .secondary)
                            }
                        }
                        
                        HStack {
                            Text("Priority")
                            Spacer()
                            Text(todo.priority.rawValue.capitalized)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(todo.category.rawValue)
                                .foregroundStyle(.secondary)
                        }
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
                    } else if let notes = todo.notes {
                        Section("Notes") {
                            Text(notes)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let workSessions = todo.workSessions, !workSessions.isEmpty {
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
                                if let workSessions = todo.workSessions {
                                    let reversedSessions = Array(workSessions.reversed())
                                    indexSet.forEach { index in
                                        let session = reversedSessions[index]
                                        viewModel.removeWorkSession(session.id, from: todo)
                                    }
                                }
                            }
                        }
                    }
                }
                
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Button {
                            showingEditSheet = true
                            FeedbackManager.shared.playHaptic(style: .light)
                        } label: {
                            HStack {
                                Text("Edit")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if !todo.isCompleted {
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
                            .tint(todo.category.color)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .background(.ultraThinMaterial)
            }
            .navigationTitle(todo.title)
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
            EditTodoView(todo: todo, viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingWorkSession) {
            WorkSessionView(workSessionViewModel: workSessionViewModel, todoViewModel: viewModel, todo: todo)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                if workSessionViewModel.isActive || workSessionViewModel.isPaused {
                    DispatchQueue.main.async {
                        showingWorkSession = true
                    }
                }
            case .background, .inactive:
                break
            @unknown default:
                break
            }
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
        .onAppear {
            detectURLInNotes()
            if let url = detectedURL {
                fetchLinkMetadata(for: url)
            }
            if workSessionViewModel.isActive || workSessionViewModel.isPaused {
                showingWorkSession = true
            }
        }
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
    
    private var todoStatus: String {
        if todo.isCompleted {
            return "Completed"
        } else if let sessions = todo.workSessions, !sessions.isEmpty {
            return "In Progress"
        } else {
            return "Not Started"
        }
    }
    
    private var statusColor: Color {
        if todo.isCompleted {
            return .green
        } else if let sessions = todo.workSessions, !sessions.isEmpty {
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
    
    private func isPastDue(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)
        return dueDay < today
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
