//
//  ViewController.swift
//  MIDITimeTableView
//
//  Created by Cem Olcay on 14.10.2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  @IBOutlet weak var measureView: MIDITimeTableMeasureView?

  override func viewDidLoad() {
    super.viewDidLoad()
    measureView?.barCount = 4
    measureView?.setNeedsLayout()
  }
}

