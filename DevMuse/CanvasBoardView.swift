import SwiftUI

struct CardEditorRoute: Identifiable {
    let id = UUID()
    let card: NoteCard
    let isNew: Bool
}

struct CanvasBoardView: View {
    @EnvironmentObject private var store: MuseStore
    @State private var zoom: CGFloat = 1
    @State private var anchorZoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var anchorPan: CGSize = .zero
    @State private var draggingID: UUID?
    @State private var dragTranslation: CGSize = .zero
    @State private var editorRoute: CardEditorRoute?

    private let cardWidth: CGFloat = 208

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                MuseTheme.paper
                    .ignoresSafeArea()

                DotGrid()

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(panGesture)
                    .simultaneousGesture(zoomGesture(in: proxy.size))

                ForEach(store.cards) { card in
                    cardNode(card)
                }

                if store.cards.isEmpty {
                    emptyState
                }
            }
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                MusePrimaryButton(title: "New note", symbol: "plus") {
                    addCard(in: proxy.size)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .overlay(alignment: .bottomLeading) {
                zoomPill(in: proxy.size)
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topBar
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editorRoute) { route in
            CardEditorSheet(
                card: route.card,
                isNew: route.isNew,
                onSave: { card in
                    if route.isNew {
                        store.addCard(card)
                    } else {
                        store.updateCard(card)
                    }
                },
                onDelete: {
                    if !route.isNew {
                        store.deleteCard(route.card.id)
                    }
                }
            )
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("BOARD")
                    .font(MuseFont.mono(10, .semibold))
                    .tracking(2.4)
                    .foregroundColor(MuseTheme.inkFaint)
                Spacer()
                Text("\(store.cards.count) NOTES")
                    .font(MuseFont.mono(10, .medium))
                    .tracking(1.2)
                    .foregroundColor(MuseTheme.inkFaint)
            }
            Text("Thinking Canvas")
                .font(MuseFont.serif(27, .semibold))
                .foregroundColor(MuseTheme.ink)
            MuseHairline()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MuseTheme.paper)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("A blank canvas")
                .font(MuseFont.serif(23, .semibold))
                .foregroundColor(MuseTheme.ink)
            Text("Tap New note to drop your first thought.")
                .font(MuseFont.sans(13))
                .foregroundColor(MuseTheme.inkSoft)
        }
        .padding(24)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private func zoomPill(in size: CGSize) -> some View {
        HStack(spacing: 10) {
            Button {
                changeZoom(by: 0.85, in: size)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .semibold))
            }
            .accessibilityLabel("Zoom out")

            Text("\(Int(zoom * 100))%")
                .font(MuseFont.mono(10, .medium))
                .frame(width: 38)

            Button {
                changeZoom(by: 1.18, in: size)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
            }
            .accessibilityLabel("Zoom in")

            Rectangle()
                .fill(MuseTheme.hairline)
                .frame(width: 1, height: 16)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    zoom = 1
                    pan = .zero
                    anchorZoom = 1
                    anchorPan = .zero
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 11, weight: .semibold))
            }
            .accessibilityLabel("Reset view")
        }
        .foregroundColor(MuseTheme.inkSoft)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(MuseTheme.surface)
        )
        .overlay(
            Capsule()
                .strokeBorder(MuseTheme.hairline, lineWidth: 1)
        )
        .shadow(color: MuseTheme.shadow, radius: 8, x: 0, y: 3)
    }

    private func cardNode(_ card: NoteCard) -> some View {
        NoteCardView(card: card, isDragging: draggingID == card.id, width: cardWidth)
            .scaleEffect(zoom)
            .position(
                x: CGFloat(card.x) * zoom + pan.width,
                y: CGFloat(card.y) * zoom + pan.height
            )
            .offset(
                x: draggingID == card.id ? dragTranslation.width : 0,
                y: draggingID == card.id ? dragTranslation.height : 0
            )
            .gesture(cardGesture(card))
            .onTapGesture {
                editorRoute = CardEditorRoute(card: card, isNew: false)
            }
            .contextMenu {
                Button {
                    editorRoute = CardEditorRoute(card: card, isNew: false)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    store.deleteCard(card.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(card.kind.label): \(card.title)")
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                pan = CGSize(
                    width: anchorPan.width + value.translation.width,
                    height: anchorPan.height + value.translation.height
                )
            }
            .onEnded { _ in
                anchorPan = pan
            }
    }

    private func zoomGesture(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let next = min(max(anchorZoom * value, 0.4), 2.2)
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let ratio = next / anchorZoom
                pan = CGSize(
                    width: center.x - (center.x - anchorPan.width) * ratio,
                    height: center.y - (center.y - anchorPan.height) * ratio
                )
                zoom = next
            }
            .onEnded { _ in
                anchorZoom = zoom
                anchorPan = pan
            }
    }

    private func cardGesture(_ card: NoteCard) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                draggingID = card.id
                dragTranslation = value.translation
            }
            .onEnded { value in
                store.moveCard(
                    card.id,
                    dx: Double(value.translation.width / zoom),
                    dy: Double(value.translation.height / zoom)
                )
                draggingID = nil
                dragTranslation = .zero
            }
    }

    private func changeZoom(by factor: CGFloat, in size: CGSize) {
        let next = min(max(zoom * factor, 0.4), 2.2)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let ratio = next / zoom
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            pan = CGSize(
                width: center.x - (center.x - pan.width) * ratio,
                height: center.y - (center.y - pan.height) * ratio
            )
            zoom = next
        }
        anchorZoom = next
        anchorPan = pan
    }

    private func addCard(in size: CGSize) {
        let worldX = (size.width / 2 - pan.width) / zoom
        let worldY = (size.height / 2 - pan.height) / zoom
        let card = NoteCard(
            title: "",
            body: "",
            kind: .idea,
            x: Double(worldX),
            y: Double(worldY)
        )
        editorRoute = CardEditorRoute(card: card, isNew: true)
    }
}

struct NoteCardView: View {
    let card: NoteCard
    let isDragging: Bool
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: card.kind.symbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(card.kind.label.uppercased())
                    .font(MuseFont.mono(9, .semibold))
                    .tracking(1.2)
                Spacer(minLength: 0)
            }
            .foregroundColor(card.kind.tint)

            Text(card.title.isEmpty ? "Untitled" : card.title)
                .font(MuseFont.serif(19, .semibold))
                .foregroundColor(MuseTheme.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            if !card.body.isEmpty {
                Text(card.body)
                    .font(MuseFont.sans(12))
                    .foregroundColor(MuseTheme.inkSoft)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
            }

            HStack(spacing: 5) {
                Rectangle()
                    .fill(card.kind.tint.opacity(0.45))
                    .frame(width: 16, height: 1)
                Text(card.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(MuseFont.mono(9))
                    .foregroundColor(MuseTheme.inkFaint)
            }
        }
        .padding(16)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MuseTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isDragging ? card.kind.tint.opacity(0.55) : MuseTheme.hairline,
                    lineWidth: 1
                )
        )
        .shadow(
            color: MuseTheme.shadow,
            radius: isDragging ? 16 : 9,
            x: 0,
            y: isDragging ? 9 : 4
        )
    }
}
