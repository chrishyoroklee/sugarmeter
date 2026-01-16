//
//  SugaMeterWidgetBundle.swift
//  SugaMeterWidget
//
//  Created by 이효록 on 1/15/26.
//

import WidgetKit
import SwiftUI

@main
struct SugaMeterWidgetBundle: WidgetBundle {
    var body: some Widget {
        SugaMeterWidget()
        SugaMeterLockScreenWidget()
        SugaMeterWidgetControl()
        SugaMeterWidgetLiveActivity()
    }
}
