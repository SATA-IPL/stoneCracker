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
            Button(action: {
                audioRecorder.toggleRecording()
            }) {
                ZStack{
                    Circle()
                        .trim(from: 0.0, to: audioRecorder.isPlaying ? audioRecorder.playbackProgress : 1.0)
                        .stroke(.white.opacity(0.5), lineWidth: 2)
                        .foregroundStyle(.ultraThinMaterial)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.2), value: audioRecorder.playbackProgress)
                    if audioRecorder.isRecording {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.red)
                            .frame(width: 75, height: 75)
                            .transition(.scale)
                    } else {
                        Circle()
                            .fill(audioRecorder.isPlaying ? Color.blue : Color.red)
                            .padding(10)
                            .transition(.scale)
                    }
                }
            }
            .handGestureShortcut(.primaryAction)
            .buttonStyle(.plain)
            .padding()
            .disabled(audioRecorder.isPlaying)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
