import Foundation
import AVFoundation
import WatchKit

class AudioRecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var playbackProgress: CGFloat = 0.0

    // URL where the audio file will be saved
    let audioFileURL: URL
    
    // Timer to update playback progress
    var playbackTimer: Timer?

    override init() {
        // Set up the file path for the recording
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFileURL = documentsDirectory.appendingPathComponent("recording.m4a")
        
        super.init()
    }

    // Set up the audio session and recorder
    func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to set up audio recorder: \(error)")
        }
    }

    // Start recording
    func startRecording() {
        if audioRecorder == nil {
            setupRecorder()
        }
        audioRecorder?.record()
        isRecording = true
        WKInterfaceDevice.current().play(.start)
    }

    // Stop recording
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        self.togglePlayback()
        WKInterfaceDevice.current().play(.stop)
    }

    // Toggle recording state
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // Play the recorded audio
    func playRecording() {
        if !FileManager.default.fileExists(atPath: audioFileURL.path) {
            print("No recording found at \(audioFileURL.path)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true

            // Start timer to update playback progress
            startPlaybackTimer()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    // Stop playing audio
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }

    // Toggle playback state
    func togglePlayback() {
        if isPlaying {
            stopPlaying()
        } else {
            playRecording()
        }
    }
    
    // Start the timer to update playback progress
        private func startPlaybackTimer() {
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updatePlaybackProgress()
            }
        }

        // Stop the timer when playback finishes or stops
        private func stopPlaybackTimer() {
            playbackTimer?.invalidate()
            playbackTimer = nil
        }

        // Update the playback progress
        private func updatePlaybackProgress() {
            guard let audioPlayer = audioPlayer else { return }

            // Calculate the progress (currentTime / duration)
            let progress = CGFloat(audioPlayer.currentTime / audioPlayer.duration)
            playbackProgress = progress
        }

    // AVAudioPlayerDelegate method: stops playing after audio finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        WKInterfaceDevice.current().play(.success)
    }
}
