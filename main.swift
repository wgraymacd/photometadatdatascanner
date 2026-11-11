import Foundation
import ImageIO
import AppKit

// =====================================================================
// CONFIGURATION
// =====================================================================

// File extensions treated as "photos". Add more if you need them
// (e.g. "bmp", "gif", "cr3", "rw2", etc.)
let imageExtensions: Set<String> = [
    "jpg", "jpeg", "heic", "heif", "png", "tiff", "tif",
    "cr2", "nef", "arw", "dng", "raf", "orf"
]

// Folders to search. ~/Pictures covers the Photos app library on disk
// (Photos Library.photoslibrary is just a folder with a special icon).
// Add more URLs here (e.g. /Volumes for external drives) if you want
// a wider scan.
let homeDir = FileManager.default.homeDirectoryForCurrentUser
let searchRoots: [URL] = [
    homeDir.appendingPathComponent("Pictures"),
    homeDir.appendingPathComponent("Desktop"),
    homeDir.appendingPathComponent("Downloads"),
    homeDir.appendingPathComponent("Documents")
]

// =====================================================================
// DATA MODEL
// =====================================================================

struct PhotoRecord {
    let path: String
    let dateTaken: String?
    let latitude: Double?
    let longitude: Double?
}

// =====================================================================
// METADATA EXTRACTION
// =====================================================================

func extractMetadata(from url: URL) -> PhotoRecord {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    else {
        return PhotoRecord(path: url.path, dateTaken: nil, latitude: nil, longitude: nil)
    }

    var dateTaken: String?
    if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
        dateTaken = exif[kCGImagePropertyExifDateTimeOriginal] as? String
    }
    if dateTaken == nil, let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
        dateTaken = tiff[kCGImagePropertyTIFFDateTime] as? String
    }

    var latitude: Double?
    var longitude: Double?
    if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
        if let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
           let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String {
            latitude = (latRef == "S") ? -lat : lat
        }
        if let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
           let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String {
            longitude = (lonRef == "W") ? -lon : lon
        }
    }

    return PhotoRecord(path: url.path, dateTaken: dateTaken, latitude: latitude, longitude: longitude)
}

// =====================================================================
// CSV OUTPUT
// =====================================================================

func csvEscape(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    return field
}

func writeCSV(records: [PhotoRecord]) -> URL {
    var csv = "Path,DateTaken,Latitude,Longitude\n"
    for r in records {
        let path = csvEscape(r.path)
        let date = r.dateTaken ?? ""
        let lat = r.latitude != nil ? String(r.latitude!) : ""
        let lon = r.longitude != nil ? String(r.longitude!) : ""
        csv += "\(path),\(date),\(lat),\(lon)\n"
    }

    let outputURL = homeDir.appendingPathComponent("Desktop/PhotoMetadataReport.csv")
    try? csv.write(to: outputURL, atomically: true, encoding: .utf8)
    return outputURL
}

// =====================================================================
// UI (simple alert dialogs — no full app window needed)
// =====================================================================

func showStartAlert() -> Bool {
    _ = NSApplication.shared
    NSApp.setActivationPolicy(.regular)

    let alert = NSAlert()
    alert.messageText = "Scan Photos for Date & Location?"
    alert.informativeText = """
    This will scan your Pictures folder (including the Photos app library), \
    Desktop, Downloads, and Documents for photos, and save a report of each \
    photo's date and GPS location (when present) to a CSV file on your Desktop.

    macOS may ask for permission to access your Photos — please allow it. \
    If the scan finds nothing, you may need to grant Full Disk Access in \
    System Settings > Privacy & Security.
    """
    alert.addButton(withTitle: "Start Scan")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == .alertFirstButtonReturn
}

func showCompletionAlert(scanned: Int, withMetadata: Int, outputURL: URL) {
    let alert = NSAlert()
    alert.messageText = "Scan Complete"
    alert.informativeText = """
    Scanned \(scanned) photo files.
    \(withMetadata) had a date and/or GPS location.

    Report saved to: \(outputURL.lastPathComponent)
    """
    alert.addButton(withTitle: "Show in Finder")
    alert.addButton(withTitle: "OK")
    if alert.runModal() == .alertFirstButtonReturn {
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }
}

// =====================================================================
// MAIN
// =====================================================================

func run() {
    var records: [PhotoRecord] = []
    var scannedCount = 0
    var withMetadataCount = 0

    for root in searchRoots {
        guard FileManager.default.fileExists(atPath: root.path) else { continue }

        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true } // skip anything we can't read, keep going
        )
        guard let enumerator = enumerator else { continue }

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard imageExtensions.contains(ext) else { continue }

            scannedCount += 1
            let record = extractMetadata(from: fileURL)
            if record.dateTaken != nil || record.latitude != nil {
                withMetadataCount += 1
            }
            records.append(record)
        }
    }

    let outputURL = writeCSV(records: records)
    showCompletionAlert(scanned: scannedCount, withMetadata: withMetadataCount, outputURL: outputURL)
}

if showStartAlert() {
    run()
}
