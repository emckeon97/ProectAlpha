import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject var postService: LocalPostService
    @Environment(\.dismiss) var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var caption = ""
    @State private var isPosting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .cornerRadius(12)
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                            Text("Choose a photo")
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }

                TextField("Add a caption…", text: $caption, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button { post() } label: {
                    if isPosting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Post").bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedImage == nil ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedImage == nil || isPosting)

                Spacer()
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }

    private func post() {
        guard let image = selectedImage,
              let data = image.jpegData(compressionQuality: 0.85)
        else { return }

        isPosting = true
        do {
            try postService.createPost(imageData: data, caption: caption)
            dismiss()
        } catch {
            errorMessage = "Couldn't save your post. Try again."
            isPosting = false
        }
    }
}
