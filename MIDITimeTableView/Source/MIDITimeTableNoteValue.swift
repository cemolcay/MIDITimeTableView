//
//  MIDITimeTableNoteValue.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Value of note for defining its duration in rhythme.
public enum MIDITimeTableNoteValue: Int {
  /// Whole note worths a beat.
  case whole = 1
  /// Half note worths half a beat.
  case half = 2
  /// Quarter note worths quarter a beat.
  case quarter = 4
  /// Eighth note worhts one eighth of a beat.
  case eighth = 8
  /// Sixteenth note worths one sixteenth of a beat.
  case sixteenth = 16
  /// Thirtysecond note worths one thirtysecond of a beat.
  case thirtysecond = 32
  /// Sixtyfourth note worths one sixtyfourth of a beat.
  case sixtyfourth = 64
}
