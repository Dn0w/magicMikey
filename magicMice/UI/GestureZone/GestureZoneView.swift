import SwiftUI

/// Gesture / trackpad zone — sits BELOW the keyboard, like a MacBook trackpad.
struct GestureZoneView: View {
    @StateObject private var vm = GestureZoneViewModel()

    var body: some View {
        ZStack {
            // Background — dark glass with subtle grid
            Color(hex: "#111118")
                .overlay(gridTexture)

            // Touch ripple
            if vm.showRipple {
                Circle()
                    .stroke(Color(hex: "#4A9EFF").opacity(0.5), lineWidth: 1.5)
                    .frame(width: 60, height: 60)
                    .position(vm.rippleLocation)
                    .scaleEffect(vm.showRipple ? 1.6 : 0.4)
                    .opacity(vm.showRipple ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: vm.showRipple)
            }

            // Hint label
            Text("trackpad")
                .font(.system(size: 11, weight: .light, design: .monospaced))
                .foregroundColor(Color(hex: "#2E2E3E"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#1C1C24"), lineWidth: 1)
        )
        .gesture(panGesture)
        .simultaneousGesture(pinchGesture)
        .onTapGesture(count: 1) { /* single tap */ }
    }

    // MARK: - Grid texture

    private var gridTexture: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 24
            var x: CGFloat = 0
            while x < size.width {
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }, with: .color(Color(hex: "#1A1A22")), lineWidth: 0.5)
                x += spacing
            }
            var y: CGFloat = 0
            while y < size.height {
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(Color(hex: "#1A1A22")), lineWidth: 0.5)
                y += spacing
            }
        }
    }

    // MARK: - Gestures

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                vm.handlePan(translation: value.translation,
                             velocity: value.velocity,
                             state: .changed)
                vm.triggerRipple(at: value.location)
            }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                vm.handlePinch(scale: value.magnification, velocity: 0)
            }
    }
}
