#!/usr/bin/env swift
//
// TrainFinishTimeModel.swift
// Generates synthetic training data and trains a CoreML model for finish time prediction.
//
// Usage: swift Scripts/TrainFinishTimeModel.swift
// Requires: macOS 14+ with Xcode command line tools (CreateML framework)
//
// Output: UltraTrain/Resources/FinishTimePredictor.mlmodel

import Foundation
import CreateML
import TabularData

// MARK: - Algorithmic Model (replicates FinishTimeMLService regression)

func experienceMultiplier(for level: Int) -> Double {
    switch level {
    case 0: return 1.15   // beginner
    case 1: return 1.0    // intermediate
    case 2: return 0.92   // advanced
    case 3: return 0.85   // elite
    default: return 1.0
    }
}

func computeFitnessAdjustment(ctl: Double, tsb: Double) -> Double {
    let ctlEffect = ctl * 0.001
    let tsbEffect: Double
    if tsb < 0 {
        tsbEffect = abs(tsb) * 0.002
    } else {
        tsbEffect = -tsb * 0.001
    }
    return max(0.80, min(1.20, 1.0 - ctlEffect + tsbEffect))
}

func computeTerrainAdjustment(terrainDifficulty: Double, elevationPerKm: Double) -> Double {
    let difficultyEffect = 1.0 + (terrainDifficulty - 1.0) * 0.1
    let elevationEffect = 1.0 + max(0, elevationPerKm - 30) * 0.002
    return difficultyEffect * elevationEffect
}

func predict(
    effectiveDistanceKm: Double,
    experienceLevel: Int,
    avgPaceSecondsPerKm: Double,
    ctl: Double,
    tsb: Double,
    terrainDifficulty: Double,
    elevationPerKm: Double,
    calibrationFactor: Double
) -> Double {
    let expMult = experienceMultiplier(for: experienceLevel)
    let basePrediction = effectiveDistanceKm * avgPaceSecondsPerKm * expMult
    let fitnessAdj = computeFitnessAdjustment(ctl: ctl, tsb: tsb)
    let terrainAdj = computeTerrainAdjustment(
        terrainDifficulty: terrainDifficulty,
        elevationPerKm: elevationPerKm
    )
    return max(0, basePrediction * fitnessAdj * terrainAdj * calibrationFactor)
}

// MARK: - Generate Synthetic Training Data

print("Generating 10,000 synthetic training samples...")

var effectiveDistances: [Double] = []
var experienceLevels: [Double] = []
var avgPaces: [Double] = []
var ctls: [Double] = []
var tsbs: [Double] = []
var terrainDifficulties: [Double] = []
var elevationPerKms: [Double] = []
var calibrationFactors: [Double] = []
var predictedTimes: [Double] = []

for _ in 0..<10000 {
    let distance = Double.random(in: 20...170)
    let elevGain = Double.random(in: 500...12000)
    let effectiveKm = distance + elevGain / 100.0
    let experience = Int.random(in: 0...3)
    let pace = Double.random(in: 300...900)
    let ctl = Double.random(in: 0...120)
    let tsb = Double.random(in: -30...30)
    let terrain = Double.random(in: 1.0...4.0)
    let elevPerKm = elevGain / max(distance, 1)
    let calibration = Double.random(in: 0.85...1.15)

    let predicted = predict(
        effectiveDistanceKm: effectiveKm,
        experienceLevel: experience,
        avgPaceSecondsPerKm: pace,
        ctl: ctl,
        tsb: tsb,
        terrainDifficulty: terrain,
        elevationPerKm: elevPerKm,
        calibrationFactor: calibration
    )

    // Add 5% noise to simulate real-world variance
    let noise = predicted * Double.random(in: -0.05...0.05)
    let noisyTime = max(0, predicted + noise)

    effectiveDistances.append(effectiveKm)
    experienceLevels.append(Double(experience))
    avgPaces.append(pace)
    ctls.append(ctl)
    tsbs.append(tsb)
    terrainDifficulties.append(terrain)
    elevationPerKms.append(elevPerKm)
    calibrationFactors.append(calibration)
    predictedTimes.append(noisyTime)
}

// MARK: - Build DataFrame

print("Building DataFrame...")

var dataFrame = DataFrame()
dataFrame.append(column: Column(name: "effectiveDistanceKm", contents: effectiveDistances))
dataFrame.append(column: Column(name: "experienceLevel", contents: experienceLevels))
dataFrame.append(column: Column(name: "avgPaceSecondsPerKm", contents: avgPaces))
dataFrame.append(column: Column(name: "ctl", contents: ctls))
dataFrame.append(column: Column(name: "tsb", contents: tsbs))
dataFrame.append(column: Column(name: "terrainDifficulty", contents: terrainDifficulties))
dataFrame.append(column: Column(name: "elevationPerKm", contents: elevationPerKms))
dataFrame.append(column: Column(name: "calibrationFactor", contents: calibrationFactors))
dataFrame.append(column: Column(name: "predictedTimeSeconds", contents: predictedTimes))

print("DataFrame shape: \(dataFrame.rows.count) rows x \(dataFrame.columns.count) columns")

// MARK: - Train/Test Split

let (trainSlice, testSlice) = dataFrame.randomSplit(by: 0.8)
let trainDF = DataFrame(trainSlice)
let testDF = DataFrame(testSlice)
print("Training set: \(trainDF.rows.count) rows, Test set: \(testDF.rows.count) rows")

// MARK: - Train Model

print("Training MLBoostedTreeRegressor (maxDepth: 6, maxIterations: 200)...")

do {
    let regressor = try MLBoostedTreeRegressor(
        trainingData: trainDF,
        targetColumn: "predictedTimeSeconds",
        parameters: MLBoostedTreeRegressor.ModelParameters(
            maxDepth: 6,
            maxIterations: 200
        )
    )

    // Evaluate
    let evaluation = regressor.evaluation(on: testDF)
    print("\n--- Model Evaluation ---")
    print("RMSE: \(evaluation.rootMeanSquaredError)")
    print("Max Error: \(evaluation.maximumError)")

    // Export
    let metadata = MLModelMetadata(
        author: "UltraTrain",
        shortDescription: "Predicts ultra trail finish time in seconds from distance, pace, fitness, and terrain features",
        version: "1.0.0"
    )

    let outputDir = "UltraTrain/Resources"
    let outputPath = URL(fileURLWithPath: outputDir)
        .appendingPathComponent("FinishTimePredictor.mlmodel")

    try regressor.write(to: outputPath, metadata: metadata)
    print("\nModel saved to: \(outputPath.path)")
    print("Done! Add this file to the Xcode project and rebuild.")

} catch {
    print("ERROR: Failed to train model: \(error)")
    exit(1)
}
