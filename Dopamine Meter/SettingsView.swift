import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var musicPlayer: BackgroundMusicPlayer

    var body: some View {
        NavigationStack {
            Form {
                Section("Music") {
                    Picker("Track", selection: $musicPlayer.selectedTrackID) {
                        ForEach(musicPlayer.tracks) { track in
                            Text(track.displayName)
                                .tag(track.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
