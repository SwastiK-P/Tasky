import SwiftUI
import UniformTypeIdentifiers

struct DataBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var dataManager = DataManager.shared
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var backupData: Data?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingConfirmation = false
    @State private var selectedFile: URL?
    
    var body: some View {
        List {
            Section {
                Button(action: prepareExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                    }
                }
                
                Button(action: { showingConfirmation = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Data")
                    }
                }
            } footer: {
                Text("Export or import all your todos, settings, and preferences. Your data will be saved as a backup file that you can use to restore your data later.")
            }
        }
        .tint(colorScheme == .dark ? .white : .black)
        .navigationTitle("Backup & Restore")
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showingExporter,
            document: BackupDocument(data: backupData ?? Data()),
            contentType: .taskyBackup,
            defaultFilename: "TaskyBackup"
        ) { result in
            switch result {
            case .success:
                showAlert(title: "Success", message: "Data exported successfully!")
            case .failure(let error):
                showAlert(title: "Export Failed", message: error.localizedDescription)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.taskyBackup],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                // Start accessing the security-scoped resource
                if url.startAccessingSecurityScopedResource() {
                    do {
                        try dataManager.importData(from: url)
                        alertTitle = "Success"
                        alertMessage = "Data imported successfully!"
                        showingAlert = true
                    } catch {
                        alertTitle = "Import Failed"
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                    // Stop accessing the security-scoped resource
                    url.stopAccessingSecurityScopedResource()
                } else {
                    alertTitle = "Access Denied"
                    alertMessage = "Could not access the file."
                    showingAlert = true
                }
            case .failure(let error):
                alertTitle = "Import Failed"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        .onChange(of: selectedFile) { newFile in
            guard let url = newFile else { return }
            do {
                try dataManager.importData(from: url)
                // Notify the user of success
                showingAlert = true
                alertMessage = "Data imported successfully!"
            } catch {
                // Handle error
                showingAlert = true
                alertMessage = "Failed to import data: \(error.localizedDescription)"
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onChange(of: showingAlert) { newValue in
            if newValue {
                print("Alert shown: \(alertTitle) - \(alertMessage)")
            }
        }
        .confirmationDialog(
            "Import Data",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continue") {
                showingImporter = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Importing data will replace all existing data. Make sure to backup your current data first.")
        }
    }
    
    private func prepareExport() {
        do {
            let url = try dataManager.exportData()
            backupData = try Data(contentsOf: url)
            showingExporter = true
        } catch {
            showAlert(title: "Export Failed", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.taskyBackup] }
    static var writableContentTypes: [UTType] { [.taskyBackup] }
    
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
