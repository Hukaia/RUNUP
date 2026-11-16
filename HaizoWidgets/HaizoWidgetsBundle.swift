import WidgetKit
import SwiftUI

@main
struct HaizoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DailyGoalsWidget()
        RunActivityWidget()
    }
}
