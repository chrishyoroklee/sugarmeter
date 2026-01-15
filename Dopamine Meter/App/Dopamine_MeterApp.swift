//
//  Dopamine_MeterApp.swift
//  Dopamine Meter
//
//  Created by 이효록 on 1/14/26.
//

import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

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
                    AppGroup.migrateIfNeeded()
#if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
#endif
                    musicPlayer.start()
                }
                .preferredColorScheme(.light)
        }
    }
}
