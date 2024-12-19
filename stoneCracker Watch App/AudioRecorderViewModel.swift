import Foundation
import AVFoundation
import WatchKit
import Starscream

class AudioRecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate, WebSocketDelegate {
    
    
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var playbackProgress: CGFloat = 0.0

    let audioFileURL: URL
    var fileHandle: FileHandle?  // File handle for reading data during recording
    let chunkSize: Int = 2048  // Chunk size in bytes for uploading
    var fileOffset: UInt64 = 0  // Keep track of how much data has been read and sent
    var chunk: Data = Data()  // Initialize with empty data
    var fileLength: UInt64 = 0  // Track the length of the file

    // WebSocket properties
    var socket: WebSocket?
    
    // Timer to update playback progress
    var playbackTimer: Timer?

    override init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFileURL = documentsDirectory.appendingPathComponent("recording.pcm")  // Use .pcm extension for raw audio
        super.init()
        
        // Initialize WebSocket
        let urlws = URL(string: "http://144.24.177.214:5001/reverse")!
        var request = URLRequest(url: urlws)
        socket = WebSocket(request: request)
        socket?.delegate = self  // Set this class as the WebSocket delegate
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            setupRecorder()
            startRecording()
        }
    }

    func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            // PCM settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),  // Raw PCM format
                AVSampleRateKey: 16000,  // 16kHz sampling rate
                AVNumberOfChannelsKey: 1,  // Mono
                AVLinearPCMBitDepthKey: 16,  // 16-bit audio depth
                AVLinearPCMIsFloatKey: false,  // Integer PCM
                AVLinearPCMIsBigEndianKey: false  // Little-endian PCM
            ]

            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to set up audio recorder: \(error)")
        }
    }

    func startRecording() {
        if audioRecorder == nil {
            setupRecorder()
        }
        audioRecorder?.record()
        isRecording = true
        WKInterfaceDevice.current().play(.start)
        
        // Open the file for streaming chunks
        startStreamingChunks()
        
        // Connect to WebSocket
        socket?.connect()
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        WKInterfaceDevice.current().play(.stop)
        print("Stopped recording")

        stopStreamingChunks()
        
        // Close WebSocket connection
        socket?.disconnect()
    }

    func startStreamingChunks() {
        do {
            fileHandle = try FileHandle(forReadingFrom: audioFileURL)
            fileOffset = 0  // Reset the file offset when starting
        } catch {
            print("Failed to open file for reading: \(error)")
            return
        }
        
        // Start checking for new data periodically
        checkForNewData()
    }

    func stopStreamingChunks() {
        fileHandle?.closeFile()
        fileHandle = nil
    }

    func checkForNewData() {
        // Use a timer to periodically check if new data has been written to the file
        Timer.scheduledTimer(withTimeInterval: 0.064, repeats: true) { [weak self] timer in
            guard let strongSelf = self else { return }

            if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: strongSelf.audioFileURL.path),
               let newFileSize = fileAttributes[FileAttributeKey.size] as? UInt64 {
                
                // Only read if there is new data available
                if newFileSize > strongSelf.fileOffset {
                    strongSelf.readAndStreamAudioData(newFileSize: newFileSize)
                }
            }

            // Stop the timer if recording has finished
            if !(strongSelf.isRecording) {
                timer.invalidate()
                strongSelf.finalizeAudioOnServer()
            }
        }
    }

    func readAndStreamAudioData(newFileSize: UInt64) {
        // Read only the new data
        do {
            fileHandle?.seek(toFileOffset: fileOffset)
            let availableDataSize = Int(newFileSize - fileOffset)
            let readSize = min(availableDataSize, chunkSize)

            let data = fileHandle?.readData(ofLength: readSize)

            guard let chunkData = data else {
                print("No more data to read.")
                return
            }

            chunk.append(chunkData)

            // Update the file offset after reading
            fileOffset += UInt64(readSize)

            // When chunk reaches the target size, send it
            if chunk.count >= chunkSize {
                //sendAudioChunkToAPI()
                sendAudioChunkToWebSocket()  // Send to WebSocket as well
            }
        } catch {
            print("Failed to read audio file: \(error)")
            stopStreamingChunks()
        }
    }

    // Send audio chunk to WebSocket
    func sendAudioChunkToWebSocket() {
        guard chunk.count >= chunkSize else {
            print("Chunk not full for WebSocket...", chunk.count, chunkSize)
            return
        }

        // Send the chunk data via WebSocket (ensure the data is binary)
        socket?.write(data: chunk)

        // Reset the chunk after sending
        chunk.removeAll()
    }

    // Call server to finalize and reconstruct the audio
    func finalizeAudioOnServer() {
        let url = URL(string: "http://192.168.1.140:5001/finalize")!

        // Since we need to make a POST request, we still need URLRequest to set the HTTP method.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        let task = URLSession(configuration: config).dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error finalizing audio: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Audio file reconstructed successfully!")
            } else {
                print("Failed to finalize audio.")
            }
        }
        task.resume()

    }

    // WebSocket delegate methods
    
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("canceled")
        case .error(let error):
            print("WebSocket disconnected with error: \(error)")
                   break
        case .peerClosed:
            print("peer closed")
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
}
