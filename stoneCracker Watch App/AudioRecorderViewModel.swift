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

    override init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFileURL = documentsDirectory.appendingPathComponent("recording.pcm")  // Use .pcm extension for raw audio
        super.init()
        
        // Initialize WebSocket
        let urlws = URL(string: "http://127.0.0.1:5000/reverse")!
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

    // Send audio chunk to Flask API
    func sendAudioChunkToAPI() {
        guard chunk.count >= chunkSize else {
            print("Chunk not full...", chunk.count, chunkSize)
            return  // Ensure we only send when we have a full chunk
        }
        
        let url = URL(string: "http://127.0.0.1:5000/audio")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"chunk.pcm\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/pcm\r\n\r\n".data(using: .utf8)!)
        body.append(chunk)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error sending audio chunk: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Audio chunk uploaded successfully!")
                self?.chunk.removeAll()  // Reset chunk after successful upload
            } else {
                print("Failed to upload audio chunk.")
            }
        }
        task.resume()
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
        let url = URL(string: "http://127.0.0.1:5000/finalize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
}
