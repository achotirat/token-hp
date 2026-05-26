import SwiftUI
import TokenCatCore

struct MenuBarIconView: View {
    let state: CatState

    @State private var isAlternateFrame = false

    var body: some View {
        Canvas { context, size in
            let stroke = StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round)
            let path = catPath(in: size)

            context.stroke(path, with: .color(.primary), style: stroke)

            if state == .sleeping {
                context.stroke(zzzPath(in: size), with: .color(.primary.opacity(0.72)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: 28, height: 18)
        .accessibilityLabel(accessibilityLabel)
        .task(id: state) {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(animationInterval))
                isAlternateFrame.toggle()
            }
        }
    }

    private var animationInterval: Int {
        switch state {
        case .sitting:
            return 560
        case .lyingDown:
            return 820
        case .sleeping:
            return 1_200
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .sitting:
            return "Token Cat healthy, walking"
        case .lyingDown:
            return "Token Cat low, sitting and yawning"
        case .sleeping:
            return "Token Cat exhausted, sleeping"
        }
    }

    private func catPath(in size: CGSize) -> Path {
        Path { path in
            switch state {
            case .sitting:
                walkingCat(in: size, path: &path)
            case .lyingDown:
                yawningCat(in: size, path: &path)
            case .sleeping:
                sleepingCat(in: size, path: &path)
            }
        }
    }

    private func walkingCat(in size: CGSize, path: inout Path) {
        let step = isAlternateFrame ? size.height * 0.12 : -size.height * 0.07
        let tailLift = isAlternateFrame ? size.height * 0.04 : 0

        path.move(to: CGPoint(x: size.width * 0.24, y: size.height * 0.55))
        path.addCurve(
            to: CGPoint(x: size.width * 0.70, y: size.height * 0.50),
            control1: CGPoint(x: size.width * 0.34, y: size.height * 0.24),
            control2: CGPoint(x: size.width * 0.58, y: size.height * 0.24)
        )
        path.addCurve(
            to: CGPoint(x: size.width * 0.79, y: size.height * 0.42),
            control1: CGPoint(x: size.width * 0.73, y: size.height * 0.39),
            control2: CGPoint(x: size.width * 0.76, y: size.height * 0.37)
        )
        path.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.22))
        path.addLine(to: CGPoint(x: size.width * 0.90, y: size.height * 0.42))
        path.addCurve(
            to: CGPoint(x: size.width * 0.78, y: size.height * 0.58),
            control1: CGPoint(x: size.width * 0.89, y: size.height * 0.52),
            control2: CGPoint(x: size.width * 0.84, y: size.height * 0.57)
        )
        path.addCurve(
            to: CGPoint(x: size.width * 0.25, y: size.height * 0.61),
            control1: CGPoint(x: size.width * 0.62, y: size.height * 0.76),
            control2: CGPoint(x: size.width * 0.38, y: size.height * 0.75)
        )

        path.move(to: CGPoint(x: size.width * 0.25, y: size.height * 0.53))
        path.addCurve(
            to: CGPoint(x: size.width * 0.07, y: size.height * 0.25 - tailLift),
            control1: CGPoint(x: size.width * 0.08, y: size.height * 0.51),
            control2: CGPoint(x: size.width * 0.03, y: size.height * 0.35)
        )

        path.move(to: CGPoint(x: size.width * 0.37, y: size.height * 0.67))
        path.addLine(to: CGPoint(x: size.width * 0.33, y: size.height * 0.92 + step))
        path.move(to: CGPoint(x: size.width * 0.55, y: size.height * 0.68))
        path.addLine(to: CGPoint(x: size.width * 0.60, y: size.height * 0.90 - step))
        path.move(to: CGPoint(x: size.width * 0.72, y: size.height * 0.61))
        path.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.82 + (step * 0.4)))

        path.move(to: CGPoint(x: size.width * 0.82, y: size.height * 0.45))
        path.addLine(to: CGPoint(x: size.width * 0.83, y: size.height * 0.45))
    }

    private func yawningCat(in size: CGSize, path: inout Path) {
        let mouthDrop = isAlternateFrame ? size.height * 0.13 : size.height * 0.06
        let headRise = isAlternateFrame ? -size.height * 0.02 : 0

        path.move(to: CGPoint(x: size.width * 0.22, y: size.height * 0.74))
        path.addCurve(
            to: CGPoint(x: size.width * 0.70, y: size.height * 0.70),
            control1: CGPoint(x: size.width * 0.32, y: size.height * 0.45),
            control2: CGPoint(x: size.width * 0.57, y: size.height * 0.47)
        )
        path.addCurve(
            to: CGPoint(x: size.width * 0.80, y: size.height * 0.42 + headRise),
            control1: CGPoint(x: size.width * 0.70, y: size.height * 0.53),
            control2: CGPoint(x: size.width * 0.73, y: size.height * 0.44)
        )
        path.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.20 + headRise))
        path.addLine(to: CGPoint(x: size.width * 0.91, y: size.height * 0.41 + headRise))
        path.addCurve(
            to: CGPoint(x: size.width * 0.73, y: size.height * 0.62),
            control1: CGPoint(x: size.width * 0.91, y: size.height * 0.57),
            control2: CGPoint(x: size.width * 0.83, y: size.height * 0.64)
        )

        path.move(to: CGPoint(x: size.width * 0.24, y: size.height * 0.68))
        path.addCurve(
            to: CGPoint(x: size.width * 0.10, y: size.height * 0.48),
            control1: CGPoint(x: size.width * 0.10, y: size.height * 0.75),
            control2: CGPoint(x: size.width * 0.06, y: size.height * 0.62)
        )

        path.move(to: CGPoint(x: size.width * 0.75, y: size.height * 0.46 + headRise))
        path.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.46 + headRise))
        path.move(to: CGPoint(x: size.width * 0.80, y: size.height * 0.53 + headRise))
        path.addCurve(
            to: CGPoint(x: size.width * 0.88, y: size.height * 0.53 + headRise + mouthDrop),
            control1: CGPoint(x: size.width * 0.84, y: size.height * 0.60 + headRise),
            control2: CGPoint(x: size.width * 0.88, y: size.height * 0.61 + headRise)
        )

        path.move(to: CGPoint(x: size.width * 0.38, y: size.height * 0.72))
        path.addLine(to: CGPoint(x: size.width * 0.32, y: size.height * 0.91))
        path.move(to: CGPoint(x: size.width * 0.56, y: size.height * 0.72))
        path.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.91))
    }

    private func sleepingCat(in size: CGSize, path: inout Path) {
        let breath = isAlternateFrame ? -size.height * 0.02 : size.height * 0.01

        path.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.68))
        path.addCurve(
            to: CGPoint(x: size.width * 0.72, y: size.height * 0.68 + breath),
            control1: CGPoint(x: size.width * 0.26, y: size.height * 0.37 + breath),
            control2: CGPoint(x: size.width * 0.58, y: size.height * 0.35 + breath)
        )
        path.addCurve(
            to: CGPoint(x: size.width * 0.88, y: size.height * 0.64),
            control1: CGPoint(x: size.width * 0.79, y: size.height * 0.51 + breath),
            control2: CGPoint(x: size.width * 0.88, y: size.height * 0.53)
        )
        path.addCurve(
            to: CGPoint(x: size.width * 0.17, y: size.height * 0.75),
            control1: CGPoint(x: size.width * 0.68, y: size.height * 0.87),
            control2: CGPoint(x: size.width * 0.35, y: size.height * 0.88)
        )

        path.move(to: CGPoint(x: size.width * 0.20, y: size.height * 0.66))
        path.addCurve(
            to: CGPoint(x: size.width * 0.09, y: size.height * 0.52),
            control1: CGPoint(x: size.width * 0.08, y: size.height * 0.72),
            control2: CGPoint(x: size.width * 0.04, y: size.height * 0.62)
        )

        path.move(to: CGPoint(x: size.width * 0.75, y: size.height * 0.57 + breath))
        path.addCurve(
            to: CGPoint(x: size.width * 0.83, y: size.height * 0.56 + breath),
            control1: CGPoint(x: size.width * 0.77, y: size.height * 0.61 + breath),
            control2: CGPoint(x: size.width * 0.81, y: size.height * 0.61 + breath)
        )
    }

    private func zzzPath(in size: CGSize) -> Path {
        Path { path in
            let drift = isAlternateFrame ? -size.height * 0.05 : 0

            path.move(to: CGPoint(x: size.width * 0.63, y: size.height * 0.15 + drift))
            path.addLine(to: CGPoint(x: size.width * 0.73, y: size.height * 0.15 + drift))
            path.addLine(to: CGPoint(x: size.width * 0.63, y: size.height * 0.27 + drift))
            path.addLine(to: CGPoint(x: size.width * 0.73, y: size.height * 0.27 + drift))

            path.move(to: CGPoint(x: size.width * 0.78, y: size.height * 0.04 + drift))
            path.addLine(to: CGPoint(x: size.width * 0.86, y: size.height * 0.04 + drift))
            path.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.14 + drift))
            path.addLine(to: CGPoint(x: size.width * 0.86, y: size.height * 0.14 + drift))
        }
    }
}
