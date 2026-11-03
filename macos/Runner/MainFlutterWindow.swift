import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    var frame = self.frame
    frame.size = NSSize(width: 1440, height: 860)
    self.setFrame(frame, display: true)
    self.minSize = NSSize(width: 1024, height: 700)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
