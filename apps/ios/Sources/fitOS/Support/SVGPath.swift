import CoreGraphics
import Foundation

/// Minimal SVG path-data parser: turns an SVG `d` string into a CGPath.
/// Supports M/L/H/V/C/S/Q/T/A/Z (absolute + relative). Elliptical arcs are
/// converted to cubic béziers so ellipse rotation is handled correctly.
enum SVGPath {
    private struct Token { let isCommand: Bool; let command: Character; let value: CGFloat }

    static func cgPath(from d: String) -> CGPath {
        let path = CGMutablePath()
        let tokens = tokenize(d)
        var idx = 0
        var current = CGPoint.zero
        var subStart = CGPoint.zero
        var prevCtrl: CGPoint?
        var prevCmd: Character = " "

        func hasNumber() -> Bool { idx < tokens.count && !tokens[idx].isCommand }
        func num() -> CGFloat { defer { idx += 1 }; return idx < tokens.count ? tokens[idx].value : 0 }
        func pt(_ rel: Bool) -> CGPoint {
            let x = num(); let y = num()
            return rel ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }
        func reflect() -> CGPoint {
            guard let c = prevCtrl else { return current }
            return CGPoint(x: 2 * current.x - c.x, y: 2 * current.y - c.y)
        }

        while idx < tokens.count {
            let cmd: Character
            if tokens[idx].isCommand {
                cmd = tokens[idx].command; idx += 1
            } else {
                // Implicit repeat: after M/m subsequent pairs are line-to.
                cmd = (prevCmd == "M") ? "L" : (prevCmd == "m") ? "l" : prevCmd
            }
            let rel = cmd.isLowercase
            let u = Character(cmd.uppercased())
            switch u {
            case "M":
                current = pt(rel); path.move(to: current); subStart = current
                prevCtrl = nil
            case "L":
                current = pt(rel); path.addLine(to: current); prevCtrl = nil
            case "H":
                let x = num(); current = CGPoint(x: rel ? current.x + x : x, y: current.y)
                path.addLine(to: current); prevCtrl = nil
            case "V":
                let y = num(); current = CGPoint(x: current.x, y: rel ? current.y + y : y)
                path.addLine(to: current); prevCtrl = nil
            case "C":
                let c1 = pt(rel), c2 = pt(rel), end = pt(rel)
                path.addCurve(to: end, control1: c1, control2: c2)
                current = end; prevCtrl = c2
            case "S":
                let c1 = (prevCmd == "C" || prevCmd == "c" || prevCmd == "S" || prevCmd == "s") ? reflect() : current
                let c2 = pt(rel), end = pt(rel)
                path.addCurve(to: end, control1: c1, control2: c2)
                current = end; prevCtrl = c2
            case "Q":
                let c = pt(rel), end = pt(rel)
                path.addQuadCurve(to: end, control: c)
                current = end; prevCtrl = c
            case "T":
                let c = (prevCmd == "Q" || prevCmd == "q" || prevCmd == "T" || prevCmd == "t") ? reflect() : current
                let end = pt(rel)
                path.addQuadCurve(to: end, control: c)
                current = end; prevCtrl = c
            case "A":
                let rx = num(), ry = num(), rot = num()
                let large = num() != 0, sweep = num() != 0
                let end = pt(rel)
                addArc(path, from: current, rx: rx, ry: ry, rotationDeg: rot, largeArc: large, sweep: sweep, to: end)
                current = end; prevCtrl = nil
            case "Z":
                path.closeSubpath(); current = subStart; prevCtrl = nil
            default:
                idx += 1 // unknown token — skip to avoid a stall
            }
            prevCmd = cmd
        }
        return path
    }

    // MARK: - Tokenizer

    private static func tokenize(_ d: String) -> [Token] {
        var out: [Token] = []
        let chars = Array(d)
        let n = chars.count
        var i = 0
        func isCmd(_ c: Character) -> Bool { "MmLlHhVvCcSsQqTtAaZz".contains(c) }
        func isDigit(_ c: Character) -> Bool { c >= "0" && c <= "9" }
        while i < n {
            let c = chars[i]
            if c == " " || c == "," || c == "\n" || c == "\t" || c == "\r" { i += 1; continue }
            if isCmd(c) { out.append(Token(isCommand: true, command: c, value: 0)); i += 1; continue }
            var j = i
            if chars[j] == "+" || chars[j] == "-" { j += 1 }
            while j < n && (isDigit(chars[j]) || chars[j] == ".") { j += 1 }
            if j < n && (chars[j] == "e" || chars[j] == "E") {
                j += 1
                if j < n && (chars[j] == "+" || chars[j] == "-") { j += 1 }
                while j < n && isDigit(chars[j]) { j += 1 }
            }
            if j > i, let v = Double(String(chars[i..<j])) {
                out.append(Token(isCommand: false, command: " ", value: CGFloat(v)))
                i = j
            } else {
                i += 1
            }
        }
        return out
    }

    // MARK: - Arc → bézier (SVG implementation notes, F.6)

    private static func addArc(_ path: CGMutablePath, from p0: CGPoint,
                               rx rxIn: CGFloat, ry ryIn: CGFloat, rotationDeg: CGFloat,
                               largeArc: Bool, sweep: Bool, to p1: CGPoint) {
        if p0 == p1 { return }
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 { path.addLine(to: p1); return }

        let phi = rotationDeg * .pi / 180
        let cosP = cos(phi), sinP = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cosP * dx + sinP * dy
        let y1 = -sinP * dx + cosP * dy

        var rx2 = rx * rx, ry2 = ry * ry
        let lambda = (x1 * x1) / rx2 + (y1 * y1) / ry2
        if lambda > 1 { let s = sqrt(lambda); rx *= s; ry *= s; rx2 = rx * rx; ry2 = ry * ry }

        let sign: CGFloat = (largeArc != sweep) ? 1 : -1
        var numer = rx2 * ry2 - rx2 * y1 * y1 - ry2 * x1 * x1
        if numer < 0 { numer = 0 }
        let denom = rx2 * y1 * y1 + ry2 * x1 * x1
        let coef = denom > 0 ? sign * sqrt(numer / denom) : 0
        let cxp = coef * (rx * y1 / ry)
        let cyp = coef * (-ry * x1 / rx)
        let cx = cosP * cxp - sinP * cyp + (p0.x + p1.x) / 2
        let cy = sinP * cxp + cosP * cyp + (p0.y + p1.y) / 2

        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let dot = ux * vx + uy * vy
            let len = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
            var a = acos(min(max(len > 0 ? dot / len : 0, -1), 1))
            if (ux * vy - uy * vx) < 0 { a = -a }
            return a
        }
        let ux = (x1 - cxp) / rx, uy = (y1 - cyp) / ry
        let vx = (-x1 - cxp) / rx, vy = (-y1 - cyp) / ry
        let theta1 = angle(1, 0, ux, uy)
        var dTheta = angle(ux, uy, vx, vy)
        if !sweep && dTheta > 0 { dTheta -= 2 * .pi }
        if sweep && dTheta < 0 { dTheta += 2 * .pi }

        let segs = max(Int(ceil(abs(dTheta) / (.pi / 2))), 1)
        let delta = dTheta / CGFloat(segs)
        let t = 4.0 / 3.0 * tan(delta / 4)
        var theta = theta1

        func point(_ ct: CGFloat, _ st: CGFloat) -> CGPoint {
            let ex = rx * ct, ey = ry * st
            return CGPoint(x: cosP * ex - sinP * ey + cx, y: sinP * ex + cosP * ey + cy)
        }
        func deriv(_ ct: CGFloat, _ st: CGFloat) -> CGPoint {
            let ex = -rx * st, ey = ry * ct
            return CGPoint(x: cosP * ex - sinP * ey, y: sinP * ex + cosP * ey)
        }

        for _ in 0..<segs {
            let t2 = theta + delta
            let start = point(cos(theta), sin(theta))
            let end = point(cos(t2), sin(t2))
            let d1 = deriv(cos(theta), sin(theta))
            let d2 = deriv(cos(t2), sin(t2))
            let c1 = CGPoint(x: start.x + t * d1.x, y: start.y + t * d1.y)
            let c2 = CGPoint(x: end.x - t * d2.x, y: end.y - t * d2.y)
            path.addCurve(to: end, control1: c1, control2: c2)
            theta = t2
        }
    }
}
