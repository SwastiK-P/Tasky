import SwiftUI

struct CompletedSectionHeader: View {
    let count: Int
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)
                Text("Completed")
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
} 