import SwiftUI

/// Daily adhkar with a counter on each one. Click a card (or press Space) to count.
struct AdhkarView: View {
    @Environment(AdhkarModel.self) private var model

    var body: some View {
        @Bindable var model = model
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    AdhkarHeader(session: model.session, done: model.completedCount(in: model.session), total: model.items.count)
                        .padding(.bottom, 4)
                    ForEach(model.items) { item in
                        AdhkarCard(item: item) { count(item, proxy: proxy) }
                            .id(item.id)
                    }
                    if model.nextItem == nil {
                        CompletionNote()
                            .id("done")
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: 680)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .id(model.session)
            .background {
                Button("Count") {
                    if let next = model.nextItem { count(next, proxy: proxy) }
                }
                .keyboardShortcut(.space, modifiers: [])
                .opacity(0)
                .accessibilityHidden(true)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Adhkar", selection: $model.session) {
                    ForEach(AdhkarSession.allCases) { session in
                        Label(session.displayName, systemImage: session.symbolName).tag(session)
                    }
                }
                .pickerStyle(.segmented)
                .labelStyle(.titleOnly)
                .fixedSize()
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Start Over", systemImage: "arrow.counterclockwise", action: model.reset)
                    .help("Reset today's count for this set")
                    .disabled(model.items.allSatisfy { model.count(of: $0) == 0 })
            }
        }
        .frame(minWidth: 480, minHeight: 480)
    }

    private func count(_ item: AdhkarItem, proxy: ScrollViewProxy) {
        guard model.tap(item) else { return }
        let target = model.nextItem?.id ?? "done"
        withAnimation(Motion.scroll) { proxy.scrollTo(target, anchor: .center) }
    }
}

private struct AdhkarHeader: View {
    let session: AdhkarSession
    let done: Int
    let total: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Label(session.title, systemImage: session.symbolName)
                    .font(.title2.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                Text("\(done) of \(total) done · Click a card or press Space to count")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .motion(Motion.standard, value: done)
            }
            Spacer()
            Text(session.arabicTitle)
                .font(QuranFont.font(size: 26))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}

private struct AdhkarCard: View {
    let item: AdhkarItem
    var count: () -> Void

    @Environment(AdhkarModel.self) private var model
    @State private var isHovering = false

    var body: some View {
        let current = model.count(of: item)
        let isDone = current >= item.count
        VStack(alignment: .leading, spacing: 12) {
            if let title = item.title {
                Text(title)
                    .font(.headline)
            }
            Text(model.arabic(for: item))
                .font(QuranFont.font(size: 24))
                .lineSpacing(12)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.layoutDirection, .rightToLeft)
                .textSelection(.enabled)
            Text(item.translation)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(item.source)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                CountBadge(current: current, total: item.count)
            }
        }
        .padding(18)
        .contentCard()
        .background(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .fill(Color.primary.opacity(isHovering && !isDone ? 0.03 : 0))
        )
        .opacity(isDone ? 0.55 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: count)
        .onHover { isHovering = $0 }
        .motion(Motion.standard, value: isDone)
        .motion(Motion.quick, value: isHovering)
        .contextMenu {
            Button("Count", systemImage: "plus", action: count)
                .disabled(isDone)
            Button("Undo", systemImage: "minus") { model.undo(item) }
                .disabled(current == 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(current) of \(item.count)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Count", count)
    }
}

/// Ring that fills as the dhikr is repeated, with the count inside.
private struct CountBadge: View {
    let current: Int
    let total: Int

    var body: some View {
        let isDone = current >= total
        HStack(spacing: 8) {
            if total > 1 {
                Text("\(current) / \(total)")
                    .font(.callout.weight(.medium))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(isDone ? .secondary : .primary)
            }
            ZStack {
                Circle().stroke(Color.primary.opacity(0.1), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: Double(current) / Double(max(total, 1)))
                    .stroke(isDone ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 24, height: 24)
        }
        .motion(Motion.standard, value: current)
    }
}

private struct CompletionNote: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("تَقَبَّلَ اللَّهُ")
                .font(QuranFont.font(size: 28))
            Text("All done for today. May Allah accept it from you.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
