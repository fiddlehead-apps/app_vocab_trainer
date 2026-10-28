import SwiftUI

/// Slim line drawing in the style of the app icon. Coordinates are those of the
/// 1024 px icon canvas (tools/make_icon.py); `area` is the part of it to show.
struct LineArt: View {
    let area: CGRect
    let width: CGFloat
    var lineWidth: CGFloat = 3.5
    var color: Color = .brand
    let draw: (inout Path) -> Void

    var body: some View {
        let scale = width / area.width
        Canvas { ctx, _ in
            var path = Path()
            draw(&path)
            let fit = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: -area.minX, y: -area.minY)
            ctx.stroke(path.applying(fit), with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: width, height: area.height * scale)
        .accessibilityHidden(true)
    }
}

extension Path {
    /// Fiddlehead curl starting at `start`, leaving in direction `heading`
    /// (degrees, 0 = up, clockwise). Same construction as the curl in the app icon.
    mutating func addFiddlehead(at start: CGPoint, heading: Double, radius: Double, turns: Int = 3, left: Bool = false) {
        let h = heading * .pi / 180, flip: Double = left ? -1 : 1
        func place(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: start.x + flip * x * cos(h) - y * sin(h), y: start.y + flip * x * sin(h) + y * cos(h))
        }
        move(to: start)
        var from = 0.0
        for (i, f) in [1, 0.64, 0.33, 0.12].prefix(turns).enumerated() {
            let r = radius * f
            let (cx, a0) = i % 2 == 0 ? (from + r, Double.pi) : (from - r, 0)
            for k in 1...40 {
                let a = a0 + .pi * Double(k) / 40
                addLine(to: place(cx + r * cos(a), r * sin(a)))
            }
            from = cx - r * cos(a0)
        }
    }
}

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

/// An open book with a fern growing out of it. The motif of the app icon.
struct BookIllustration: View {
    var width: CGFloat = 120

    var body: some View {
        LineArt(area: CGRect(x: 196, y: 130, width: 632, height: 694), width: width) { p in
            p.move(to: pt(512, 500))
            p.addCurve(to: pt(220, 460), control1: pt(440, 462), control2: pt(340, 448))
            p.addLine(to: pt(220, 760))
            p.addCurve(to: pt(512, 800), control1: pt(340, 750), control2: pt(440, 762))
            p.addCurve(to: pt(804, 760), control1: pt(584, 762), control2: pt(684, 750))
            p.addLine(to: pt(804, 460))
            p.addCurve(to: pt(512, 500), control1: pt(684, 448), control2: pt(584, 462))
            p.closeSubpath()
            // spine
            p.move(to: pt(512, 500))
            p.addLine(to: pt(512, 800))
            // fern
            p.move(to: pt(512, 500))
            p.addCurve(to: pt(556, 300), control1: pt(512, 420), control2: pt(520, 360))
            p.addFiddlehead(at: pt(556, 300), heading: atan2(36, 60) * 180 / .pi, radius: 96, left: true)
        }
    }
}

/// A magnifier that finds nothing but a fern.
struct SearchIllustration: View {
    var body: some View {
        LineArt(area: CGRect(x: 226, y: 216, width: 578, height: 578), width: 96) { p in
            p.addEllipse(in: CGRect(x: 250, y: 240, width: 400, height: 400))
            p.move(to: pt(592, 582))
            p.addLine(to: pt(780, 770))
            p.move(to: pt(420, 560))
            p.addCurve(to: pt(476, 430), control1: pt(420, 500), control2: pt(440, 460))
            p.addFiddlehead(at: pt(476, 430), heading: 45, radius: 52)
        }
    }
}
