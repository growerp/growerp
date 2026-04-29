//
//  Accounting_WidgetLiveActivity.swift
//  Accounting Widget
//
//  Created by hans on 29/4/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Accounting_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Accounting_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Accounting_WidgetAttributes.self) { context in
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

extension Accounting_WidgetAttributes {
    fileprivate static var preview: Accounting_WidgetAttributes {
        Accounting_WidgetAttributes(name: "World")
    }
}

extension Accounting_WidgetAttributes.ContentState {
    fileprivate static var smiley: Accounting_WidgetAttributes.ContentState {
        Accounting_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Accounting_WidgetAttributes.ContentState {
         Accounting_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Accounting_WidgetAttributes.preview) {
   Accounting_WidgetLiveActivity()
} contentStates: {
    Accounting_WidgetAttributes.ContentState.smiley
    Accounting_WidgetAttributes.ContentState.starEyes
}
