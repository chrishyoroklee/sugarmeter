import SwiftUI

struct LiquidFillView: View {
    var fillLevel: Double
    var size: CGSize
    var cornerRadius: CGFloat
    var surfaceHeight: CGFloat
    var recommendedLevel: Double
    var ringLines: [RingLine]
    var palette: LiquidPalette

    var body: some View {
        let fill = min(max(fillLevel, 0), 1)
        let fillHeight = size.height * fill
        let recommendedHeight = size.height * min(max(recommendedLevel, 0), 1)
        let surfaceOffset = -max(fillHeight - surfaceHeight * 0.5, 0)
        let bodyShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack(alignment: .bottom) {
            if fill > 0.001 {
                bodyShape
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.top,
                                palette.mid,
                                palette.bottom
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
                LiquidSurfaceView(
                    size: CGSize(width: size.width * 0.92, height: surfaceHeight),
                    palette: palette
                )
                    .offset(y: surfaceOffset)
            }

            ForEach(ringLines) { ring in
                Group {
                    if ring.isDashed {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: size.width, y: 0))
                        }
                        .stroke(
                            ring.color.opacity(0.7),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 6])
                        )
                    } else {
                        Rectangle()
                            .fill(ring.color.opacity(0.55))
                            .frame(height: 1)
                    }
                }
                .offset(y: -size.height * ring.fraction)
            }

            Rectangle()
                .fill(AppTheme.primary.opacity(0.75))
                .frame(height: 2)
                .offset(y: -recommendedHeight)
                .shadow(color: Color.white.opacity(0.4), radius: 2, x: 0, y: 0)
        }
        .frame(width: size.width, height: size.height, alignment: .bottom)
        .clipShape(bodyShape)
    }
}

struct LiquidSurfaceView: View {
    var size: CGSize
    var palette: LiquidPalette

    var body: some View {
        let highlightStroke = size.height * 0.12

        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            palette.surfaceTop,
                            palette.surfaceBottom
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
