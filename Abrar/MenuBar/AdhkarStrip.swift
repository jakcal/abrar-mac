import SwiftUI

/// Nudges toward the adhkar for this time of day until they're done.
struct AdhkarStrip: View {
    let session: AdhkarSession
    var open: () -> Void

    @Environment(AdhkarModel.self) private var adhkar

    var body: some View {
        let done = adhkar.completedCount(in: session)
        let total = AdhkarCatalog.items(for: session).count
        Button(action: open) {
            HStack(spacing: 10) {
                Image(systemName: session.symbolName)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(done == 0 ? "Not started today" : "\(done) of \(total) done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 14)
        .help("Open the \(session.title.lowercased())")
    }
}
