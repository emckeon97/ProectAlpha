import SwiftUI

enum ReportTarget {
    case post(Post)
    case gif(id: String, title: String)
    case comment(Comment)
}

/// Report a meme or a comment. Reports land in the `reports` table
/// for review in the Supabase dashboard.
struct ReportView: View {
    let target: ReportTarget

    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var reason = "Spam"
    @State private var details = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var submitted = false

    private let reasons = [
        "Spam", "Harassment", "Hate speech", "Sexual content", "Violence", "Other",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if submitted {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Thanks — we'll take a look.")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    Picker("Reason", selection: $reason) {
                        ForEach(reasons, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)

                    TextField("Details (optional)", text: $details, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button { submit() } label: {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Submit Report").bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isSending)

                    Spacer()
                }
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        isSending = true
        errorMessage = nil
        Task {
            do {
                switch target {
                case .post(let post):
                    try await SupabaseManager.shared.insertReport(
                        postID: post.id,
                        reason: reason,
                        details: details,
                        reporterName: auth.currentDisplayName
                    )
                case .gif(let id, _):
                    try await SupabaseManager.shared.insertReport(
                        gifID: id,
                        reason: reason,
                        details: details,
                        reporterName: auth.currentDisplayName
                    )
                case .comment(let comment):
                    try await SupabaseManager.shared.insertReport(
                        commentID: comment.id,
                        reason: reason,
                        details: details,
                        reporterName: auth.currentDisplayName
                    )
                }
                submitted = true
            } catch {
                errorMessage = "Couldn't send the report. Try again."
            }
            isSending = false
        }
    }
}
