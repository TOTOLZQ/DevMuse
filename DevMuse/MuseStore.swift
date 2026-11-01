import Foundation
import Combine

struct StoreSnapshot: Codable {
    var cards: [NoteCard]
    var snippets: [Snippet]
    var prompts: [PromptIdea]
    var messages: [AgentMessage]
    var appearance: AppAppearance
}

final class MuseStore: ObservableObject {
    @Published var cards: [NoteCard] = []
    @Published var snippets: [Snippet] = []
    @Published var prompts: [PromptIdea] = []
    @Published var messages: [AgentMessage] = []
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
            messages = SeedData.messages
            appearance = .paper
            return
        }
        cards = snapshot.cards
        snippets = snapshot.snippets
        prompts = snapshot.prompts
        messages = snapshot.messages.isEmpty ? SeedData.messages : snapshot.messages
        appearance = snapshot.appearance
    }

    func save() {
        let snapshot = StoreSnapshot(
            cards: cards,
            snippets: snippets,
            prompts: prompts,
            messages: messages,
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
        messages = SeedData.messages
        appearance = .paper
        save()
    }

    func addUserMessage(_ content: String) {
        messages.append(AgentMessage(role: .user, content: content))
        save()
    }

    func appendAssistantMessage(_ content: String) {
        messages.append(AgentMessage(role: .assistant, content: content))
        save()
    }

    func clearConversation() {
        messages = SeedData.messages
        save()
    }

    func response(for input: String) -> String {
        let text = input.lowercased()
        if text.contains("review") || text.contains("diff") || text.contains("审查") || text.contains("代码审查") || text.contains("评审") {
            return """
            代码审查

            我把这次改动拆成三个独立关注点：

            1. 行为 - 你新增的分支可达，但提前 return 跳过了旧调用方依赖的校验。合并前为新路径补一个单元测试。
            2. 副作用 - 新代码在无隔离的情况下读取共享可变状态。建议包进 actor 或显式传值。
            3. 对外接口 - 错误分支只返回了笼统消息。应透传底层原因，便于调用方恢复。

            结论：单元测试落地后即可发布，其余作为后续跟进。
            """
        }
        if text.contains("refactor") || text.contains("重构") {
            return """
            重构方案

            把副作用推到边界：
            - 将纯核心抽成不带 IO 的自由函数。
            - 返回结果值，不再改动 inout 参数。
            - 由调用方决定何时写盘。

            完成后核心逻辑极易测试：给定输入、断言输出、无需 mock。
            """
        }
        if text.contains("test") || text.contains("测试") {
            return """
            测试方案

            三层覆盖：
            - 单元 - 用边界用例（空、单个、大量、非法）覆盖纯函数。
            - 集成 - 通过公开 API 驱动 store，断言持久化可往返。
            - UI - 为每个界面的空态与一个有数据态拍快照。

            一条规则：每条新分支上线前先有一个失败的测试。
            """
        }
        if text.contains("commit") || text.contains("提交") {
            return """
            提交信息

            fix(core): 停止在 main actor 上修改共享状态

            之前的实现在视图更新周期内写入共享字典，导致读取不一致。
            将写入移到 store 的隔离队列后，并把值返回给调用方。
            """
        }
        if text.contains("ship") || text.contains("release") || text.contains("发布") {
            return """
            发布清单

            - 版本号与打标签的提交一致
            - 签名身份与描述文件已验证
            - Info.plist 没有遗漏新增的 NS* 使用说明
            - 崩溃上报已接入并可符号化
            - 离线路径运行无误
            - 回滚标签存在且指向上一个已知可用构建

            门槛：上传前每一项都必须勾选。
            """
        }
        if text.contains("explain") || text.contains("what is") || text.contains("how") || text.contains("解释") || text.contains("是什么") || text.contains("怎么") || text.contains("如何") {
            return """
            整体结构如下。

            系统是一个由可观察 store 包裹的单一数据源。视图从它读取，用户动作写入它，每次写入都持久化到磁盘。动画由视图层处理，store 对此一无所知。这种分离让逻辑可测、UI 可替换。

            如果你想了解某一部分，告诉我，我可以展开讲。
            """
        }
        return """
        我可以协助代码审查、重构、测试、撰写提交信息、发布清单和概念解释。粘贴一段代码或描述你正在做的事，我会接着处理。
        """
    }
}
