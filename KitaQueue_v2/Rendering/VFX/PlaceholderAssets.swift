import SpriteKit

/// Generates playtest-quality placeholder textures programmatically.
/// Every node uses SKTexture.game() which tries atlas first, falls back to generated shape.
enum PlaceholderAssets {

    nonisolated(unsafe) private static var cache: [String: SKTexture] = [:]

    static func texture(named name: String, size: CGSize, color: UIColor) -> SKTexture {
        let key = "\(name)_\(Int(size.width))x\(Int(size.height))_\(color.hashValue)"
        if let cached = cache[key] { return cached }

        let tex: SKTexture
        switch name {
        case let n where n.contains("shuriken") || n.contains("body_"):
            tex = shurikenTexture(size: size, color: color)
        case let n where n.contains("bank"):
            tex = bankTexture(size: size, color: color)
        case let n where n.contains("gate"):
            tex = gateTexture(size: size, color: color)
        case let n where n.contains("operator") || n.contains("slash"):
            tex = operatorTexture(size: size, color: color)
        case let n where n.contains("ghost"):
            tex = ghostTexture(size: size, color: color)
        case let n where n.contains("rail"):
            tex = railTexture(size: size, color: color)
        case let n where n.contains("slot_hint"):
            tex = slotHintTexture(size: size, color: color)
        case let n where n.contains("ninja"):
            tex = ninjaTexture(size: size, color: color)
        case let n where n.contains("star"):
            tex = starTexture(size: size, color: color)
        default:
            tex = roundedRectTexture(size: size, color: color, cornerRadius: 4)
        }
        cache[key] = tex
        return tex
    }

    // MARK: - Shape Generators

    private static func shurikenTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) / 2 * 0.9
            let innerR = r * 0.4

            // 4-pointed star
            let path = UIBezierPath()
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4 - .pi / 2
                let radius = i % 2 == 0 ? r : innerR
                let p = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.close()
            gc.setFillColor(color.cgColor)
            gc.addPath(path.cgPath)
            gc.fillPath()

            // Center dot
            gc.setFillColor(UIColor.white.withAlphaComponent(0.7).cgColor)
            gc.fillEllipse(in: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
        }
        return SKTexture(image: image)
    }

    private static func bankTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)

            gc.setFillColor(color.withAlphaComponent(0.3).cgColor)
            gc.addPath(path.cgPath)
            gc.fillPath()

            gc.setStrokeColor(color.cgColor)
            gc.setLineWidth(3)
            gc.addPath(path.cgPath)
            gc.strokePath()

            // Arrow pointing down into bank
            let arrowY = size.height * 0.3
            let arrowPath = UIBezierPath()
            arrowPath.move(to: CGPoint(x: size.width * 0.3, y: arrowY))
            arrowPath.addLine(to: CGPoint(x: size.width * 0.5, y: arrowY + 12))
            arrowPath.addLine(to: CGPoint(x: size.width * 0.7, y: arrowY))
            gc.setStrokeColor(color.withAlphaComponent(0.6).cgColor)
            gc.setLineWidth(2)
            gc.addPath(arrowPath.cgPath)
            gc.strokePath()
        }
        return SKTexture(image: image)
    }

    private static func gateTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            // Horizontal bar
            let barRect = CGRect(x: 2, y: size.height / 2 - 4, width: size.width - 4, height: 8)
            gc.setFillColor(UIColor.darkGray.cgColor)
            gc.fill(barRect)

            // Color indicator circle
            let dotSize: CGFloat = 12
            let dotRect = CGRect(
                x: size.width / 2 - dotSize / 2,
                y: size.height / 2 - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            gc.setFillColor(color.cgColor)
            gc.fillEllipse(in: dotRect)
        }
        return SKTexture(image: image)
    }

    private static func operatorTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            // Diagonal slash line
            gc.setStrokeColor(color.cgColor)
            gc.setLineWidth(3)
            gc.setLineCap(.round)
            gc.move(to: CGPoint(x: 4, y: size.height - 4))
            gc.addLine(to: CGPoint(x: size.width - 4, y: 4))
            gc.strokePath()

            // 3 charge pips along the slash
            let pipSize: CGFloat = 4
            for i in 0..<3 {
                let t = CGFloat(i + 1) / 4.0
                let px = 4 + (size.width - 8) * t
                let py = (size.height - 4) - (size.height - 8) * t
                gc.setFillColor(UIColor.white.cgColor)
                gc.fillEllipse(in: CGRect(x: px - pipSize / 2, y: py - pipSize / 2, width: pipSize, height: pipSize))
            }
        }
        return SKTexture(image: image)
    }

    private static func ghostTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            gc.setStrokeColor(color.withAlphaComponent(0.4).cgColor)
            gc.setLineWidth(2)
            gc.setLineCap(.round)
            gc.setLineDash(phase: 0, lengths: [4, 4])
            gc.move(to: CGPoint(x: 4, y: size.height - 4))
            gc.addLine(to: CGPoint(x: size.width - 4, y: 4))
            gc.strokePath()
        }
        return SKTexture(image: image)
    }

    private static func railTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            gc.setFillColor(color.withAlphaComponent(0.15).cgColor)
            gc.fill(CGRect(x: size.width / 2 - 1, y: 0, width: 2, height: size.height))
        }
        return SKTexture(image: image)
    }

    private static func slotHintTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            let dotSize: CGFloat = 6
            let dotRect = CGRect(
                x: size.width / 2 - dotSize / 2,
                y: size.height / 2 - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            gc.setFillColor(color.withAlphaComponent(0.12).cgColor)
            gc.fillEllipse(in: dotRect)
        }
        return SKTexture(image: image)
    }

    private static func ninjaTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            // Simple ninja silhouette
            let cx = size.width / 2
            // Head
            gc.setFillColor(color.cgColor)
            gc.fillEllipse(in: CGRect(x: cx - 10, y: size.height - 24, width: 20, height: 20))
            // Body triangle
            let bodyPath = UIBezierPath()
            bodyPath.move(to: CGPoint(x: cx, y: size.height - 28))
            bodyPath.addLine(to: CGPoint(x: cx - 16, y: size.height * 0.3))
            bodyPath.addLine(to: CGPoint(x: cx + 16, y: size.height * 0.3))
            bodyPath.close()
            gc.addPath(bodyPath.cgPath)
            gc.fillPath()
            // Eyes (white slits)
            gc.setFillColor(UIColor.white.cgColor)
            gc.fill(CGRect(x: cx - 7, y: size.height - 16, width: 5, height: 2))
            gc.fill(CGRect(x: cx + 2, y: size.height - 16, width: 5, height: 2))
        }
        return SKTexture(image: image)
    }

    private static func starTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerR = min(size.width, size.height) / 2 * 0.9
            let innerR = outerR * 0.38

            let path = UIBezierPath()
            for i in 0..<10 {
                let angle = CGFloat(i) * .pi / 5 - .pi / 2
                let r = i % 2 == 0 ? outerR : innerR
                let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.close()
            gc.setFillColor(color.cgColor)
            gc.addPath(path.cgPath)
            gc.fillPath()
        }
        return SKTexture(image: image)
    }

    private static func roundedRectTexture(size: CGSize, color: UIColor, cornerRadius: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
            color.setFill()
            path.fill()
        }
        return SKTexture(image: image)
    }
}

// MARK: - SKTexture Convenience

extension SKTexture {
    /// Try atlas first, fall back to placeholder.
    static func game(_ name: String, size: CGSize, fallbackColor: UIColor) -> SKTexture {
        #if DEBUG
        return PlaceholderAssets.texture(named: name, size: size, color: fallbackColor)
        #else
        // In release, we'd load from atlas. For now, same as debug.
        return PlaceholderAssets.texture(named: name, size: size, color: fallbackColor)
        #endif
    }
}
