import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct RootView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]

    private var activeSessions: [ChatSession] {
        sessions.filter { !$0.isDeleted }
    }

    var body: some View {
        Group {
            if settings.riskAccepted {
                MainTabView()
            } else {
                RiskConsentView()
            }
        }
        .task(id: settings.riskAccepted) {
            ensureSessionIfNeeded()
        }
    }

    private func ensureSessionIfNeeded() {
        guard settings.riskAccepted else { return }
        purgeExpiredDeletedSessions()

        if activeSessions.isEmpty {
            let session = ChatSession()
            modelContext.insert(session)
            persist()
            settings.currentSessionID = session.id.uuidString
        } else if settings.currentSessionID.isEmpty {
            settings.currentSessionID = activeSessions.first?.id.uuidString ?? ""
        } else if activeSessions.contains(where: { $0.id.uuidString == settings.currentSessionID }) == false {
            settings.currentSessionID = activeSessions.first?.id.uuidString ?? ""
        }

        if settings.hasAPIKey {
            Task {
                await ChatAPIClient.shared.prepareConnectionIfNeeded(config: settings.providerConfig)
            }
        }
    }

    private func persist() {
        try? modelContext.save()
    }

    private func purgeExpiredDeletedSessions() {
        let now = Date()
        let expired = sessions.filter { session in
            guard let expiry = session.recycleExpiryDate else { return false }
            return expiry <= now
        }

        guard !expired.isEmpty else { return }
        for session in expired {
            modelContext.delete(session)
        }
        persist()
    }
}

private enum AppTab: Hashable {
    case chat
    case history
    case settings
}

private struct MainTabView: View {
    @State private var selectedTab: AppTab = .chat

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatWorkspaceView(selectedTab: $selectedTab)
                .tag(AppTab.chat)
                .tabItem {
                    Label(systemLocalizedText(zh: "对话", en: "Chat"), systemImage: "message.fill")
                }

            HistoryView(selectedTab: $selectedTab)
                .tag(AppTab.history)
                .tabItem {
                    Label(systemLocalizedText(zh: "记录", en: "History"), systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Label(systemLocalizedText(zh: "设置", en: "Settings"), systemImage: "slider.horizontal.3")
                }
        }
        .tint(DebateTheme.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

private struct ChatWorkspaceView: View {
    @Binding var selectedTab: AppTab

    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]

    @State private var draftText = ""
    @State private var streamingText = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showImporter = false
    @State private var shareURL: URL?
    @State private var showClearAlert = false
    @FocusState private var isComposerFocused: Bool

    private var activeSessions: [ChatSession] {
        sessions.filter { !$0.isDeleted }
    }

    private var currentSession: ChatSession? {
        if let selected = activeSessions.first(where: { $0.id.uuidString == settings.currentSessionID }) {
            return selected
        }
        return activeSessions.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session = currentSession {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14) {
                                if session.sortedMessages.isEmpty && streamingText.isEmpty {
                                    WelcomeCard(language: settings.language)
                                }

                                ForEach(session.sortedMessages) { message in
                                    MessageBubble(
                                        message: message,
                                        showsRegenerateAction: message.id == lastAssistantMessageID,
                                        showsSkipAction: shouldShowSkipFormatAction(for: message),
                                        regenerateTitle: systemLocalizedText(zh: "重新生成", en: "Regenerate"),
                                        skipTitle: systemLocalizedText(zh: "先跳过", en: "Skip for now"),
                                        onRegenerate: {
                                            Task {
                                                await regenerate()
                                            }
                                        },
                                        onSkip: {
                                            Task {
                                                await send(explicitText: systemLocalizedText(zh: "先跳过", en: "Skip for now"))
                                            }
                                        }
                                    )
                                    .id(message.id)
                                }

                                if isSending {
                                    StreamingBubble(text: streamingText)
                                        .id("streaming")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                        }
                        .background(DebateTheme.pageGradient)
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            isComposerFocused = false
                        }
                        .onChange(of: session.sortedMessages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: streamingText) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: isComposerFocused) { _, focused in
                            if focused {
                                scrollToBottom(proxy: proxy)

                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(120))
                                    scrollToBottom(proxy: proxy)
                                }

                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(260))
                                    scrollToBottom(proxy: proxy)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No Session", systemImage: "message", description: Text("Create a new session to begin."))
                }
            }
            .onAppear {
                ensureActiveSessionIfNeeded()
            }
            .onChange(of: selectedTab) { _, tab in
                if tab == .chat {
                    ensureActiveSessionIfNeeded()
                }
            }
            .onChange(of: activeSessions.count) { _, _ in
                ensureActiveSessionIfNeeded()
            }
            .onChange(of: settings.currentSessionID) { _, _ in
                ensureActiveSessionIfNeeded()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer
            }
            .overlay(alignment: .top) {
                ChatHeaderBackdrop()
                    .allowsHitTesting(false)
            }
            .toolbar(isComposerFocused ? .hidden : .visible, for: .tabBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        createSession()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(DebateTheme.ink)
                            .frame(width: 44, height: 44)
                            .background(DebateTheme.panel, in: Circle())
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(currentSession?.title ?? "Debate-Coach")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(DebateTheme.ink)
                            .lineLimit(1)
                        Text(systemLocalizedText(zh: "辩论教练", en: "Debate Coach"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DebateTheme.inkSoft)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(systemLocalizedText(zh: "导入会话", en: "Import Session"), systemImage: "square.and.arrow.down") {
                            showImporter = true
                        }

                        if let session = currentSession {
                            Button(systemLocalizedText(zh: "导出 JSON", en: "Export JSON"), systemImage: "square.and.arrow.up") {
                                export(session: session, kind: .json)
                            }

                            Button(systemLocalizedText(zh: "导出 Markdown", en: "Export Markdown"), systemImage: "doc.plaintext") {
                                export(session: session, kind: .markdown)
                            }

                            Button(systemLocalizedText(zh: "导出 JPG", en: "Export JPG"), systemImage: "photo") {
                                export(session: session, kind: .jpg)
                            }

                            Button(systemLocalizedText(zh: "清空当前会话", en: "Clear Current Session"), systemImage: "trash", role: .destructive) {
                                showClearAlert = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DebateTheme.ink)
                            .frame(width: 44, height: 44)
                            .background(DebateTheme.panel, in: Circle())
                    }
                }
            }
            .alert(systemLocalizedText(zh: "提示", en: "Notice"), isPresented: Binding(get: {
                errorMessage != nil
            }, set: { newValue in
                if !newValue { errorMessage = nil }
            })) {
                Button(systemLocalizedText(zh: "好的", en: "OK"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .alert(systemLocalizedText(zh: "清空当前会话？", en: "Clear Current Session?"), isPresented: $showClearAlert) {
                Button(systemLocalizedText(zh: "清空", en: "Clear"), role: .destructive) {
                    clearCurrentSession()
                }
                Button(systemLocalizedText(zh: "取消", en: "Cancel"), role: .cancel) {}
            } message: {
                Text(systemLocalizedText(zh: "这会删除当前本地聊天记录。", en: "This will remove the current local chat history."))
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                handleImport(result)
            }
            .sheet(item: Binding(get: { shareURL.map(ShareURL.init) }, set: { _ in shareURL = nil })) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            if !settings.hasAPIKey {
                Label(systemLocalizedText(zh: "请先在设置中填写 API Key。", en: "Enter your API Key in Settings before sending messages."), systemImage: "key.fill")
                    .font(.footnote)
                    .foregroundStyle(DebateTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
            }

            HStack(alignment: .bottom, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    TextField(
                        settings.language == .zh ? "输入辩题，开始练习..." : "Enter your motion to begin...",
                        text: $draftText,
                        axis: .vertical
                    )
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1 ... 5)
                    .textFieldStyle(.plain)
                    .foregroundStyle(DebateTheme.ink)
                    .disabled(isSending)
                    .focused($isComposerFocused)

                    Button {
                        Task {
                            await send()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(sendButtonEnabled ? DebateTheme.accent : DebateTheme.inkMuted.opacity(0.24))

                            if isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 34, height: 34)
                    }
                    .disabled(!sendButtonEnabled)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(DebateTheme.panelSoft.opacity(0.92), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            ZStack {
                DebateTheme.canvas.opacity(0.96)
                LinearGradient(
                    colors: [
                        DebateTheme.canvas.opacity(0.96),
                        DebateTheme.canvasSecondary.opacity(0.9),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    @MainActor
    private func send(explicitText: String? = nil) async {
        guard let session = currentSession else { return }
        let text = (explicitText ?? draftText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard settings.hasAPIKey else {
            errorMessage = systemLocalizedText(zh: "请先在设置中填写 API Key。", en: "Please enter your API Key in Settings first.")
            return
        }

        let userMessage = ChatMessage(role: .user, content: text, createdAt: .now, session: session)
        session.messages.append(userMessage)
        session.updatedAt = .now
        if session.title == "New Conversation" || session.title == "Imported Session" {
            session.title = SessionTransfer.suggestedTitle(from: text)
        }
        persist()

        draftText = ""
        streamingText = ""
        isSending = true
        isComposerFocused = false

        do {
            let prompt = try PromptLoader.load(language: settings.language)
            let conversation = session.sortedMessages.map { message in
                LLMChatMessage(role: message.role.rawValue, content: message.content)
            }
            let stream = await ChatAPIClient.shared.streamResponse(
                config: settings.providerConfig,
                apiKey: settings.apiKey,
                prompt: prompt,
                conversation: conversation
            )

            for try await chunk in stream {
                streamingText += chunk
            }

            if !streamingText.isEmpty {
                let assistantMessage = ChatMessage(role: .assistant, content: streamingText, createdAt: .now, session: session)
                session.messages.append(assistantMessage)
                session.updatedAt = .now
                persist()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        streamingText = ""
        isSending = false
    }

    @MainActor
    private func regenerate() async {
        guard let session = currentSession else { return }
        var messages = session.sortedMessages
        while let last = messages.last, last.role == .assistant {
            modelContext.delete(last)
            messages.removeLast()
        }

        guard let lastUser = messages.last, lastUser.role == .user else {
            errorMessage = systemLocalizedText(zh: "没有可重新生成的上一条用户消息。", en: "There is no previous user message to regenerate.")
            persist()
            return
        }

        let originalText = lastUser.content
        modelContext.delete(lastUser)
        session.updatedAt = .now
        persist()
        await send(explicitText: originalText)
    }

    private func createSession() {
        if currentSession?.hasContent == false {
            return
        }

        let session = ChatSession()
        modelContext.insert(session)
        settings.currentSessionID = session.id.uuidString
        persist()
    }

    private func ensureActiveSessionIfNeeded() {
        if activeSessions.isEmpty {
            let session = ChatSession()
            modelContext.insert(session)
            settings.currentSessionID = session.id.uuidString
            persist()
        } else if settings.currentSessionID.isEmpty
            || activeSessions.contains(where: { $0.id.uuidString == settings.currentSessionID }) == false {
            settings.currentSessionID = activeSessions.first?.id.uuidString ?? ""
        }
    }

    private func clearCurrentSession() {
        guard let session = currentSession else { return }
        for message in session.messages {
            modelContext.delete(message)
        }
        session.messages.removeAll()
        session.title = "New Conversation"
        session.updatedAt = .now
        persist()
    }

    private func export(session: ChatSession, kind: ExportKind) {
        do {
            let data: Data
            let fileExtension: String
            switch kind {
            case .json:
                data = try SessionTransfer.exportJSON(from: session)
                fileExtension = "json"
            case .markdown:
                data = SessionTransfer.exportMarkdown(from: session)
                fileExtension = "md"
            case .jpg:
                guard let imageData = exportConversationImage(session: session) else {
                    errorMessage = systemLocalizedText(
                        zh: "JPG 导出失败。当前设备或系统版本可能不支持图片渲染。",
                        en: "JPG export failed. This device or OS version may not support image rendering."
                    )
                    return
                }
                data = imageData
                fileExtension = "jpg"
            }

            let url = FileManager.default.temporaryDirectory.appendingPathComponent(
                SessionTransfer.makeFilename(for: session, ext: fileExtension)
            )
            try data.write(to: url, options: .atomic)
            shareURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func exportConversationImage(session: ChatSession) -> Data? {
        #if os(iOS)
        let snapshot = ChatExportSnapshotView(session: session)
        let hostingController = UIHostingController(rootView: snapshot)
        let targetWidth: CGFloat = 900
        let targetSize = hostingController.sizeThatFits(in: CGSize(width: targetWidth, height: .greatestFiniteMagnitude))

        guard targetSize.width > 0, targetSize.height > 0 else { return nil }

        let maxExportScale: CGFloat = 2
        let maxPixelWidth: CGFloat = 1800
        let maxPixelHeight: CGFloat = 12000
        let maxPixelArea: CGFloat = 28_000_000
        let areaLimitedScale = sqrt(maxPixelArea / (targetSize.width * targetSize.height))
        let renderScale = min(
            maxExportScale,
            maxPixelWidth / targetSize.width,
            maxPixelHeight / targetSize.height,
            areaLimitedScale
        )

        guard renderScale.isFinite, renderScale > 0 else { return nil }
        let imageRenderer = ImageRenderer(content: snapshot)
        imageRenderer.proposedSize = ProposedViewSize(width: targetWidth, height: targetSize.height)
        imageRenderer.scale = renderScale

        guard let renderedImage = imageRenderer.uiImage else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = renderedImage.scale
        format.opaque = true

        let flattenedRenderer = UIGraphicsImageRenderer(size: renderedImage.size, format: format)
        let flattenedImage = flattenedRenderer.image { context in
            let bounds = CGRect(origin: .zero, size: renderedImage.size)
            UIColor(red: 243 / 255, green: 241 / 255, blue: 236 / 255, alpha: 1).setFill()
            context.fill(bounds)
            renderedImage.draw(in: bounds)
        }

        return flattenedImage.jpegData(compressionQuality: 0.88)
        #else
        return nil
        #endif
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let data = try Data(contentsOf: url)
            let payload = try SessionTransfer.importPayload(from: data)
            let firstUser = payload.messages.first(where: { $0.role == ChatRole.user.rawValue })?.content
            let session = ChatSession(title: SessionTransfer.suggestedTitle(from: firstUser))

            for (index, item) in payload.messages.enumerated() {
                guard let role = ChatRole(rawValue: item.role) else { continue }
                let date = Date().addingTimeInterval(Double(index))
                session.messages.append(ChatMessage(role: role, content: item.content, createdAt: date, session: session))
            }

            session.updatedAt = .now
            modelContext.insert(session)
            settings.currentSessionID = session.id.uuidString
            persist()
            selectedTab = .chat
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if isSending {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let id = currentSession?.sortedMessages.last?.id {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }

    private func persist() {
        try? modelContext.save()
    }

    private var sendButtonEnabled: Bool {
        !isSending && !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var lastAssistantMessageID: UUID? {
        currentSession?.sortedMessages.last(where: { $0.role == .assistant })?.id
    }

    private func shouldShowSkipFormatAction(for message: ChatMessage) -> Bool {
        guard message.role == .assistant, message.id == lastAssistantMessageID else { return false }
        let content = message.content
        let normalized = content.replacingOccurrences(of: " ", with: "")

        let isChineseFormatPrompt =
            normalized.contains("你们这次比赛的赛制是什么")
            && normalized.contains("几个环节")
            && normalized.contains("先跳过")

        let isEnglishFormatPrompt =
            content.localizedCaseInsensitiveContains("what is the format of your competition")
            && content.localizedCaseInsensitiveContains("how many segments")
            && content.localizedCaseInsensitiveContains("skip for now")

        return isChineseFormatPrompt || isEnglishFormatPrompt
    }
}

private struct ChatHeaderBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        LinearGradient(
                            colors: [
                                DebateTheme.canvas.opacity(0.22),
                                DebateTheme.canvasSecondary.opacity(0.14),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .mask(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.98),
                                .black.opacity(0.9),
                                .black.opacity(0.55),
                                .clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: proxy.safeAreaInsets.top + 70)

                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}

private struct HistoryView: View {
    @Binding var selectedTab: AppTab

    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]

    private var archivedSessions: [ChatSession] {
        sessions.filter { $0.hasContent && !$0.isDeleted }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(systemLocalizedText(zh: "历史记录", en: "History"))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(DebateTheme.ink)
                        Text(systemLocalizedText(zh: "查看并恢复之前的练习会话。", en: "Review and reopen previous practice sessions."))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DebateTheme.inkSoft)
                    }
                    .padding(.top, 10)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 4, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                Section {
                    if archivedSessions.isEmpty {
                        Text(systemLocalizedText(zh: "还没有历史记录", en: "No saved history yet"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DebateTheme.inkSoft)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(archivedSessions) { session in
                            Button {
                                settings.currentSessionID = session.id.uuidString
                                selectedTab = .chat
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(session.title)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(DebateTheme.ink)
                                                .lineLimit(2)
                                            Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(DebateTheme.inkMuted)
                                        }

                                        Spacer()

                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(DebateTheme.inkMuted)
                                    }

                                    Text(session.latestPreview.isEmpty ? systemLocalizedText(zh: "还没有消息", en: "No messages yet") : session.latestPreview)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(DebateTheme.inkSoft)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                }
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DebateTheme.panel, in: RoundedRectangle(cornerRadius: DebateRadius.lg, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    moveToRecycleBin(session)
                                } label: {
                                    Label(systemLocalizedText(zh: "删除", en: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .contentMargins(.top, 0, for: .scrollContent)
            .background(DebateTheme.pageGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func moveToRecycleBin(_ session: ChatSession) {
        session.deletedAt = .now
        session.updatedAt = .now
        if settings.currentSessionID == session.id.uuidString {
            settings.currentSessionID = sessions.first(where: { !$0.isDeleted && $0.id != session.id })?.id.uuidString ?? ""
        }
        try? modelContext.save()
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]

    @State private var baseURL = ""
    @State private var model = ""
    @State private var apiKey = ""
    @State private var showSavedBanner = false

    private var trashedSessions: [ChatSession] {
        sessions.filter(\.isDeleted)
    }

    private var appVersionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (shortVersion, buildVersion) {
        case let (short?, build?) where !short.isEmpty && !build.isEmpty:
            return "\(short) (\(build))"
        case let (short?, _) where !short.isEmpty:
            return short
        case let (_, build?) where !build.isEmpty:
            return build
        default:
            return systemLocalizedText(zh: "未知版本", en: "Unknown Version")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DebateSpacing.section) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(systemLocalizedText(zh: "设置", en: "Settings"))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(DebateTheme.ink)
                        Text(systemLocalizedText(zh: "配置模型与隐私信息。", en: "Configure model access and privacy details."))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DebateTheme.inkSoft)
                    }
                    .padding(.top, 10)

                    SettingsCard(title: systemLocalizedText(zh: "模型配置", en: "Provider")) {
                        VStack(spacing: 12) {
                            SettingsTextField(title: "API Endpoint", text: $baseURL)
                            SettingsTextField(title: "Model", text: $model)
                            SettingsTextField(title: "API Key", text: $apiKey, isSecure: true)

                            Button(systemLocalizedText(zh: "保存配置", en: "Save Provider Settings")) {
                                settings.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                settings.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
                                settings.saveAPIKey(apiKey)
                                showSavedBanner = true

                                if settings.hasAPIKey {
                                    Task {
                                        await ChatAPIClient.shared.prepareConnectionIfNeeded(config: settings.providerConfig)
                                    }
                                }
                            }
                            .buttonStyle(PrimaryActionButtonStyle())

                            Button(systemLocalizedText(zh: "清除 API Key", en: "Clear API Key"), role: .destructive) {
                                apiKey = ""
                                settings.clearAPIKey()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DebateTheme.danger)
                        }
                    }

                    SettingsCard(title: systemLocalizedText(zh: "回收站", en: "Recycle Bin")) {
                        NavigationLink {
                            RecycleBinView()
                        } label: {
                            HStack {
                                Text(systemLocalizedText(zh: "已删除会话", en: "Deleted Sessions"))
                                Spacer()
                                Text("\(trashedSessions.count)")
                                    .foregroundStyle(DebateTheme.inkMuted)
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DebateTheme.ink)
                        }
                    }

                    SettingsCard(title: systemLocalizedText(zh: "关于", en: "Credits")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(systemLocalizedText(zh: "版本：\(appVersionText)", en: "Version: \(appVersionText)"))
                            Text(systemLocalizedText(zh: "出品：精靈Moon", en: "Produced by: Jingling Moon"))
                            Text(systemLocalizedText(zh: "开发：精靈Moon, Boyuan Wang", en: "Developed by: Jingling Moon, Boyuan Wang"))
                            Text(systemLocalizedText(zh: "内容基于《辩论筑基》。", en: "Content is based on Debate Foundations."))
                            Text(systemLocalizedText(zh: "Bilibili 和 YouTube 提供完整免费教学视频。", en: "Complete free teaching videos are available on Bilibili and YouTube."))
                            Text(systemLocalizedText(zh: "本 Debate-Coach 项目已在 GitHub 开源。", en: "The Debate-Coach project is open sourced on GitHub."))
                            Text(systemLocalizedText(zh: "核心文件遵循 CC BY-NC-SA 4.0 协议，请勿非法或违规使用。", en: "Core files follow the CC BY-NC-SA 4.0 license. Do not use them illegally or in violation of regulations."))
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DebateTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SettingsCard(title: systemLocalizedText(zh: "法律与支持", en: "Legal")) {
                        VStack(spacing: 12) {
                            NavigationLink(systemLocalizedText(zh: "隐私政策", en: "Privacy Policy")) {
                                MarkdownDocumentView(title: systemLocalizedText(zh: "隐私政策", en: "Privacy Policy"), text: PromptLoader.loadPrivacyPolicy())
                            }
                            .foregroundStyle(DebateTheme.ink)

                            Link(systemLocalizedText(zh: "联系支持", en: "Contact Support"), destination: URL(string: "mailto:support@example.com")!)
                                .foregroundStyle(DebateTheme.ink)
                        }
                    }
                }
                .padding(.horizontal, DebateSpacing.page)
                .padding(.bottom, 28)
            }
            .background(DebateTheme.pageGradient.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                baseURL = settings.baseURL
                model = settings.model
                apiKey = settings.apiKey
            }
            .overlay(alignment: .top) {
                if showSavedBanner {
                    Text(systemLocalizedText(zh: "已保存", en: "Saved"))
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(DebateTheme.panel, in: Capsule())
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task {
                            try? await Task.sleep(for: .seconds(1.2))
                            withAnimation {
                                showSavedBanner = false
                            }
                        }
                }
            }
        }
    }
}

private struct RecycleBinView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]

    private var trashedSessions: [ChatSession] {
        sessions.filter(\.isDeleted)
    }

    var body: some View {
        List {
            if trashedSessions.isEmpty {
                Text(systemLocalizedText(zh: "回收站为空", en: "Recycle bin is empty"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DebateTheme.inkSoft)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(trashedSessions) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DebateTheme.ink)
                        Text(session.latestPreview.isEmpty ? systemLocalizedText(zh: "已删除的空白会话", en: "Deleted empty session") : session.latestPreview)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(DebateTheme.inkSoft)
                            .lineLimit(2)
                        Text(recycleInfo(for: session))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DebateTheme.inkMuted)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            restore(session)
                        } label: {
                            Label(systemLocalizedText(zh: "恢复", en: "Restore"), systemImage: "arrow.uturn.backward")
                        }
                        .tint(DebateTheme.accent)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            permanentlyDelete(session)
                        } label: {
                            Label(systemLocalizedText(zh: "彻底删除", en: "Delete Forever"), systemImage: "trash")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .background(DebateTheme.pageGradient.ignoresSafeArea())
        .navigationTitle(systemLocalizedText(zh: "回收站", en: "Recycle Bin"))
        .onAppear {
            purgeExpired()
        }
    }

    private func recycleInfo(for session: ChatSession) -> String {
        guard let expiry = session.recycleExpiryDate else {
            return systemLocalizedText(zh: "已移入回收站", en: "Moved to recycle bin")
        }
        let remaining = max(0, Int(ceil(expiry.timeIntervalSinceNow / (24 * 60 * 60))))
        return systemLocalizedText(
            zh: "将于 \(remaining) 天内自动清除",
            en: "Auto-deletes in \(remaining) day(s)"
        )
    }

    private func restore(_ session: ChatSession) {
        session.deletedAt = nil
        session.updatedAt = .now
        try? modelContext.save()
    }

    private func permanentlyDelete(_ session: ChatSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }

    private func purgeExpired() {
        let now = Date()
        let expired = trashedSessions.filter { session in
            guard let expiry = session.recycleExpiryDate else { return false }
            return expiry <= now
        }
        guard !expired.isEmpty else { return }
        for session in expired {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}

private struct RiskConsentView: View {
    @EnvironmentObject private var settings: AppSettingsStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(riskIntroText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.black)

                    VStack(alignment: .leading, spacing: 10) {
                        RiskNoteRow(
                            systemImage: "exclamationmark.triangle.fill",
                            text: systemLocalizedText(zh: "仅供技术学习与参考使用。", en: "For technical learning and reference use.")
                        )
                        RiskNoteRow(
                            systemImage: "key.fill",
                            text: systemLocalizedText(zh: "API 使用成本与合规责任由用户自行承担。", en: "Users are responsible for API usage costs and legal compliance.")
                        )
                        RiskNoteRow(
                            systemImage: "book.fill",
                            text: systemLocalizedText(zh: "内容基于 AI 对课件的学习，而非权威视频讲解。", en: "Content is based on AI learning from courseware, not authoritative video lectures.")
                        )
                        RiskNoteRow(
                            systemImage: "lock.fill",
                            text: systemLocalizedText(zh: "本地会话记录默认仅保存在此设备，除非你主动导出。", en: "Local session history stays on this device unless you export it.")
                        )
                    }
                    .font(.body)

                    Button {
                        settings.riskAccepted = true
                    } label: {
                        Text(systemLocalizedText(zh: "我已了解并继续", en: "I Understand and Continue"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
                .padding(24)
                .foregroundStyle(Color.black)
            }
            .background(DebateTheme.pageGradient.ignoresSafeArea())
            .navigationTitle(systemLocalizedText(zh: "开始之前", en: "Before You Start"))
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    private var riskIntroText: AttributedString {
        let source = systemLocalizedText(
            zh: "我是基于 [grill-me](https://github.com/mattpocock/grill-me) 审问模式、学习《辩论筑基》（Debate Universal Grammar，精靈Moon著）全套体系内容训练的辩论教练。",
            en: "This coach is trained from the full Debate Universal Grammar system and inspired by the grill-me interrogation format."
        )

        return (try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(source)
    }
}

private struct RiskNoteRow: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 28, alignment: .center)
                .foregroundStyle(Color.black)

            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct WelcomeCard: View {
    let language: AppLanguage
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text(systemLocalizedText(zh: "今天想练什么？", en: "What do you want to practice today?"))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DebateTheme.panel)

                Text(language == .zh ? chineseText : englishText)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(DebateTheme.panel.opacity(0.88))
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .padding(.top, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DebateTheme.accent, in: RoundedRectangle(cornerRadius: DebateRadius.xl, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                ScrollView {
                    Text(detailText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(DebateTheme.ink)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
                .background(DebateTheme.pageGradient.ignoresSafeArea())
                .navigationTitle(systemLocalizedText(zh: "辩论筑基・Debate-Coach", en: "Debate-Coach"))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var chineseText: String {
        "可以是一道辩题、一个观点，\n也可以是一段还没想清楚的论证。\n我会像教练一样追问你，直到它变得清楚、有力。"
    }

    private var englishText: String {
        "Bring a motion, a viewpoint, or even an argument you have not fully figured out yet. I will push on it like a coach until it becomes clear and strong."
    }

    private var detailText: String {
        systemLocalizedText(
            zh: "我是基于 grill-me 审问模式、学习《辩论筑基》（Debate Universal Grammar，精靈Moon著）全套体系内容训练的辩论教练。感谢 grill-me（Matt Pocock）的开创性审问格式，也感谢王伯元学弟分享启发 grill-me 在辩论中的应用。\n\n⚠️ 因教材所限，本 skill 目前仅针对华语辩论进行了调试，对英语辩论完全不适配，而且主流英语辩论和华语辩论流行的一般性辩论也大相径庭，相关英语功能仅供娱乐与参考。完整免费视频课程见 YouTube 和 Bilibili（搜索\"辩论筑基\"或\"精靈Moon\"）。\n\n⚠️ 本 Skill 的回答基于 AI 学习《辩论筑基》课件（而非视频讲解），与精灵的理解和本意必然存在错漏偏差，知识性内容请以精灵的视频讲解为准，本 Skill 会话内容仅供参考！仅供参考！仅供参考！！！",
            en: "This debate coach is trained on the full Debate Universal Grammar system and inspired by the grill-me questioning format. The current skill is tuned for Chinese-language debate only. English debate support is not reliable and is for entertainment and rough reference only. Its answers are based on AI learning from course slides rather than full video instruction, so factual or interpretive details may contain errors. Please treat all responses as reference only."
        )
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let showsRegenerateAction: Bool
    let showsSkipAction: Bool
    let regenerateTitle: String
    let skipTitle: String
    let onRegenerate: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.role == .user { Spacer(minLength: 40) }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.caption.weight(.semibold))
                        if message.role != .user {
                            Text(timestamp)
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(labelColor)

                    Text(message.content)
                        .textSelection(.enabled)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(DebateTheme.ink)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(bubbleBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .frame(maxWidth: 560, alignment: message.role == .user ? .trailing : .leading)

                if message.role != .user { Spacer(minLength: 40) }
            }

            if message.role == .assistant && (showsRegenerateAction || showsSkipAction) {
                HStack(spacing: 8) {
                    if showsSkipAction {
                        Button(action: onSkip) {
                            Text(skipTitle)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DebateTheme.inkMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DebateTheme.panel.opacity(0.75), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if showsRegenerateAction {
                        Button(action: onRegenerate) {
                            Label(regenerateTitle, systemImage: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DebateTheme.inkMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DebateTheme.panel.opacity(0.75), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 6)
            }
        }
    }

    private var label: String {
        switch message.role {
        case .user: "You"
        case .assistant: "Debate Coach"
        case .system: "System"
        }
    }

    private var bubbleBackground: AnyShapeStyle {
        switch message.role {
        case .user:
            AnyShapeStyle(DebateTheme.userBubbleGradient)
        case .assistant:
            AnyShapeStyle(LinearGradient(colors: [DebateTheme.panel, DebateTheme.bubbleAI], startPoint: .top, endPoint: .bottom))
        case .system:
            AnyShapeStyle(LinearGradient(colors: [DebateTheme.bubbleSystem.opacity(0.9), DebateTheme.bubbleSystem.opacity(0.66)], startPoint: .top, endPoint: .bottom))
        }
    }

    private var labelColor: Color {
        switch message.role {
        case .user:
            DebateTheme.accent
        case .assistant:
            DebateTheme.inkSoft
        case .system:
            DebateTheme.danger
        }
    }

    private var timestamp: String {
        message.createdAt.formatted(date: .omitted, time: .shortened)
    }
}

private struct StreamingBubble: View {
    let text: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("Debate Coach")
                        .font(.caption.weight(.semibold))
                    Text("typing")
                        .font(.caption2)
                }
                .foregroundStyle(DebateTheme.inkSoft)

                if text.isEmpty {
                    HStack(spacing: 6) {
                        ProgressView()
                        Text("Thinking…")
                            .foregroundStyle(DebateTheme.inkSoft)
                    }
                } else {
                    Text(text)
                        .textSelection(.enabled)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(DebateTheme.ink)
                        .lineSpacing(3)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [DebateTheme.panel, DebateTheme.bubbleAI], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .frame(maxWidth: 560, alignment: .leading)

            Spacer(minLength: 40)
        }
    }
}

private struct MarkdownDocumentView: View {
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            Text(markdownAttributedString ?? AttributedString(text))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(DebateTheme.pageGradient.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var markdownAttributedString: AttributedString? {
        try? AttributedString(markdown: text)
    }
}

private struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private enum ExportKind {
    case json
    case markdown
    case jpg
}

private struct ChatExportSnapshotView: View {
    let session: ChatSession

    private let exportCanvasWidth: CGFloat = 900
    private let exportContentWidth: CGFloat = 852

    private var exportFooterImage: UIImage? {
        guard let url = Bundle.main.url(forResource: "last", withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    private var exportFooterHeight: CGFloat? {
        guard let footerImage = exportFooterImage, footerImage.size.width > 0 else {
            return nil
        }
        return exportContentWidth * (footerImage.size.height / footerImage.size.width)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DebateTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(systemLocalizedText(zh: "辩论教练会话导出", en: "Debate Coach Conversation Export"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DebateTheme.inkSoft)
            }
            .padding(.bottom, 8)

            ForEach(session.sortedMessages) { message in
                MessageBubble(
                    message: message,
                    showsRegenerateAction: false,
                    showsSkipAction: false,
                    regenerateTitle: "",
                    skipTitle: "",
                    onRegenerate: {},
                    onSkip: {}
                )
            }

            if let footerImage = exportFooterImage,
               let footerHeight = exportFooterHeight {
                Image(uiImage: footerImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: exportContentWidth, height: footerHeight)
                    .padding(.top, 10)
            }
        }
        .padding(24)
        .frame(width: exportCanvasWidth, alignment: .leading)
        .background(DebateTheme.pageGradient)
    }
}

private func systemLocalizedText(zh: String, en: String) -> String {
    Locale.preferredLanguages.first?.hasPrefix("zh") == true ? zh : en
}

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DebateTheme.inkSoft)
                .textCase(.uppercase)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DebateTheme.panel, in: RoundedRectangle(cornerRadius: DebateRadius.lg, style: .continuous))
    }
}

private struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DebateTheme.inkSoft)
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(DebateTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(DebateTheme.panelSoft, in: RoundedRectangle(cornerRadius: DebateRadius.md, style: .continuous))
        }
    }
}

private struct SettingsPickerRow<Selection: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: Selection
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DebateTheme.inkSoft)
            Picker(title, selection: $selection) {
                content
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                DebateTheme.accent.opacity(configuration.isPressed ? 0.92 : 1),
                in: RoundedRectangle(cornerRadius: DebateRadius.md, style: .continuous)
            )
    }
}
