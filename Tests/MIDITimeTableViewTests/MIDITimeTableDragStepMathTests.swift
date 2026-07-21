//
//  MIDITimeTableDragStepMathTests.swift
//  MIDITimeTableViewTests
//

import XCTest
@testable import MIDITimeTableView

final class MIDITimeTableDragStepMathTests: XCTestCase {

  func testCatchesUpMultipleStepsInOneCallback() {
    // A single fast pan callback covering 3.7 steps should advance a full 3 steps at once,
    // instead of the old one-step-per-callback behavior that caused a visible lag.
    let steps = MIDITimeTableDragStepMath.steps(translation: 37, stepSize: 10, maxForwardSteps: 100, maxBackwardSteps: 100)
    XCTAssertEqual(steps, 3)
  }

  func testCatchesUpMultipleStepsBackwards() {
    let steps = MIDITimeTableDragStepMath.steps(translation: -37, stepSize: 10, maxForwardSteps: 100, maxBackwardSteps: 100)
    XCTAssertEqual(steps, -3)
  }

  func testSubStepTranslationProducesNoStepYet() {
    // Translation hasn't accumulated a full step; the remainder should be left for next time
    // (the view itself keeps it via `setTranslation`), not rounded up or discarded.
    let steps = MIDITimeTableDragStepMath.steps(translation: 9, stepSize: 10, maxForwardSteps: 100, maxBackwardSteps: 100)
    XCTAssertEqual(steps, 0)
  }

  func testClampedByForwardHeadroom() {
    let steps = MIDITimeTableDragStepMath.steps(translation: 100, stepSize: 10, maxForwardSteps: 3, maxBackwardSteps: 100)
    XCTAssertEqual(steps, 3)
  }

  func testClampedByBackwardHeadroom() {
    let steps = MIDITimeTableDragStepMath.steps(translation: -100, stepSize: 10, maxForwardSteps: 100, maxBackwardSteps: 2)
    XCTAssertEqual(steps, -2)
  }

  func testNoHeadroomProducesNoMovement() {
    let forward = MIDITimeTableDragStepMath.steps(translation: 100, stepSize: 10, maxForwardSteps: 0, maxBackwardSteps: 100)
    let backward = MIDITimeTableDragStepMath.steps(translation: -100, stepSize: 10, maxForwardSteps: 100, maxBackwardSteps: 0)
    XCTAssertEqual(forward, 0)
    XCTAssertEqual(backward, 0)
  }

  func testZeroStepSizeReturnsZero() {
    let steps = MIDITimeTableDragStepMath.steps(translation: 100, stepSize: 0, maxForwardSteps: 10, maxBackwardSteps: 10)
    XCTAssertEqual(steps, 0)
  }
}
