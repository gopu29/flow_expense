import AppIntents
import Foundation

/// Modern iOS AppIntent enabling zero-friction expense addition via Back Tap,
/// Siri Shortcuts, Action Button, and Control Center widgets (iOS 16+).
@available(iOS 16.0, *)
struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Flow Expense"
    static var description = IntentDescription("Instantly logs an expense to Flow Expense without opening the full dashboard.")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount", description: "Expense amount to log")
    var amount: Double?

    @Parameter(title: "Category", description: "Category name (e.g. Food, Transport, Shopping)")
    var category: String?

    @Parameter(title: "Note", description: "Optional transaction note or merchant")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log expense of \(\.$amount) for \(\.$category)") {
            \.$note
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let enteredAmount = amount, enteredAmount > 0 else {
            return .result(dialog: "Please provide a valid expense amount.")
        }

        let categoryName = category ?? "Food"
        let transactionNote = note ?? "Back Tap Shortcut"

        // Shared App Group SQLite write or local intent persistence
        let appGroupID = "group.com.quanto.flowexpense"
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let pendingIntentURL = containerURL.appendingPathComponent("pending_intents.json")
            
            var existing: [[String: Any]] = []
            if let data = try? Data(contentsOf: pendingIntentURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                existing = json
            }

            let newEntry: [String: Any] = [
                "id": UUID().uuidString,
                "amount": enteredAmount,
                "category": categoryName,
                "note": transactionNote,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            existing.append(newEntry)

            if let updatedData = try? JSONSerialization.data(withJSONObject: existing) {
                try? updatedData.write(to: pendingIntentURL)
            }
        }

        return .result(dialog: "Logged ₹\(String(format: "%.2f", enteredAmount)) for \(categoryName) in Flow Expense!")
    }
}

/// AppShortcutsProvider to register Flow Expense in the iOS Shortcuts & Back Tap menus.
@available(iOS 16.0, *)
struct FlowExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Log expense in \(.applicationName)",
                "Add expense to \(.applicationName)",
                "Quick spend in \(.applicationName)"
            ],
            shortTitle: "Quick Log Expense",
            systemImageName: "plus.circle.fill"
        )
    }
}
