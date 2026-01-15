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
            MusicTrack(id: "main5", displayName: "Main 5", fileName: "main5.mp3")
        ]
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(musicPlayer)
                .onAppear {
                    musicPlayer.start()
                }
        }
    }
}
