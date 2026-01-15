//
//  Dopamine_MeterApp.swift
//  Dopamine Meter
//
//  Created by 이효록 on 1/14/26.
//

import SwiftUI

@main
struct Dopamine_MeterApp: App {
    @StateObject private var musicPlayer = BackgroundMusicPlayer(
        tracks: [
            MusicTrack(id: "main1", displayName: "Main 1", fileName: "main1.mp3"),
            MusicTrack(id: "main2", displayName: "Main 2", fileName: "main2.mp3"),
            MusicTrack(id: "main3", displayName: "Main 3", fileName: "main3.mp3"),
            MusicTrack(id: "main4", displayName: "Main 4", fileName: "main4.mp3")
        ]
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicPlayer)
                .onAppear {
                    musicPlayer.start()
                }
        }
    }
}
