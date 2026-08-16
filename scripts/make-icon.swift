#!/usr/bin/env swift
// アプリアイコン(AppIcon.icns)を生成する。
// 依存を増やさずビルドを再現可能にするため、画像を外部から持ち込まず
// CoreGraphicsで描画する。
//
// 使い方: swift scripts/make-icon.swift
// 出力:   Resources/AppIcon.icns

import AppKit
import CoreGraphics
import Foundation

// Big Sur以降のアイコンは角丸四角形。小さいサイズでも潰れないよう要素を絞る。
private func drawIcon(size: CGFloat, into context: CGContext) {
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .high

    // 実寸に対して少し余白を取る（macOS標準のアイコンと並べたときに揃う）
    let inset = size * 0.055
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let cornerRadius = rect.width * 0.2237  // Big Sur のsquircle比率に近い値

    // 背景: 藍から青のグラデーション
    let background = CGPath(
        roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil
    )
    context.saveGState()
    context.addPath(background)
    context.clip()
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(colorSpace: colorSpace, components: [0.36, 0.36, 0.86, 1.0])!,
            CGColor(colorSpace: colorSpace, components: [0.16, 0.47, 0.94, 1.0])!,
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.midX, y: rect.maxY),
        end: CGPoint(x: rect.midX, y: rect.minY),
        options: []
    )
    context.restoreGState()

    // 前景: 白い南京錠。「パスワード付きzip」という用途が一目で伝わる形にする。
    // シャックル(U字)と本体はどちらも白なので、両者が重なると輪郭が溶けて
    // 錠前に見えなくなる。U字が本体の上にはっきり出る比率にしている。
    let white = CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!

    let bodyWidth = rect.width * 0.50
    let bodyHeight = rect.height * 0.31
    let bodyRect = CGRect(
        x: rect.midX - bodyWidth / 2,
        y: rect.minY + rect.height * 0.22,
        width: bodyWidth,
        height: bodyHeight
    )
    let bodyRadius = bodyHeight * 0.26

    // シャックルを先に描き、あとから本体を重ねて脚の端を隠す
    let shackleLineWidth = rect.width * 0.078
    let shackleRadius = rect.width * 0.145
    let shackleCenterY = bodyRect.maxY + rect.height * 0.115

    context.setStrokeColor(white)
    context.setLineWidth(shackleLineWidth)
    context.setLineCap(.butt)
    let shackle = CGMutablePath()
    shackle.move(to: CGPoint(x: rect.midX - shackleRadius, y: bodyRect.midY))
    shackle.addLine(to: CGPoint(x: rect.midX - shackleRadius, y: shackleCenterY))
    // π→0 を clockwise:true で回すと上半分(ドーム)になる。
    // false にすると下半分を通ってしまい、U字ではなく本体のくぼみに見える。
    shackle.addArc(
        center: CGPoint(x: rect.midX, y: shackleCenterY),
        radius: shackleRadius,
        startAngle: .pi,
        endAngle: 0,
        clockwise: true
    )
    shackle.addLine(to: CGPoint(x: rect.midX + shackleRadius, y: bodyRect.midY))
    context.addPath(shackle)
    context.strokePath()

    context.setFillColor(white)
    context.addPath(
        CGPath(
            roundedRect: bodyRect, cornerWidth: bodyRadius, cornerHeight: bodyRadius, transform: nil
        ))
    context.fillPath()

    let lockWidth = bodyWidth

    // 錠前の中央にファスナー(ジッパー)を描いて zip であることを示す。
    // 16pxでは潰れるので、一定サイズ以上のときだけ描く。
    guard size >= 64 else { return }

    let slotWidth = lockWidth * 0.1
    let slotTop = bodyRect.maxY - bodyHeight * 0.2
    let slotBottom = bodyRect.minY + bodyHeight * 0.2
    context.setStrokeColor(CGColor(colorSpace: colorSpace, components: [0.16, 0.47, 0.94, 1.0])!)
    context.setLineWidth(slotWidth)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: rect.midX, y: slotTop))
    context.addLine(to: CGPoint(x: rect.midX, y: slotBottom))
    context.strokePath()

    // ファスナーの歯
    let toothLength = lockWidth * 0.16
    let toothWidth = slotWidth * 0.62
    context.setLineWidth(toothWidth)
    context.setLineCap(.butt)
    let toothCount = 3
    let spacing = (slotTop - slotBottom) / CGFloat(toothCount + 1)
    for index in 1...toothCount {
        let y = slotBottom + spacing * CGFloat(index)
        context.move(to: CGPoint(x: rect.midX - toothLength, y: y))
        context.addLine(to: CGPoint(x: rect.midX + toothLength, y: y))
    }
    context.strokePath()
}

private func makePNG(size: Int) -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard
        let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else { fatalError("CGContextを作成できませんでした") }

    drawIcon(size: CGFloat(size), into: context)

    guard let image = context.makeImage() else { fatalError("画像を生成できませんでした") }
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("PNGに変換できませんでした")
    }
    return data
}

// MARK: - 出力

let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = repositoryRoot.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

// .iconsetが要求する名前とサイズの組み合わせ
let variants: [(name: String, size: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for variant in variants {
    let data = makePNG(size: variant.size)
    try data.write(to: iconsetURL.appendingPathComponent("\(variant.name).png"))
}

let resourcesURL = repositoryRoot.appendingPathComponent("Resources")
try? FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c", "icns", iconsetURL.path,
    "-o", resourcesURL.appendingPathComponent("AppIcon.icns").path,
]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { exit(process.terminationStatus) }

print("作成しました: Resources/AppIcon.icns")
