import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.delegate = self

    super.awakeFromNib()
  }
}

extension MainFlutterWindow: NSWindowDelegate {
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    self.miniaturize(nil)
    return false
  }
}
