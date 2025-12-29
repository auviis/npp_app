import Cocoa

/// AppDelegate handles macOS application events for Notepad++ Wine wrapper
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// Called when app launches without opening a file (double-click on app icon)
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Launch Notepad++ without a file when app is opened directly
        launchNotepad(with: nil)
    }
    
    /// Called when a file is opened via "Open With" or drag-and-drop
    /// - Parameters:
    ///   - sender: The NSApplication instance
    ///   - filename: Full POSIX path to the file being opened
    /// - Returns: true if the file was handled successfully
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        launchNotepad(with: filename)
        return true
    }
    
    /// Launches Notepad++ via Wine with optional file path
    /// - Parameter filePath: Optional macOS file path to open in Notepad++
    func launchNotepad(with filePath: String? = nil) {
        let task = Process() 
        task.launchPath = "/usr/local/bin/wine"
        let bundlePath = Bundle.main.bundlePath
        let resPath = URL(fileURLWithPath: bundlePath).appendingPathComponent("Contents/Resources/npp.8.9.portable").path
        task.currentDirectoryPath = resPath
        
        var args = ["notepad++.exe"]
        
        // Convert macOS path to Windows path if file is provided
        if let file = filePath {
            let winepath = Process()
            winepath.launchPath = "/usr/local/bin/winepath"
            winepath.arguments = ["-w", file]
            
            let pipe = Pipe()
            winepath.standardOutput = pipe
            winepath.launch()
            winepath.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let winPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                args.append(winPath)
            }
        }
        
        task.arguments = args
        task.launch()
        
        // Terminate the wrapper app after a short delay
        // Wine/Notepad++ will continue running independently
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }
}

// Application entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
