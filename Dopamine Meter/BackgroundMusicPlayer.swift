import AVFoundation

struct MusicTrack: Identifiable, Equatable {
    let id: String
    let displayName: String
    let fileName: String
}

final class BackgroundMusicPlayer: NSObject, ObservableObject {
    let tracks: [MusicTrack]
    @Published var selectedTrackID: String {
        didSet {
            guard !isSelectionChangeInternal else { return }
            selectTrack(id: selectedTrackID)
        }
    }

    private var currentIndex = 0
    private var player: AVAudioPlayer?
    private var hasStarted = false
    private var isSelectionChangeInternal = false

    init(tracks: [MusicTrack]) {
        self.tracks = tracks
        self.selectedTrackID = tracks.first?.id ?? ""
        super.init()
        if let index = tracks.firstIndex(where: { $0.id == selectedTrackID }) {
            currentIndex = index
        }
    }

    func start() {
        guard !tracks.isEmpty else { return }
        guard !hasStarted else { return }
        hasStarted = true
        configureSession()
        playCurrent()
    }

    func stop() {
        player?.stop()
        player = nil
        hasStarted = false
    }

    func selectTrack(id: String) {
        guard let index = tracks.firstIndex(where: { $0.id == id }) else { return }
        currentIndex = index
        if !hasStarted {
            start()
            return
        }
        playCurrent()
    }

    private func playCurrent() {
        guard !tracks.isEmpty else { return }
        let track = tracks[currentIndex]
        guard let url = urlForTrack(named: track.fileName) else { return }
        player?.stop()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 0.7
            player?.play()
        } catch {
            player = nil
        }
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
        }
    }

    private func advanceToNextTrack() {
        guard !tracks.isEmpty else { return }
        currentIndex = (currentIndex + 1) % tracks.count
        updateSelection(id: tracks[currentIndex].id)
        playCurrent()
    }

    private func updateSelection(id: String) {
        isSelectionChangeInternal = true
        selectedTrackID = id
        isSelectionChangeInternal = false
    }

    private func urlForTrack(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            return url
        }
        let parts = name.split(separator: ".", maxSplits: 1).map(String.init)
        if parts.count == 2, let url = Bundle.main.url(forResource: parts[0], withExtension: parts[1]) {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: "mp3")
    }
}

extension BackgroundMusicPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        advanceToNextTrack()
    }
}
