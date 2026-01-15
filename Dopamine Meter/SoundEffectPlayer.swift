import AVFoundation

final class SoundEffectPlayer: ObservableObject {
    private let soundName: String
    private var player: AVAudioPlayer?

    init(soundName: String) {
        self.soundName = soundName
        loadSound()
    }

    func play() {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    private func loadSound() {
        guard let url = urlForSound(named: soundName) else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = 0.9
        } catch {
            player = nil
        }
    }

    private func urlForSound(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            return url
        }
        let parts = name.split(separator: ".", maxSplits: 1).map(String.init)
        if parts.count == 2, let url = Bundle.main.url(forResource: parts[0], withExtension: parts[1]) {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: "wav")
    }
}
