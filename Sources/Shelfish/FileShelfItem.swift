import Cocoa

struct FileShelfItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    var displayName: String { url.lastPathComponent }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }

    static func == (lhs: FileShelfItem, rhs: FileShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}
