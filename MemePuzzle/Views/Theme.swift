import SwiftUI

public enum Theme {
    public static let backgroundTop = Color(red: 0.05, green: 0.04, blue: 0.11)
    public static let backgroundMid = Color(red: 0.09, green: 0.07, blue: 0.18)
    public static let backgroundBottom = Color(red: 0.06, green: 0.05, blue: 0.14)

    public static let frame = Color(red: 0.18, green: 0.16, blue: 0.27)
    public static let frameHighlight = Color(red: 0.98, green: 0.80, blue: 0.25)
    public static let emptySlot = Color(red: 0.05, green: 0.05, blue: 0.09)
    public static let tray = Color(red: 0.95, green: 0.94, blue: 0.98)
    public static let trayText = Color(red: 0.16, green: 0.14, blue: 0.24)
    public static let accent = Color(red: 1.0, green: 0.78, blue: 0.18)
    public static let success = Color(red: 0.25, green: 0.86, blue: 0.47)
    public static let failure = Color(red: 1.0, green: 0.30, blue: 0.33)

    // Arcade & Neon Blitz Palette
    public static let neonViolet = Color(red: 0.68, green: 0.32, blue: 0.98)
    public static let neonGold = Color(red: 1.0, green: 0.76, blue: 0.14)
    public static let neonOrange = Color(red: 1.0, green: 0.52, blue: 0.15)
    public static let neonCyan = Color(red: 0.12, green: 0.86, blue: 0.94)

    // Mode Accents
    public static let easyEmerald = Color(red: 0.08, green: 0.84, blue: 0.56)
    public static let mediumAmber = Color(red: 1.0, green: 0.76, blue: 0.14)
    public static let hardMagenta = Color(red: 0.82, green: 0.35, blue: 0.98)
    public static let extremeCrimson = Color(red: 1.0, green: 0.12, blue: 0.38)

    public static var background: some View {
        ZStack {
            LinearGradient(
                colors: [backgroundTop, backgroundMid, backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle purple radial ambiance
            RadialGradient(
                colors: [neonViolet.opacity(0.18), .clear],
                center: .top,
                startRadius: 40,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }
}

/// Horizontal shake used for rejected drops.
public struct ShakeEffect: GeometryEffect {
    public var travel: CGFloat = 6
    public var animatableData: CGFloat

    public init(travel: CGFloat = 6, animatableData: CGFloat) {
        self.travel = travel
        self.animatableData = animatableData
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * 6), y: 0))
    }
}

public extension View {
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
            .animation(.linear(duration: 0.4), value: trigger)
    }

    func arcadeGlass(
        stroke: Color = Color.white.opacity(0.14),
        lineWidth: CGFloat = 1.2,
        cornerRadius: CGFloat = 20,
        fillOpacity: Double = 0.08
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(fillOpacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(red: 0.07, green: 0.06, blue: 0.15).opacity(0.6))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(stroke, lineWidth: lineWidth)
            )
    }
}
