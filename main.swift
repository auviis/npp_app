import Cocoa

/// Returns the absolute path of an executable by checking `which` and common locations
func findExecutable(_ name: String) -> String? {
    let which = Process()
    which.launchPath = "/usr/bin/which"
    which.arguments = [name]
    let pipe = Pipe()
    which.standardOutput = pipe
    which.launch()
    which.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
        return path
    }

    let candidates = ["/usr/local/bin/\(name)", "/opt/homebrew/bin/\(name)", "/usr/bin/\(name)"]
    for p in candidates {
        if FileManager.default.isExecutableFile(atPath: p) {
            return p
        }
    }

    return nil
}

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

        guard let wineExec = findExecutable("wine") else {
            print("Wine not found in PATH or common locations.")
            return
        }
        task.launchPath = wineExec
        let bundlePath = Bundle.main.bundlePath
        let resPath = URL(fileURLWithPath: bundlePath).appendingPathComponent("Contents/Resources/npp.8.9.portable").path
        task.currentDirectoryPath = resPath
        
        var args = ["notepad++.exe"]
        
        // Convert macOS path to Windows path if file is provided
        if let file = filePath {
            let winepath = Process()
            if let winepathExec = findExecutable("winepath") {
                winepath.launchPath = winepathExec
            } else {
                let wineDir = (task.launchPath ?? "").split(separator: "/").dropLast().joined(separator: "/")
                winepath.launchPath = wineDir.isEmpty ? "/usr/local/bin/winepath" : "\(wineDir)/winepath"
            }
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
