import SwiftUI

struct LicenseView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var licenseKey = ""
    @State private var showingError = false
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 40)
                
                Text("License Activation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your license key to unlock all features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("License Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: licenseKey) { newValue in
                            if newValue.count > 16 {
                                licenseKey = String(newValue.prefix(16))
                            }
                        }
                }
                .padding(.horizontal)
                
                Button {
                    isLoading = true
                    feedbackManager.playHaptic(style: .medium)
                    licenseManager.validateLicenseKey(licenseKey) { success in
                        isLoading = false
                        if !success {
                            showingError = true
                        }
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Activate License")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(licenseKey.isEmpty || isLoading)
                
                Spacer()
            }
            .alert("Invalid License", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    feedbackManager.playHaptic(style: .rigid)
                }
            } message: {
                Text("The license key you entered is not valid. Please check and try again.")
            }
        }
    }
} 