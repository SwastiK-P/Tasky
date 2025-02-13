import Foundation
import SwiftUI

class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    private let jsonBinId = "67ae1625acd3cb34a8e0b13f"
    private let apiKey = "$2a$10$EKVrVeqY7jprghWOrzsvluROgbxRLSudY.rw.UurmDiS0Qf6.LkeO"
    
    @Published var isLicensed = false
    @Published var isChecking = true
    @AppStorage("licenseKey") private var storedLicenseKey: String = ""
    
    private init() {
        // Check stored license on launch
        if !storedLicenseKey.isEmpty {
            validateLicenseKey(storedLicenseKey) { success in
                self.isChecking = false
                self.isLicensed = success
            }
        } else {
            isChecking = false
        }
    }
    
    // Update response structure to match JSONBin
    struct LicenseResponse: Codable {
        let record: Record
        
        struct Record: Codable {
            let valid_keys: [String]
        }
    }
    
    func validateLicenseKey(_ key: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let urlString = "https://api.jsonbin.io/v3/b/\(jsonBinId)"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "X-Master-Key")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(LicenseResponse.self, from: data)
                DispatchQueue.main.async {
                    let isValid = response.record.valid_keys.contains(key)
                    self.isLicensed = isValid
                    if isValid {
                        self.storedLicenseKey = key
                    }
                    completion(isValid)
                }
            } catch {
                print("License validation error:", error)
                print("Response data:", String(data: data, encoding: .utf8) ?? "No data")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
} 
