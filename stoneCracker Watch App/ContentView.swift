//
//  ContentView.swift
//  stoneCracker Watch App
//
//  Created by Miguel Susano on 01/10/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorderViewModel()

    var body: some View {
        VStack {
            // Show mic icon based on recording state
            Image(systemName: audioRecorder.isRecording ? "mic.fill" : "mic.slash")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .padding()

            // Text to show whether recording or idle
            Text(audioRecorder.isRecording ? "Recording..." : "Tap to Record")
            
            // Button to toggle recording
            Button(action: {
                audioRecorder.toggleRecording()
            }) {
                Text(audioRecorder.isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(audioRecorder.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            // Button to play or stop playback
            Button(action: {
                audioRecorder.togglePlayback()
            }) {
                Text(audioRecorder.isPlaying ? "Stop Playing" : "Play Recording")
                    .padding()
                    .background(audioRecorder.isPlaying ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
