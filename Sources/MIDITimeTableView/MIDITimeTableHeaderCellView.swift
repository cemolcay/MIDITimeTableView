//
//  MIDITimeTableHeaderCellView.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 16.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

/// Base class to header cell in each row of `MIDITimeTableView`.
open class MIDITimeTableHeaderCellView: UIView {
  /// Reuse identifier used by `MIDITimeTableView` when pooling header views.
  public private(set) var reuseIdentifier: String?

  public init(reuseIdentifier: String? = nil) {
    self.reuseIdentifier = reuseIdentifier
    super.init(frame: .zero)
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// Called before a header view is returned from the reuse pool.
  open func prepareForReuse() {}
}
