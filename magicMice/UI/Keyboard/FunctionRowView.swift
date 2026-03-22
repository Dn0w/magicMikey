import SwiftUI

/// Collapsible F1–F12 + Esc row. Revealed by swiping up on the keyboard.
struct FunctionRowView: View {
    let layout: KeyboardLayout
    let onKey: (Key) -> Void
    @Binding var isExpanded: Bool

    var body: some View {
        if isExpanded {
            HStack(spacing: 4) {
                ForEach(layout.functionRow) { key in
                    KeyView(key: key, isArmed: false, keyHeight: 32) { onKey(key) }
                        .frame(height: 32)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
