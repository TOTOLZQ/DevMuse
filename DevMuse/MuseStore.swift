import Foundation
import Combine

struct StoreSnapshot: Codable {
    var cards: [NoteCard]
    var snippets: [Snippet]
    var prompts: [PromptIdea]
    var appearance: AppAppearance
}

final class MuseStore: ObservableObject {
    @Published var cards: [NoteCard] = []
    @Published var snippets: [Snippet] = []
    @Published var prompts: [PromptIdea] = []
    @Published var appearance: AppAppearance = .paper

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = directory.appendingPathComponent("muse-store.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(StoreSnapshot.self, from: data) else {
            cards = SeedData.cards
            snippets = SeedData.snippets
            prompts = SeedData.prompts
            appearance = .paper
            return
        }
        cards = snapshot.cards
        snippets = snapshot.snippets
        prompts = snapshot.prompts
        appearance = snapshot.appearance
    }

    func save() {
        let snapshot = StoreSnapshot(
            cards: cards,
            snippets: snippets,
            prompts: prompts,
            appearance: appearance
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func setAppearance(_ value: AppAppearance) {
        appearance = value
        save()
    }

    func addCard(_ card: NoteCard) {
        cards.append(card)
        save()
    }

    func updateCard(_ card: NoteCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index] = card
        save()
    }

    func deleteCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
        save()
    }

    func moveCard(_ id: UUID, dx: Double, dy: Double) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].x += dx
        cards[index].y += dy
        save()
    }

    func addSnippet(_ snippet: Snippet) {
        snippets.insert(snippet, at: 0)
        save()
    }

    func updateSnippet(_ snippet: Snippet) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[index] = snippet
        save()
    }

    func deleteSnippet(_ id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    func addPrompt(_ prompt: PromptIdea) {
        prompts.insert(prompt, at: 0)
        save()
    }

    func updatePrompt(_ prompt: PromptIdea) {
        guard let index = prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        prompts[index] = prompt
        save()
    }

    func deletePrompt(_ id: UUID) {
        prompts.removeAll { $0.id == id }
        save()
    }

    func resetAll() {
        cards = SeedData.cards
        snippets = SeedData.snippets
        prompts = SeedData.prompts
        appearance = .paper
        save()
    }
}
