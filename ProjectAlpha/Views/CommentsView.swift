import SwiftUI

/// Comment thread for a user post or a GIF, presented as a sheet.
/// Anonymous commenting is allowed; signed-in users post under their display name.
struct CommentsView: View {
    let postID: String?
    let gifID: String?

    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var comments: [Comment] = []
    @State private var draft = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var reportingComment: Comment?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if comments.isEmpty {
                    Spacer()
                    Text("No comments yet.")
                        .foregroundColor(.gray)
                    Text("Start the conversation.")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Spacer()
                } else {
                    List(comments) { comment in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.displayName)
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.gray)
                                Text(comment.body)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button {
                                reportingComment = comment
                            } label: {
                                Image(systemName: "flag")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.black)
                    }
                    .listStyle(.plain)
                    .background(Color.black)
                }

                HStack {
                    TextField("Add a comment…", text: $draft)
                        .textFieldStyle(.roundedBorder)

                    Button { send() } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .disabled(
                        isSending
                            || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await load() }
            .sheet(item: $reportingComment) { comment in
                ReportView(target: .comment(comment))
            }
        }
    }

    private func load() async {
        do {
            comments = try await SupabaseManager.shared.fetchComments(
                postID: postID, gifID: gifID
            )
        } catch {
            comments = []
        }
        isLoading = false
    }

    private func send() {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        isSending = true
        Task {
            do {
                let comment = try await SupabaseManager.shared.insertComment(
                    postID: postID,
                    gifID: gifID,
                    body: body,
                    displayName: auth.currentDisplayName
                )
                comments.append(comment)
                draft = ""
            } catch {
                // Leave the draft in place so nothing is lost.
            }
            isSending = false
        }
    }
}
