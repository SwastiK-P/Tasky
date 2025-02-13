import SwiftUI
import SharedModels

struct TodoWidgetConfiguration: View {
    let category: SharedModels.Category?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
                Text(category?.rawValue ?? "All Categories")
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            Text("Shows tasks from \(category?.rawValue ?? "all categories")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
