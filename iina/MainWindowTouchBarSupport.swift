//
//  MainWindowTouchBarSupport.swift
//  iina
//
//  Created by lhc on 16/5/2017.
//  Copyright © 2017 lhc. All rights reserved.
//

import Cocoa

// MARK: - Touch bar

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBar.CustomizationIdentifier {

  static let windowBar = NSTouchBar.CustomizationIdentifier("\(Bundle.main.bundleIdentifier!).windowTouchBar")

}

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBarItem.Identifier {

  static let playPause = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.playPause")
  static let slider = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.slider")
  static let volumeUp = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.voUp")
  static let volumeDown = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.voDn")
  static let rewind = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.rewind")
  static let fastForward = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.forward")
  static let time = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.time")
  static let ahead15Sec = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.ahead15Sec")
  static let back15Sec = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.back15Sec")
  static let ahead30Sec = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.ahead30Sec")
  static let back30Sec = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.back30Sec")
  static let next = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.next")
  static let prev = NSTouchBarItem.Identifier("\(Bundle.main.bundleIdentifier!).TouchBarItem.prev")

}

// Image name, tag, custom label
@available(OSX 10.12.2, *)
fileprivate let touchBarItemBinding: [NSTouchBarItem.Identifier: (NSImage.Name, Int, String)] = [
  .ahead15Sec: (.touchBarSkipAhead15SecondsTemplate, 15, "15sec Ahead"),
  .ahead30Sec: (.touchBarSkipAhead30SecondsTemplate, 30, "30sec Ahead"),
  .back15Sec: (.touchBarSkipBack15SecondsTemplate, -15, "-15sec Ahead"),
  .back30Sec: (.touchBarSkipBack30SecondsTemplate, -30, "-30sec Ahead"),
  .next: (.touchBarSkipAheadTemplate, 0, "Next video"),
  .prev: (.touchBarSkipBackTemplate, 1, "Previous video"),
  .volumeUp: (.touchBarVolumeUpTemplate, 0, "Volume +"),
  .volumeDown: (.touchBarVolumeDownTemplate, 1, "Volume -"),
  .rewind: (.touchBarRewindTemplate, 0, "Rewind"),
  .fastForward: (.touchBarFastForwardTemplate, 1, "Fast forward")
]

@available(OSX 10.12.2, *)
extension MainWindowController: NSTouchBarDelegate {

  override func makeTouchBar() -> NSTouchBar? {
    let touchBar = NSTouchBar()
    touchBar.delegate = self
    touchBar.customizationIdentifier = .windowBar
    touchBar.defaultItemIdentifiers = [.playPause, .slider, .time]
    touchBar.customizationAllowedItemIdentifiers = [.playPause, .slider, .volumeUp, .volumeDown, .rewind, .fastForward, .time, .ahead15Sec, .ahead30Sec, .back15Sec, .back30Sec, .next, .prev, .fixedSpaceLarge]
    return touchBar
  }

  func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {

    switch identifier {

    case .playPause:
      let item = NSCustomTouchBarItem(identifier: identifier)
      item.view = NSButton(image: NSImage(named: .touchBarPauseTemplate)!, target: self, action: #selector(self.touchBarPlayBtnAction(_:)))
      item.customizationLabel = "Play / Pause"
      self.touchBarPlayPauseBtn = item.view as? NSButton
      return item

    case .slider:
      let item = NSSliderTouchBarItem(identifier: identifier)
      item.slider = TouchBarPlaySlider()
      item.slider.cell = TouchBarPlaySliderCell()
      item.slider.minValue = 0
      item.slider.maxValue = 100
      item.slider.target = self
      item.slider.action = #selector(self.touchBarSliderAction(_:))
      item.customizationLabel = "Seek"
      self.touchBarPlaySlider = item.slider as? TouchBarPlaySlider
      return item

    case .volumeUp,
         .volumeDown:
      guard let data = touchBarItemBinding[identifier] else { return nil }
      return buttonTouchBarItem(withIdentifier: identifier, imageName: data.0, tag: data.1, customLabel: data.2, action: #selector(self.touchBarVolumeAction(_:)))

    case .rewind,
         .fastForward:
      guard let data = touchBarItemBinding[identifier] else { return nil }
      return buttonTouchBarItem(withIdentifier: identifier, imageName: data.0, tag: data.1, customLabel: data.2, action: #selector(self.touchBarRewindAction(_:)))

    case .time:
      let item = NSCustomTouchBarItem(identifier: identifier)
      let label = DurationDisplayTextField(labelWithString: "00:00")
      label.alignment = .center
      label.mode = ud.bool(forKey: Preference.Key.showRemainingTime) ? .remaining : .current
      self.touchBarCurrentPosLabel = label
      item.view = label
      item.customizationLabel = "Time Position"
      return item

    case .ahead15Sec,
         .back15Sec,
         .ahead30Sec,
         .back30Sec:
      guard let data = touchBarItemBinding[identifier] else { return nil }
      return buttonTouchBarItem(withIdentifier: identifier, imageName: data.0, tag: data.1, customLabel: data.2, action: #selector(self.touchBarSeekAction(_:)))

    case .next,
         .prev:
      guard let data = touchBarItemBinding[identifier] else { return nil }
      return buttonTouchBarItem(withIdentifier: identifier, imageName: data.0, tag: data.1, customLabel: data.2, action: #selector(self.touchBarSkipAction(_:)))

    default:
      return nil
    }
  }

  func updateTouchBarPlayBtn() {
    if playerCore.info.isPaused {
      touchBarPlayPauseBtn?.image = NSImage(named: .touchBarPlayTemplate)
    } else {
      touchBarPlayPauseBtn?.image = NSImage(named: .touchBarPauseTemplate)
    }
  }

  func touchBarPlayBtnAction(_ sender: NSButton) {
    playerCore.togglePause(nil)
  }

  func touchBarVolumeAction(_ sender: NSButton) {
    let currVolume = playerCore.info.volume
    playerCore.setVolume(currVolume + (sender.tag == 0 ? 5 : -5))
  }

  func touchBarRewindAction(_ sender: NSButton) {
    arrowButtonAction(left: sender.tag == 0)
  }

  func touchBarSeekAction(_ sender: NSButton) {
    let sec = sender.tag
    playerCore.seek(relativeSecond: Double(sec), option: .relative)
  }

  func touchBarSkipAction(_ sender: NSButton) {
    playerCore.navigateInPlaylist(nextOrPrev: sender.tag == 0)
  }

  func touchBarSliderAction(_ sender: NSSlider) {
    let percentage = 100 * sender.doubleValue / sender.maxValue
    playerCore.seek(percent: percentage)
  }

  private func buttonTouchBarItem(withIdentifier identifier: NSTouchBarItem.Identifier, imageName: NSImage.Name, tag: Int, customLabel: String, action: Selector) -> NSCustomTouchBarItem {
    let item = NSCustomTouchBarItem(identifier: identifier)
    let button = NSButton(image: NSImage(named: imageName)!, target: self, action: action)
    button.tag = tag
    item.view = button
    item.customizationLabel = customLabel
    return item
  }

  // Set TouchBar Time Label

  func setupTouchBarUI() {
    guard let duration = playerCore.info.videoDuration else {
      Utility.fatal("video info not available")
    }

    let pad: CGFloat = 16.0
    sizingTouchBarTextField.stringValue = duration.stringRepresentation
    if let widthConstant = sizingTouchBarTextField.cell?.cellSize.width, let posLabel = touchBarCurrentPosLabel {
      if let posConstraint = touchBarPosLabelWidthLayout {
        posConstraint.constant = widthConstant + pad
        posLabel.setNeedsDisplay()
      } else {
        let posConstraint = NSLayoutConstraint(item: posLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: widthConstant + pad)
        posLabel.addConstraint(posConstraint)
        touchBarPosLabelWidthLayout = posConstraint
      }
    }
    
  }
}

// MARK: - Slider

class TouchBarPlaySlider: NSSlider {

  var isTouching = false

  override func touchesBegan(with event: NSEvent) {
    isTouching = true
    super.touchesBegan(with: event)
  }

  override func touchesEnded(with event: NSEvent) {
    isTouching = false
    super.touchesEnded(with: event)
  }

  func setDoubleValueSafely(_ value: Double) {
    guard !isTouching else { return }
    doubleValue = value
  }

}


class TouchBarPlaySliderCell: NSSliderCell {

  private let gradient = NSGradient(starting: NSColor(calibratedRed: 0.471, green: 0.8, blue: 0.929, alpha: 1),
                            ending: NSColor(calibratedRed: 0.784, green: 0.471, blue: 0.929, alpha: 1))
  private let solidColor = NSColor.labelColor.withAlphaComponent(0.4)

  var isTouching: Bool {
    return (self.controlView as? TouchBarPlaySlider)?.isTouching ?? false
  }

  override var knobThickness: CGFloat {
    return 4
  }

  override func barRect(flipped: Bool) -> NSRect {
    let rect = super.barRect(flipped: flipped)
    return NSRect(x: rect.origin.x,
                  y: 6,
                  width: rect.width,
                  height: self.controlView!.frame.height - 12)
  }

  override func knobRect(flipped: Bool) -> NSRect {
    let superKnob = super.knobRect(flipped: flipped)
    if isTouching {
      return superKnob
    } else {
      let remainingKnobWidth = superKnob.width - knobThickness
      return NSRect(x: superKnob.origin.x + remainingKnobWidth * CGFloat(doubleValue/100),
                    y: superKnob.origin.y,
                    width: knobThickness,
                    height: superKnob.height)
    }
  }

  override func drawKnob(_ knobRect: NSRect) {
    NSColor.labelColor.setFill()
    let path = NSBezierPath(roundedRect: knobRect, xRadius: 2, yRadius: 2)
    path.fill()
  }

  override func drawBar(inside rect: NSRect, flipped: Bool) {
    let barRect = self.barRect(flipped: flipped)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: barRect, xRadius: 2.5, yRadius: 2.5).setClip()
    let step: CGFloat = 2
    let mid = barRect.origin.x + barRect.width * CGFloat(doubleValue/100)
    let end = barRect.origin.x + barRect.width
    var i: CGFloat = barRect.origin.x
    var j: CGFloat = 0
    while (i < mid) {
      let rect = NSRect(x: i, y: barRect.origin.y, width: 1, height: barRect.height)
      gradient?.interpolatedColor(atLocation: CGFloat(j / barRect.width)).setFill()
      NSBezierPath(rect: rect).fill()
      i += step
      j += step
    }
    while (i < end) {
      let rect = NSRect(x: i, y: barRect.origin.y, width: 1, height: barRect.height)
      solidColor.setFill()
      NSBezierPath(rect: rect).fill()
      i += step
      j += step
    }
    NSGraphicsContext.restoreGraphicsState()
  }

}
