import PhotosUI
import SwiftUI

struct SettingsView: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.language) private var language = Settings.defaultLanguage
    @AppStorage(Settings.accent) private var accent = "en-GB"
    @AppStorage(Settings.rewardEvery) private var rewardEvery = 10
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("My language", selection: $language) {
                        ForEach(Settings.languages.sorted { Settings.name(of: $0) < Settings.name(of: $1) }, id: \.self) {
                            Text(Settings.name(of: $0)).tag($0)
                        }
                    }
                    Picker("English voice", selection: $accent) {
                        Text("British").tag("en-GB")
                        Text("American").tag("en-US")
                    }
                    Button("Listen", systemImage: "speaker.wave.2") {
                        Speech.shared.english("Hello! Let's learn some new words.")
                    }
                } header: {
                    Text("Learning")
                } footer: {
                    Text("Words found on photos are translated into this language. Words you already have keep their translation.")
                }

                Section("Brainrots") {
                    Picker("A brainrot after", selection: $rewardEvery) {
                        ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) correct answers").tag($0) }
                    }
                    NavigationLink {
                        CustomBrainrotsView(store: store)
                    } label: {
                        LabeledContent("Own pictures", value: "\(store.custom.count)")
                    }
                }

                Section {
                    LabeledContent("Words", value: "\(store.words.count)")
                    LabeledContent("Correct answers", value: "\(store.progress.totalCorrect)")
                    LabeledContent("Answers", value: "\(store.progress.totalAnswers)")
                    Button("Reset learning progress", role: .destructive) { confirmReset = true }
                } header: {
                    Text("Progress")
                } footer: {
                    Text("Text recognition, translation and voices run on this iPhone. No account, no server, nothing leaves the device.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("All words go back to zero stars. The words and the collection stay.",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset learning progress", role: .destructive) { store.resetProgress() }
            }
        }
    }
}

/// Own brainrot pictures from the photo library. They show up as rewards like the built-in ones.
struct CustomBrainrotsView: View {
    let store: Store
    @State private var item: PhotosPickerItem?
    @State private var pending: PendingPicture?
    @State private var name = ""

    struct PendingPicture: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    var body: some View {
        List {
            Section {
                PhotosPicker(selection: $item, matching: .images) {
                    Label("Add a picture", systemImage: "photo.badge.plus")
                }
            } footer: {
                Text("Save a brainrot picture to Photos, then add it here with its name. The Italian voice reads the name out.")
            }
            Section {
                ForEach(store.custom) { own in
                    HStack(spacing: 12) {
                        BrainrotPicture(item: .custom(own), size: 52, animated: false)
                        Text(own.name)
                        Spacer()
                        Button {
                            Speech.shared.say(own.name, language: "it-IT", rate: 0.42, pitch: 0.9)
                        } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Listen")
                    }
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) { store.deleteCustom(own.id) }
                    }
                }
            }
        }
        .navigationTitle("Own pictures")
        .onChange(of: item) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    name = ""
                    pending = PendingPicture(image: image)
                }
                self.item = nil
            }
        }
        .sheet(item: $pending) { picture in
            NavigationStack {
                VStack(spacing: 20) {
                    Image(uiImage: picture.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(.rect(cornerRadius: 20))
                    TextField("Name, e.g. Tralalero Tralala", text: $name)
                        .font(.system(size: 18, weight: .semibold))
                        .autocorrectionDisabled()
                        .card(padding: 14)
                    Spacer()
                }
                .padding(20)
                .background(Color.bg)
                .navigationTitle("New picture")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { pending = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            store.addCustom(name: name.trimmed, image: picture.image)
                            pending = nil
                        }
                        .disabled(name.trimmed.isEmpty)
                    }
                }
            }
        }
    }
}
