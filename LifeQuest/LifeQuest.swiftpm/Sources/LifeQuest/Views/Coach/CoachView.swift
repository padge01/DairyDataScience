import SwiftUI

/// AI Coach chat and insights view
struct CoachView: View {
    @Environment(CharacterViewModel.self) private var viewModel
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                WelcomeMessageView()
                                    .padding()
                            }

                            ForEach(messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                TypingIndicatorView()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input
                MessageInputView(
                    text: $messageText,
                    isLoading: isLoading,
                    onSend: sendMessage
                )
            }
            .navigationTitle("Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            // Request insight
                        } label: {
                            Label("Get Daily Insight", systemImage: "lightbulb")
                        }

                        Button {
                            // Clear chat
                            messages.removeAll()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: messageText)
        messages.append(userMessage)
        let currentMessage = messageText
        messageText = ""

        isLoading = true

        // Simulate AI response (replace with actual AI call)
        Task {
            try? await Task.sleep(for: .seconds(1))

            let response = generateMockResponse(for: currentMessage)
            let assistantMessage = ChatMessage(role: "assistant", content: response)

            await MainActor.run {
                messages.append(assistantMessage)
                isLoading = false
            }
        }
    }

    func generateMockResponse(for input: String) -> String {
        let lower = input.lowercased()

        if lower.contains("tired") || lower.contains("exhausted") {
            return "I can see your energy is running low. Your data shows you've been pushing hard lately. Consider prioritizing sleep tonight - even one good night can shift things. What's one thing you could skip tomorrow to make room for rest?"
        } else if lower.contains("streak") {
            return "Streaks are powerful - they compound your gains over time. Right now your best streak is on your daily steps. Want me to suggest a new habit that builds on that momentum?"
        } else if lower.contains("what should") || lower.contains("suggest") {
            return "Based on your recent patterns, you're strongest in the mornings. Your Focus skill has been growing steadily. I'd suggest doubling down there - maybe add a morning deep work block before context-switching hits."
        } else {
            return "I hear you. Looking at your journey so far, you've been making steady progress. Every small action compounds. What's one thing you'd like to focus on this week?"
        }
    }
}

// MARK: - Welcome Message

struct WelcomeMessageView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Constants.Colors.primary.gradient)

            Text("Your AI Coach")
                .font(.title2.bold())

            Text("I'm here to help you understand your patterns, suggest improvements, and celebrate your progress. Ask me anything about your journey.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("Try asking:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                SuggestionChip(text: "What should I focus on?")
                SuggestionChip(text: "How am I doing this week?")
                SuggestionChip(text: "I'm feeling tired")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }
}

struct SuggestionChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Constants.Colors.primary.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Message Bubble

struct MessageBubbleView: View {
    let message: ChatMessage

    var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .padding(12)
                    .background(isUser ? Constants.Colors.primary : Color.secondary.opacity(0.1))
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timestamp.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .offset(y: animationPhase == index ? -4 : 0)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Message Input

struct MessageInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Message your coach...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(canSend ? Constants.Colors.primary : .secondary)
            }
            .disabled(!canSend)
        }
        .padding()
    }

    var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

#Preview {
    CoachView()
}
