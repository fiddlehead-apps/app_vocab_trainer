import PhotosUI
import SwiftUI
import VisionKit

/// Photo → text → new words. Opened from the home screen.
struct ScanView: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.language) private var language = Settings.defaultLanguage
    @State private var phase = Phase.pick
    @State private var picked: [PhotosPickerItem] = []
    @State private var showScanner = false
    @State private var showCamera = false

    enum Phase {
        case pick
        case reading
        case review(ScanResult)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .pick: pickView
                case .reading: readingView
                case .review(let result):
                    ReviewView(store: store, result: result, retry: { phase = .pick }, done: { dismiss() })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bg)
            .navigationTitle("New words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScanner { images in
                showScanner = false
                read(images)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                showCamera = false
                if let image { read([image]) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            phase = .reading
            Task {
                var images: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
                picked = []
                read(images)
            }
        }
    }

    private var pickView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("📸")
                    .font(.system(size: 72))
                    .padding(.top, 24)
                Text("Take a photo of English text")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink)
                Text("The text is read right here on the iPhone. Then you pick the words you want to learn.")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.muted)
                    .padding(.bottom, 12)

                if VNDocumentCameraViewController.isSupported {
                    Button { showScanner = true } label: {
                        Label("Scan a book page", systemImage: "doc.viewfinder")
                    }
                    .buttonStyle(BigButtonStyle(primary: true))
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button { showCamera = true } label: {
                        Label("Take a photo", systemImage: "camera")
                    }
                    .buttonStyle(BigButtonStyle(primary: !VNDocumentCameraViewController.isSupported))
                }
                PhotosPicker(selection: $picked, maxSelectionCount: 10, matching: .images) {
                    Label("Choose from photos", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(BigButtonStyle(primary: false))

                Label {
                    Text("Tip: vocabulary lists with English and \(Settings.name(of: language)) side by side work best. The translations are taken over directly.")
                } icon: {
                    Image(systemName: "lightbulb")
                }
                .font(.system(size: 14))
                .foregroundStyle(Color.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
                .padding(.top, 10)
            }
            .padding(20)
        }
    }

    private var readingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Reading the text…")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.muted)
        }
    }

    private func read(_ images: [UIImage]) {
        guard !images.isEmpty else {
            phase = .pick
            return
        }
        phase = .reading
        let language = language
        Task {
            let result = await TextExtractor.read(images, language: language)
            phase = .review(result)
        }
    }
}

/// VisionKit's document camera: finds the page edges and straightens the page.
struct DocumentScanner: UIViewControllerRepresentable {
    let done: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(done: done) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let done: ([UIImage]) -> Void

        init(done: @escaping ([UIImage]) -> Void) { self.done = done }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            done((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            done([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            done([])
        }
    }
}

/// The plain camera, for anything that is not a page (posters, signs, game screens).
struct CameraPicker: UIViewControllerRepresentable {
    let done: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(done: done) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let done: (UIImage?) -> Void

        init(done: @escaping (UIImage?) -> Void) { self.done = done }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            done(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            done(nil)
        }
    }
}
