import SwiftUI

struct LiquidFillView: View {
    var fillLevel: Double
    var size: CGSize
    var cornerRadius: CGFloat
    var surfaceHeight: CGFloat

    var body: some View {
        let fill = min(max(fillLevel, 0), 1)
        let fillHeight = size.height * fill
        let surfaceOffset = -max(fillHeight - surfaceHeight * 0.5, 0)
        let bodyShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack(alignment: .bottom) {
            if fill > 0.001 {
                bodyShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.73, blue: 0.36).opacity(0.95),
                                Color(red: 0.94, green: 0.48, blue: 0.2).opacity(0.96),
                                Color(red: 0.74, green: 0.25, blue: 0.16).opacity(0.98)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size.width, height: fillHeight)
                    .overlay(
                        bodyShape
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 8,
                                    endRadius: size.width * 0.7
                                )
                            )
                            .blendMode(.screen)
                    )
                    .overlay(
                        bodyShape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.black.opacity(0.22)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(0.6)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 6)
            }

            if fill > 0.01 {
                LiquidSurfaceView(size: CGSize(width: size.width * 0.92, height: surfaceHeight))
                    .offset(y: surfaceOffset)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .bottom)
        .clipShape(bodyShape)
    }
}

struct LiquidSurfaceView: View {
    var size: CGSize

    var body: some View {
        let highlightStroke = size.height * 0.12

        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.78, blue: 0.38).opacity(0.98),
                            Color(red: 0.92, green: 0.42, blue: 0.22).opacity(0.95)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Ellipse()
                .stroke(Color.white.opacity(0.25), lineWidth: highlightStroke * 0.6)

            WaveHighlightShape(waveHeight: size.height * 0.12, waveCount: 1.1)
                .stroke(Color.white.opacity(0.45), lineWidth: highlightStroke)
                .blur(radius: size.height * 0.06)
                .offset(y: -size.height * 0.12)
                .mask(Ellipse())
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct WaveHighlightShape: Shape {
    var waveHeight: CGFloat
    var waveCount: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midY = rect.midY
        let step = max(width / 60, 1)

        path.move(to: CGPoint(x: rect.minX, y: midY))

        var x: CGFloat = 0
        while x <= width {
            let progress = x / width
            let angle = Double(progress * waveCount) * 2 * Double.pi
            let y = midY + CGFloat(sin(angle)) * waveHeight
            path.addLine(to: CGPoint(x: rect.minX + x, y: y))
            x += step
        }

        return path
    }
}
