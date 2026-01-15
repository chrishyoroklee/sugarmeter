import SwiftUI

struct SugarMeterView: View {
    var fillLevel: Double
    var recommendedLevel: Double
    var ringLines: [RingLine]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let width = min(size.width, size.height * 0.72)
            let height = size.height
            let rimHeight = width * 0.22
            let bodyWidth = width * 0.82
            let bodyHeight = height - rimHeight * 0.2
            let bodyTop = rimHeight * 0.35
            let cornerRadius = bodyWidth * 0.22
            let fill = min(max(fillLevel, 0), 1)
            let liquidContainerHeight = bodyHeight * 0.94
            let liquidContainerTop = bodyTop + bodyHeight * 0.03
            let surfaceHeight = rimHeight * 0.5
            let handleWidth = width * 0.36
            let handleHeight = bodyHeight * 0.45
            let handleX = bodyWidth * 0.55

            ZStack(alignment: .top) {
                Ellipse()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: bodyWidth * 1.08, height: rimHeight * 0.5)
                    .offset(y: bodyTop + bodyHeight + rimHeight * 0.12)

                RoundedRectangle(cornerRadius: handleWidth * 0.45, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.92, blue: 0.9),
                                Color(red: 0.72, green: 0.7, blue: 0.68),
                                Color(red: 0.95, green: 0.93, blue: 0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: width * 0.06
                    )
                    .frame(width: handleWidth, height: handleHeight)
                    .offset(x: handleX, y: bodyTop + bodyHeight * 0.25)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.97, green: 0.95, blue: 0.92),
                                Color(red: 0.83, green: 0.81, blue: 0.78),
                                Color(red: 0.95, green: 0.93, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: bodyWidth, height: bodyHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(red: 0.78, green: 0.76, blue: 0.72), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 10)
                    .offset(y: bodyTop)

                LiquidFillView(
                    fillLevel: fill,
                    size: CGSize(width: bodyWidth * 0.9, height: liquidContainerHeight),
                    cornerRadius: cornerRadius * 0.9,
                    surfaceHeight: surfaceHeight,
                    recommendedLevel: recommendedLevel,
                    ringLines: ringLines
                )
                .offset(y: liquidContainerTop)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: bodyWidth * 0.9, height: bodyHeight * 0.92)
                    .offset(x: -bodyWidth * 0.08, y: bodyTop + bodyHeight * 0.04)
                    .blendMode(.screen)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.97, blue: 0.96),
                                Color(red: 0.74, green: 0.72, blue: 0.7),
                                Color(red: 0.96, green: 0.95, blue: 0.94)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: bodyWidth * 1.02, height: rimHeight)
                    .offset(y: bodyTop - rimHeight * 0.55)

                Ellipse()
                    .fill(Color(red: 0.65, green: 0.63, blue: 0.62))
                    .frame(width: bodyWidth * 0.84, height: rimHeight * 0.52)
                    .offset(y: bodyTop - rimHeight * 0.28)
            }
            .frame(width: width, height: height, alignment: .top)
            .position(x: size.width / 2, y: size.height / 2)
        }
    }
}
