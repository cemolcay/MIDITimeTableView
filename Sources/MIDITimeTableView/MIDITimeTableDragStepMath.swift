//
//  MIDITimeTableDragStepMath.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 21.07.2026.
//  Copyright © 2026 cemolcay. All rights reserved.
//

import CoreGraphics

/// Pure step-quantization math shared by cell moving, cell resizing and playhead/rangehead
/// dragging. Given a pan gesture's accumulated translation, computes how many whole grid steps
/// to advance right now — catching up fully instead of a single step per callback, which is what
/// used to make dragged views trail behind the touch on fast gestures — while clamping the result
/// to the headroom available in each direction so the dragged view(s) never overshoot the table.
enum MIDITimeTableDragStepMath {
  /// Computes the number of whole `stepSize` units to advance for a given pan `translation`.
  ///
  /// - Parameters:
  ///   - translation: The pan gesture's current translation along the axis being quantized.
  ///   - stepSize: The size of one grid step along that axis. Must be greater than zero.
  ///   - maxForwardSteps: Steps of headroom available in the positive direction (>= 0).
  ///   - maxBackwardSteps: Steps of headroom available in the negative direction (>= 0).
  /// - Returns: The (possibly clamped) whole number of steps to advance. Positive moves forward,
  ///   negative moves backward, zero means the translation hasn't accumulated a full step yet.
  static func steps(translation: CGFloat, stepSize: CGFloat, maxForwardSteps: Int, maxBackwardSteps: Int) -> Int {
    guard stepSize > 0 else { return 0 }
    var steps = Int((translation / stepSize).rounded(.towardZero))
    if steps > 0 {
      steps = min(steps, max(maxForwardSteps, 0))
    } else if steps < 0 {
      steps = max(steps, -max(maxBackwardSteps, 0))
    }
    return steps
  }
}
