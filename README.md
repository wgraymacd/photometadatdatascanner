# Photo Metadata Scanner

A small double-clickable Mac app that scans your photos (including the
Photos app library) and pulls out date-taken and GPS location data into
a CSV report on your Desktop.

## What's in this folder

- `main.swift` — the app's source code
- `Info.plist` — app bundle configuration
- `build.sh` — builds everything into a shippable `.app`

## Build it (run this on a Mac, not this sandbox)

1. Make sure Xcode Command Line Tools are installed:
   ```
   xcode-select --install
   ```
   (If already installed, this will just say so — that's fine.)

2. In Terminal, `cd` into this folder, then run:
   ```
   chmod +x build.sh
   ./build.sh
   ```
This grants execute permissions to the file `build.sh` and executes the file.

3. You'll end up with `PhotoMetadataScanner.app` and
   `PhotoMetadataScanner.zip` in the same folder. The `.zip` is the
   thing to share — send that file to whoever needs it.

## Running it

Double-click the app. It will:

1. Show a dialog explaining what it's about to do (Start Scan / Cancel).
2. Scan `~/Pictures` (which includes the Photos library on disk),
   `~/Desktop`, `~/Downloads`, and `~/Documents` for image files.
3. Pull EXIF date and GPS coordinates from each one it can read.
4. Save `PhotoMetadataReport.csv` to the Desktop.
5. Show a completion dialog with a "Show in Finder" shortcut to the report.

## Two permission things to expect

**Gatekeeper warning on first launch.** Since this isn't signed with a
paid Apple Developer account or notarized by Apple, macOS will likely
say it "cannot be opened because it is from an unidentified developer."
Right-click the app and choose **Open** (instead of double-clicking) the
first time — this bypasses that warning. After that, double-clicking
works normally.

**Photos / Full Disk Access permission.** The first time the app reads
inside the Photos library, macOS may show a permission prompt — allow
it. If the report comes back mostly empty, go to **System Settings >
Privacy & Security > Full Disk Access** and add the app there manually,
then run it again.

## Adjusting what gets scanned

Open `main.swift` and look near the top for `searchRoots` — add or
remove folders there (for example `/Volumes` to include external
drives). Also see `imageExtensions` if you want to include other file
types like `.bmp` or additional RAW formats. After editing, just run
`./build.sh` again.

## Notes

- This was written and reviewed in a non-Mac environment, so while the
  code has been checked carefully against Apple's APIs, you're the
  first to actually compile and run it. If `swiftc` throws an error,
  send it back and it can be fixed quickly.
