//
//  SugaMeterWidgetLiveActivity.swift
//  SugaMeterWidget
//
//  Created by 이효록 on 1/15/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SugaMeterWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SugaMeterWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SugaMeterWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SugaMeterWidgetAttributes {
    fileprivate static var preview: SugaMeterWidgetAttributes {
        SugaMeterWidgetAttributes(name: "World")
    }
}

extension SugaMeterWidgetAttributes.ContentState {
    fileprivate static var smiley: SugaMeterWidgetAttributes.ContentState {
        SugaMeterWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SugaMeterWidgetAttributes.ContentState {
         SugaMeterWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SugaMeterWidgetAttributes.preview) {
   SugaMeterWidgetLiveActivity()
} contentStates: {
    SugaMeterWidgetAttributes.ContentState.smiley
    SugaMeterWidgetAttributes.ContentState.starEyes
}
