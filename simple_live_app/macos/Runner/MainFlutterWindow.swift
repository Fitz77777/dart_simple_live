import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // Try to restore saved frame if available
    let defaults = UserDefaults.standard
    let frameKey = "MainFlutterWindowFrame"
    if let frameString = defaults.string(forKey: frameKey) {
      let rect = NSRectFromString(frameString)
      // Only set the frame if it's not empty
      if rect.width > 0 && rect.height > 0 {
        // Ensure the restored rect intersects at least one connected screen's visible frame
        let screens = NSScreen.screens
        let intersectsScreen = screens.contains { screen in
          return screen.visibleFrame.intersects(rect)
        }
        if intersectsScreen {
          self.setFrame(rect, display: true)
        } else if let main = NSScreen.main {
          // If saved frame would be off-screen (e.g. monitor removed), center on main screen and clamp size
          let screenFrame = main.visibleFrame
          let w = min(rect.width, screenFrame.width)
          let h = min(rect.height, screenFrame.height)
          let x = screenFrame.origin.x + (screenFrame.width - w) / 2.0
          let y = screenFrame.origin.y + (screenFrame.height - h) / 2.0
          let newRect = NSRect(x: x, y: y, width: w, height: h)
          self.setFrame(newRect, display: true)
        } else {
          self.setFrame(rect, display: true)
        }
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Observe window changes to save the frame
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(windowDidMoveOrResize(_:)),
                                           name: NSWindow.didMoveNotification,
                                           object: self)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(windowDidMoveOrResize(_:)),
                                           name: NSWindow.didResizeNotification,
                                           object: self)

    // Save frame on app termination
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(saveWindowFrame),
                                           name: NSApplication.willTerminateNotification,
                                           object: nil)

    super.awakeFromNib()
  }

  @objc private func windowDidMoveOrResize(_ notification: Notification) {
    saveWindowFrame()
  }

  @objc private func saveWindowFrame() {
    let frameKey = "MainFlutterWindowFrame"
    let frameString = NSStringFromRect(self.frame)
    UserDefaults.standard.set(frameString, forKey: frameKey)
  }
}
