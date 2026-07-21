//
//  MIDITimeTableTimeSignature.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Defines time signature with number of beats and their note value in a measure.
public struct MIDITimeTableTimeSignature {
  /// Number of beats in a measure.
  public var beats: Int
  /// Note value of each beat.
  public var noteValue: MIDITimeTableNoteValue

  /// Initilizes time signature with number of beats and note value of each beat.
  ///
  /// - Parameters:
  ///   - beats: Number of beats in a measure.
  ///   - noteValue: Note value of each beat.
  public init(beats: Int, noteValue: MIDITimeTableNoteValue) {
    self.beats = beats
    self.noteValue = noteValue
  }
}
