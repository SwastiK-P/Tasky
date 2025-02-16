import SwiftUI

struct WorkSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var workSessionViewModel: WorkSessionViewModel
    @ObservedObject var todoViewModel: TodoListViewModel
    let todo: TodoItem
    
    @State private var selectedDuration: TimeInterval = 25 * 60
    @State private var showingCustomDuration = false
    @State private var customHours: Int = 0
    @State private var customMinutes: Int = 25
    
    private let availableDurations: [(String, TimeInterval)] = [
        ("5 minutes", 5 * 60),
        ("10 minutes", 10 * 60),
        ("15 minutes", 15 * 60),
        ("25 minutes", 25 * 60),
        ("30 minutes", 30 * 60),
        ("45 minutes", 45 * 60),
        ("1 hour", 60 * 60),
        ("Custom", 0)
    ]
    
    private let availableHours = Array(0...12)
    private let availableMinutes = Array(0...59)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Static gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        todo.category.color.opacity(0.8),
                        todo.category.color.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if workSessionViewModel.currentSession == nil && !workSessionViewModel.isPaused && workSessionViewModel.timeRemaining == 0 && !workSessionViewModel.isCompleted {
                    durationPickerView
                } else {
                    timerView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(workSessionViewModel.currentSession != nil || workSessionViewModel.isPaused || workSessionViewModel.isCompleted)
        }
        .navigationViewStyle(.stack)
        .alert("Session Complete", isPresented: $workSessionViewModel.showCompletionAlert) {
            Button("Mark as Incomplete") {
                withAnimation {
                    // Save the work session to the todo item
                    var updatedTodo = todo
                    var sessions = updatedTodo.workSessions ?? []
                    if let session = workSessionViewModel.currentSession {
                        sessions.append(session)
                    }
                    updatedTodo.workSessions = sessions
                    todoViewModel.updateTodo(updatedTodo)
                    
                    todoViewModel.objectWillChange.send()
                    workSessionViewModel.resetSession()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
            Button("Mark as Complete") {
                withAnimation {
                    // Save the work session to the todo item
                    var updatedTodo = todo
                    var sessions = updatedTodo.workSessions ?? []
                    if let session = workSessionViewModel.currentSession {
                        sessions.append(session)
                    }
                    updatedTodo.workSessions = sessions
                    todoViewModel.updateTodo(updatedTodo)
                    
                    HapticManager.shared.notification(type: .success)
                    todoViewModel.toggleTodo(updatedTodo)
                    workSessionViewModel.resetSession()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Would you like to mark this task as complete?")
        }
        .interactiveDismissDisabled()
        .sheet(isPresented: $showingCustomDuration) {
            customDurationPicker
        }
        .onDisappear {
            if !workSessionViewModel.isActive && !workSessionViewModel.isCompleted && !workSessionViewModel.isPaused {
                workSessionViewModel.resetSession()
            }
        }
        .presentationDragIndicator(.visible)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                // Let ViewModel handle the state
                break
            case .inactive:
                // App is in inactive state (control center, etc)
                break
            case .active:
                // App is active again
                break
            @unknown default:
                break
            }
        }
    }
    
    private var customDurationPicker: some View {
        NavigationView {
            VStack(spacing: 32) {
                HStack(spacing: 20) {
                    // Hours Picker
                    VStack {
                        Picker("Hours", selection: $customHours) {
                            ForEach(availableHours, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                        
                        Text("Hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, -24)
                    
                    // Minutes Picker
                    VStack {
                        Picker("Minutes", selection: $customMinutes) {
                            ForEach(availableMinutes, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                        
                        Text("Minutes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Set Custom Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Material.regular, for: .navigationBar)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingCustomDuration = false
                },
                trailing: Button("Start") {
                    let totalSeconds = (customHours * 3600) + (customMinutes * 60)
                    if totalSeconds > 0 {
                        selectedDuration = TimeInterval(totalSeconds)
                        showingCustomDuration = false
                        HapticManager.shared.impact(style: .light)
                        workSessionViewModel.startSession(for: todo.id, duration: selectedDuration)
                    }
                }
                .disabled(customHours == 0 && customMinutes == 0)
            )
        }
        .presentationDetents([.height(400)])
    }
    
    private var durationPickerView: some View {
        VStack(spacing: 24) {
            Text("Set Timer Duration")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 140), spacing: 16)
            ], spacing: 16) {
                ForEach(availableDurations, id: \.1) { duration in
                    Button {
                        if duration.1 == 0 {
                            showingCustomDuration = true
                        } else {
                            selectedDuration = duration.1
                            HapticManager.shared.impact(style: .light)
                            workSessionViewModel.startSession(for: todo.id, duration: duration.1)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(duration.0)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            if duration.1 > 0 {
                                Text(formatDuration(duration.1))
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 32) {
            // Title and task info
            VStack(spacing: 8) {
                Text("Working on")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(todo.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            
            // Timer circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(lineWidth: 20)
                    .foregroundColor(.white.opacity(0.2))
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: workSessionViewModel.progress)
                    .stroke(style: StrokeStyle(
                        lineWidth: 20,
                        lineCap: .round
                    ))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: workSessionViewModel.progress)
                
                // Time remaining
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        TimeNumberView(timeString: String(format: "%02d", Int(workSessionViewModel.timeRemaining) / 60))
                        Text(":")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        TimeNumberView(timeString: String(format: "%02d", Int(workSessionViewModel.timeRemaining) % 60))
                    }
                    
                    Text(workSessionViewModel.isCompleted ? "Completed" : workSessionViewModel.isActive ? "Remaining" : "Paused")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 280, height: 280)
            .padding(.vertical, 32)
            
            // Control buttons
            HStack(spacing: 40) {
                // Reset button
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    workSessionViewModel.resetSession()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Play/Pause button
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    if workSessionViewModel.isActive {
                        workSessionViewModel.pauseSession()
                    } else if workSessionViewModel.timeRemaining > 0 {
                        workSessionViewModel.resumeSession()
                    }
                }) {
                    Image(systemName: workSessionViewModel.isActive ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                }
                .disabled(workSessionViewModel.isCompleted)
                
                // End button
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    workSessionViewModel.endSession()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

struct TimeNumberView: View {
    let timeString: String
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 60, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .contentTransition(.numericText())
            .transaction { transaction in
                transaction.animation = .spring(response: 0.3, dampingFraction: 0.7)
            }
    }
} 
