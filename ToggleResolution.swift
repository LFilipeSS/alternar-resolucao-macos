import AppKit
import CoreGraphics

private struct DisplayMode: Hashable {
    let width: Int
    let height: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let refreshRate: Double
    let modeID: Int32

    var key: String {
        "\(width)x\(height)|\(pixelWidth)x\(pixelHeight)|\(String(format: "%.2f", refreshRate))"
    }

    var title: String {
        let hz = refreshRate.rounded() == refreshRate
            ? String(format: "%.0f Hz", refreshRate)
            : String(format: "%.2f Hz", refreshRate)
        let scale = (width != pixelWidth || height != pixelHeight)
            ? " · HiDPI \(pixelWidth)×\(pixelHeight)"
            : ""
        return "\(width)×\(height) · \(hz)\(scale)"
    }
}

final class ResolutionMenuApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let favoritesKey = "favoriteDisplayModes"
    private let launchAgentPath = NSString(string: "~/Library/LaunchAgents/br.com.luizfilipe.alternar-resolucao.plist").expandingTildeInPath
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var modesByKey: [String: DisplayMode] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Resoluções do Odyssey")
        button.image?.isTemplate = true
        button.toolTip = "Resoluções do Odyssey"
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func findOdyssey() -> CGDirectDisplayID? {
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(UInt32(displays.count), &displays, &count) == .success else { return nil }
        return displays.prefix(Int(count)).first { CGDisplayPixelsWide($0) >= 1920 }
    }

    private func availableModes(for display: CGDirectDisplayID) -> [DisplayMode] {
        guard let rawModes = CGDisplayCopyAllDisplayModes(display, nil) as? [CGDisplayMode] else { return [] }
        var unique: [String: DisplayMode] = [:]
        for raw in rawModes where raw.refreshRate > 0 {
            let mode = DisplayMode(
                width: raw.width,
                height: raw.height,
                pixelWidth: raw.pixelWidth,
                pixelHeight: raw.pixelHeight,
                refreshRate: raw.refreshRate,
                modeID: raw.ioDisplayModeID
            )
            if let existing = unique[mode.key] {
                if mode.modeID < existing.modeID { unique[mode.key] = mode }
            } else {
                unique[mode.key] = mode
            }
        }
        return unique.values.sorted {
            let area0 = $0.width * $0.height
            let area1 = $1.width * $1.height
            if area0 != area1 { return area0 > area1 }
            if $0.width != $1.width { return $0.width > $1.width }
            if $0.refreshRate != $1.refreshRate { return $0.refreshRate > $1.refreshRate }
            return $0.pixelWidth > $1.pixelWidth
        }
    }

    private func favoriteKeys() -> [String] {
        UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }

    private func saveFavoriteKeys(_ keys: [String]) {
        UserDefaults.standard.set(keys, forKey: favoritesKey)
    }

    private func rebuildMenu() {
        menu.removeAllItems()
        guard let display = findOdyssey(), let current = CGDisplayCopyDisplayMode(display) else {
            let unavailable = NSMenuItem(title: "Odyssey não encontrado", action: nil, keyEquivalent: "")
            unavailable.isEnabled = false
            menu.addItem(unavailable)
            addFooter()
            return
        }

        let modes = availableModes(for: display)
        modesByKey = Dictionary(uniqueKeysWithValues: modes.map { ($0.key, $0) })
        let validFavorites = favoriteKeys().filter { modesByKey[$0] != nil }
        if validFavorites != favoriteKeys() { saveFavoriteKeys(validFavorites) }

        let currentInfo = NSMenuItem(
            title: "Atual: \(current.width)×\(current.height) · \(formatHz(current.refreshRate))",
            action: nil,
            keyEquivalent: ""
        )
        currentInfo.isEnabled = false
        menu.addItem(currentInfo)

        if !validFavorites.isEmpty {
            menu.addItem(.separator())
            let heading = NSMenuItem(title: "Favoritas", action: nil, keyEquivalent: "")
            heading.isEnabled = false
            menu.addItem(heading)
            for key in validFavorites {
                if let mode = modesByKey[key] { menu.addItem(modeItem(mode, current: current)) }
            }
        }

        menu.addItem(.separator())
        let allItem = NSMenuItem(title: "Todas as resoluções", action: nil, keyEquivalent: "")
        let allMenu = NSMenu()
        for mode in modes { allMenu.addItem(modeItem(mode, current: current)) }
        allItem.submenu = allMenu
        menu.addItem(allItem)

        let favoritesItem = NSMenuItem(title: "Gerenciar favoritos", action: nil, keyEquivalent: "")
        let favoritesMenu = NSMenu()
        let favoriteSet = Set(validFavorites)
        for mode in modes {
            let item = NSMenuItem(title: mode.title, action: #selector(toggleFavorite(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.key
            item.state = favoriteSet.contains(mode.key) ? .on : .off
            favoritesMenu.addItem(item)
        }
        favoritesItem.submenu = favoritesMenu
        menu.addItem(favoritesItem)
        addFooter()
    }

    private func modeItem(_ mode: DisplayMode, current: CGDisplayMode) -> NSMenuItem {
        let item = NSMenuItem(title: mode.title, action: #selector(applyMode(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = mode.key
        if mode.width == current.width && mode.height == current.height &&
            mode.pixelWidth == current.pixelWidth && mode.pixelHeight == current.pixelHeight &&
            abs(mode.refreshRate - current.refreshRate) < 0.01 {
            item.state = .on
        }
        return item
    }

    private func addFooter() {
        menu.addItem(.separator())
        let autoLaunch = NSMenuItem(
            title: "Iniciar automaticamente com o macOS",
            action: #selector(toggleAutoLaunch(_:)),
            keyEquivalent: ""
        )
        autoLaunch.target = self
        autoLaunch.state = FileManager.default.fileExists(atPath: launchAgentPath) ? .on : .off
        menu.addItem(autoLaunch)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Encerrar", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func formatHz(_ value: Double) -> String {
        value.rounded() == value ? String(format: "%.0f Hz", value) : String(format: "%.2f Hz", value)
    }

    @objc private func applyMode(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String,
              let selected = modesByKey[key],
              let display = findOdyssey(),
              let rawModes = CGDisplayCopyAllDisplayModes(display, nil) as? [CGDisplayMode],
              let raw = rawModes.first(where: { $0.ioDisplayModeID == selected.modeID }) else {
            showError("A resolução escolhida não está mais disponível.")
            return
        }
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else {
            showError("Não foi possível iniciar a alteração do monitor.")
            return
        }
        guard CGConfigureDisplayWithDisplayMode(config, display, raw, nil) == .success else {
            CGCancelDisplayConfiguration(config)
            showError("O monitor recusou a resolução escolhida.")
            return
        }
        if CGCompleteDisplayConfiguration(config, .permanently) != .success {
            showError("O macOS não conseguiu salvar a resolução.")
        }
    }

    @objc private func toggleFavorite(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        var favorites = favoriteKeys()
        if let index = favorites.firstIndex(of: key) {
            favorites.remove(at: index)
        } else {
            favorites.append(key)
        }
        saveFavoriteKeys(favorites)
        rebuildMenu()
    }

    @objc private func toggleAutoLaunch(_ sender: NSMenuItem) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: launchAgentPath) {
            do {
                try fileManager.removeItem(atPath: launchAgentPath)
                sender.state = .off
            } catch {
                showError("Não foi possível desativar a inicialização automática: \(error.localizedDescription)")
            }
            return
        }

        guard let executablePath = Bundle.main.executableURL?.path else {
            showError("Não foi possível identificar o executável do aplicativo.")
            return
        }
        let escapedExecutablePath = executablePath
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>br.com.luizfilipe.alternar-resolucao</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(escapedExecutablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """
        do {
            try fileManager.createDirectory(
                at: URL(fileURLWithPath: launchAgentPath).deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try plist.write(toFile: launchAgentPath, atomically: true, encoding: .utf8)
            sender.state = .on
        } catch {
            showError("Não foi possível ativar a inicialização automática: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Não foi possível alterar a resolução"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = ResolutionMenuApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
