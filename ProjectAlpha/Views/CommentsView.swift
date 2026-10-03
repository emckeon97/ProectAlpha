import SwiftUI

/// Comment thread for a single post, presented as a sheet.
struct CommentsView: View {
    let post: Post

    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var comments: [Comment] = []
    @State private var draft = ""
    @State private var isLoading = true
    @State private var isSending = false

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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.displayName)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.gray)
                            Text(comment.body)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.black)
                    }
                    .listStyle(.plain)
                    .background(Color.black)
                }

                HStack {
                    TextField(
                        auth.isSignedIn ? "Add a comment…" : "Sign in to comment",
                        text: $draft
                    )
                    .textFieldStyle(.roundedBorder)
                    .disabled(!auth.isSignedIn)

                    Button { send() } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .disabled(
                        !auth.isSignedIn || isSending
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
        }
    }

    private func load() async {
        do {
            comments = try await SupabaseManager.shared.fetchComments(postID: post.id)
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
                    postID: post.id,
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
