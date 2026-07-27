import SwiftUI
import AppKit

struct PointingHand: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

extension View {
    func pointingHand() -> some View {
        modifier(PointingHand())
    }
}
