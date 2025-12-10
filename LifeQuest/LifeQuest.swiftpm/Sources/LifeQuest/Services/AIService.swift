import Foundation

/// Handles Claude API integration for activity interpretation and coaching
@Observable
class AIService {
    private var apiKey: String?
    private let baseURL = "https://api.anthropic.com/v1/messages"

    var isConfigured: Bool { apiKey != nil && !apiKey!.isEmpty }
    var lastError: String?

    // MARK: - Configuration

    func configure(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Activity Interpretation

    /// Interpret a natural language activity and map to skill gains
    func interpretActivity(
        _ input: String,
        character: Character,
        context: String
    ) async -> ActivityInterpretation? {
        let systemPrompt = buildSystemPrompt()
        let userPrompt = buildActivityPrompt(input: input, character: character, context: context)

        guard let response = await sendMessage(system: systemPrompt, user: userPrompt) else {
            return nil
        }

        return parseActivityInterpretation(response)
    }

    private func buildActivityPrompt(input: String, character: Character, context: String) -> String {
        """
        Given this activity log entry, determine the appropriate skill gains.

        ACTIVITY: "\(input)"

        CONTEXT:
        - Character level: \(character.level)
        - Major skills: \(character.majorSkillIDs.joined(separator: ", "))
        - Current health: \(character.currentHealth)/\(character.maxHealth)
        - Current energy: \(character.currentEnergy)/\(character.maxEnergy)

        MEMORY CONTEXT:
        \(context)

        AVAILABLE SKILLS:
        Physical: strength, endurance, mobility, recovery
        Mental: focus, learning, problem_solving, creativity
        Social: communication, leadership, empathy, networking
        Professional: programming, design, writing (or user-defined)
        Maintenance: sleep, nutrition, stress_management, finance

        Respond with JSON only:
        {
          "interpretation": "Brief description of what the user did",
          "skillGains": [
            {"skillID": "skill_id", "amount": 25, "reason": "Why this skill"}
          ],
          "notes": "Any relevant observation for the user",
          "suggestedQuest": null,
          "energyCost": 0,
          "healthCost": 0
        }

        Guidelines:
        - Award 5-100 XP based on effort/duration
        - Multiple skills can gain from one activity
        - Be generous but not inflated
        - energyCost: 0-30 for mental activities
        - healthCost: 0-30 for physical activities
        """
    }

    // MARK: - Coaching Chat

    /// Have a coaching conversation
    func chat(
        message: String,
        character: Character,
        history: [ChatMessage],
        memoryContext: String
    ) async -> String? {
        let systemPrompt = buildCoachingSystemPrompt(character: character, context: memoryContext)

        var messages = history.map { msg in
            ["role": msg.role, "content": msg.content]
        }
        messages.append(["role": "user", "content": message])

        return await sendConversation(system: systemPrompt, messages: messages)
    }

    private func buildCoachingSystemPrompt(character: Character, context: String) -> String {
        """
        You are the AI coach for LifeQuest, a life improvement app with RPG mechanics.

        CURRENT CHARACTER STATE:
        - Level: \(character.level)
        - Health: \(character.currentHealth)/\(character.maxHealth) (\(character.status.rawValue))
        - Energy: \(character.currentEnergy)/\(character.maxEnergy)
        - Rest debt: \(character.restDebt)
        - Major skills: \(character.majorSkillIDs.joined(separator: ", "))

        MEMORY CONTEXT:
        \(context)

        Your role:
        1. Provide encouraging but realistic feedback
        2. Reference their actual data when relevant
        3. Keep responses under 100 words unless asked to elaborate
        4. If they're struggling, acknowledge before problem-solving
        5. Celebrate specific achievements, not generic praise

        Never:
        - Give medical advice
        - Make promises about outcomes
        - Be preachy or lecture
        - Repeat the same advice verbatim
        """
    }

    // MARK: - Insight Generation

    /// Generate daily insights based on recent activity
    func generateDailyInsight(
        character: Character,
        recentActivities: [Activity],
        patterns: String
    ) async -> String? {
        let systemPrompt = buildSystemPrompt()
        let userPrompt = """
        Generate a brief daily insight for this user.

        CHARACTER:
        - Level \(character.level), \(character.status.rawValue)
        - Health: \(character.currentHealth)%, Energy: \(character.currentEnergy)%

        TODAY'S ACTIVITIES:
        \(recentActivities.prefix(5).map { "- \($0.rawInput)" }.joined(separator: "\n"))

        PATTERNS:
        \(patterns)

        Generate a 1-2 sentence insight that is:
        - Specific to their data (not generic)
        - Actionable or observational
        - Encouraging without being hollow

        Respond with just the insight text, no JSON or formatting.
        """

        return await sendMessage(system: systemPrompt, user: userPrompt)
    }

    /// Generate weekly review
    func generateWeeklyReview(
        character: Character,
        weekSummary: WeekSummary
    ) async -> WeeklyReview? {
        let systemPrompt = buildSystemPrompt()
        let userPrompt = """
        Generate a weekly review for this user.

        WEEK SUMMARY:
        - Total XP earned: \(weekSummary.totalXP)
        - Skills trained: \(weekSummary.skillsTrained.joined(separator: ", "))
        - Quests completed: \(weekSummary.questsCompleted)
        - Best streak: \(weekSummary.longestStreak) days
        - Average sleep: \(String(format: "%.1f", weekSummary.avgSleep)) hours

        Generate a review with exactly this JSON format:
        {
          "highlight": "One biggest win",
          "observation": "One pattern noticed",
          "suggestion": "One specific, achievable next step"
        }
        """

        guard let response = await sendMessage(system: systemPrompt, user: userPrompt) else {
            return nil
        }

        return parseWeeklyReview(response)
    }

    // MARK: - API Communication

    private func buildSystemPrompt() -> String {
        """
        You are the AI coach for LifeQuest, a life improvement app with RPG mechanics inspired by Morrowind.

        Your role:
        1. Interpret user activities and map them to skill gains
        2. Provide encouraging but realistic feedback
        3. Notice patterns in behavior and offer insights
        4. Suggest optimizations without being pushy

        Personality:
        - Wise mentor, not drill sergeant
        - Celebrates progress without being sycophantic
        - Honest about challenges, optimistic about potential
        - Speaks concisely - this is a mobile app

        Always respond in the exact format requested.
        """
    }

    private func sendMessage(system: String, user: String) async -> String? {
        guard let apiKey = apiKey else {
            lastError = "API key not configured"
            return nil
        }

        guard let url = URL(string: baseURL) else {
            lastError = "Invalid URL"
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": system,
            "messages": [
                ["role": "user", "content": user]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid response"
                return nil
            }

            if httpResponse.statusCode != 200 {
                lastError = "API error: \(httpResponse.statusCode)"
                return nil
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String {
                return text
            }

            lastError = "Failed to parse response"
            return nil
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private func sendConversation(system: String, messages: [[String: String]]) async -> String? {
        guard let apiKey = apiKey else {
            lastError = "API key not configured"
            return nil
        }

        guard let url = URL(string: baseURL) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": system,
            "messages": messages
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String {
                return text
            }
            return nil
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Response Parsing

    private func parseActivityInterpretation(_ response: String) -> ActivityInterpretation? {
        // Extract JSON from response (may have markdown code blocks)
        let jsonString = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let interpretation = json["interpretation"] as? String ?? ""
        let notes = json["notes"] as? String
        let suggestedQuest = json["suggestedQuest"] as? String
        let energyCost = json["energyCost"] as? Int ?? 0
        let healthCost = json["healthCost"] as? Int ?? 0

        var skillGains: [SkillGain] = []
        if let gains = json["skillGains"] as? [[String: Any]] {
            for gain in gains {
                if let skillID = gain["skillID"] as? String,
                   let amount = gain["amount"] as? Int {
                    skillGains.append(SkillGain(
                        skillID: skillID,
                        amount: amount,
                        reason: gain["reason"] as? String
                    ))
                }
            }
        }

        return ActivityInterpretation(
            interpretation: interpretation,
            skillGains: skillGains,
            notes: notes,
            suggestedQuest: suggestedQuest,
            energyCost: energyCost,
            healthCost: healthCost
        )
    }

    private func parseWeeklyReview(_ response: String) -> WeeklyReview? {
        let jsonString = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return WeeklyReview(
            highlight: json["highlight"] as? String ?? "",
            observation: json["observation"] as? String ?? "",
            suggestion: json["suggestion"] as? String ?? ""
        )
    }
}

// MARK: - Supporting Types

struct ActivityInterpretation {
    let interpretation: String
    let skillGains: [SkillGain]
    let notes: String?
    let suggestedQuest: String?
    let energyCost: Int
    let healthCost: Int
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String  // "user" or "assistant"
    let content: String
    let timestamp = Date()
}

struct WeekSummary {
    let totalXP: Int
    let skillsTrained: [String]
    let questsCompleted: Int
    let longestStreak: Int
    let avgSleep: Double
}

struct WeeklyReview {
    let highlight: String
    let observation: String
    let suggestion: String
}
