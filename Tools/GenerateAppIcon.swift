#!/usr/bin/env swift

// Generates UltraTrain's 1024×1024 App Icon (Direction A — Midnight Glass).
//
// Layers (bottom → top):
//   1. Vertical gradient    #0F1F3E → #0A1530 → #050A18
//   2. Top sheen            white 8% → 0% across the top 18%
//   3. Radial cyan glow     #4DBDFF 15% center → 0% at edge
//   4. Runner glyph         reuses LaunchIcon-dark@3x.png in pure white
//
// Run:   swift Tools/GenerateAppIcon.swift
// Out:   UltraTrain/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png

import AppKit
import CoreGraphics
import Foundation

// MARK: - Paths

let repoRoot: URL = {
    let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
    return scriptPath
        .deletingLastPathComponent()       // Tools/
        .deletingLastPathComponent()       // repo root
}()

let runnerSourceURL = repoRoot
    .appendingPathComponent("UltraTrain/Resources/Assets.xcassets/LaunchIcon.imageset/LaunchIcon-dark@3x.png")

let outputURL = repoRoot
    .appendingPathComponent("UltraTrain/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

// MARK: - Helpers

func srgbColor(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1.0) -> CGColor {
    CGColor(srgbRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
}

func srgbHex(_ rrggbb: UInt32, _ a: Double = 1.0) -> CGColor {
    let r = Double((rrggbb >> 16) & 0xFF) / 255.0
    let g = Double((rrggbb >> 8) & 0xFF) / 255.0
    let b = Double(rrggbb & 0xFF) / 255.0
    return srgbColor(r, g, b, a)
}

// MARK: - Canvas

let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Failed to create CGContext\n", stderr)
    exit(1)
}

let rect = CGRect(x: 0, y: 0, width: size, height: size)
let w = CGFloat(size)
let h = CGFloat(size)

// MARK: - 1. Background gradient

let bgGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        srgbHex(0x0F1F3E),
        srgbHex(0x0A1530),
        srgbHex(0x050A18)
    ] as CFArray,
    locations: [0.0, 0.55, 1.0]
)!
// Core Graphics is bottom-left origin, so "top" = high Y.
ctx.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 0, y: h),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// MARK: - 2. Top-center spotlight (white 4% → 0%, radial)
// Reads as light catching glass from above — adds depth without a flat
// linear-gradient look.

ctx.saveGState()
let spotCenter = CGPoint(x: w * 0.5, y: h * 0.95)
let spotRadius: CGFloat = w * 0.70
let spotGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        srgbColor(1, 1, 1, 0.04),
        srgbColor(1, 1, 1, 0.0)
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.setBlendMode(.screen)
ctx.drawRadialGradient(
    spotGradient,
    startCenter: spotCenter, startRadius: 0,
    endCenter: spotCenter, endRadius: spotRadius,
    options: []
)
ctx.restoreGState()

// MARK: - 3. Radial cyan glow under runner

ctx.saveGState()
// Centered horizontally, slightly below center vertically — sits beneath the runner.
let glowCenter = CGPoint(x: w * 0.5, y: h * 0.48)
let glowRadius: CGFloat = w * 0.40
let glowGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        srgbHex(0x4DBDFF, 0.18),
        srgbHex(0x4DBDFF, 0.0)
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.setBlendMode(.screen)
ctx.drawRadialGradient(
    glowGradient,
    startCenter: glowCenter, startRadius: 0,
    endCenter: glowCenter, endRadius: glowRadius,
    options: []
)
ctx.restoreGState()

// MARK: - 4. Runner glyph

guard let runnerData = try? Data(contentsOf: runnerSourceURL),
      let runnerImgSource = CGImageSourceCreateWithData(runnerData as CFData, nil),
      let runnerImage = CGImageSourceCreateImageAtIndex(runnerImgSource, 0, nil) else {
    fputs("Failed to load runner source at \(runnerSourceURL.path)\n", stderr)
    exit(1)
}

// Source is 600×600 white runner on transparent.
// Target footprint: ~64% of canvas. Centered.
let runnerBox: CGFloat = w * 0.64
let runnerRect = CGRect(
    x: (w - runnerBox) / 2,
    y: (h - runnerBox) / 2,
    width: runnerBox,
    height: runnerBox
)
ctx.interpolationQuality = .high
ctx.draw(runnerImage, in: runnerRect)

// MARK: - Encode PNG

guard let cgOutput = ctx.makeImage() else {
    fputs("Failed to produce CGImage\n", stderr)
    exit(1)
}
let nsImage = NSBitmapImageRep(cgImage: cgOutput)
guard let png = nsImage.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

do {
    try png.write(to: outputURL)
    print("Wrote \(outputURL.path) (\(png.count) bytes)")
} catch {
    fputs("Failed to write output: \(error)\n", stderr)
    exit(1)
}
