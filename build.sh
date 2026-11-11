#!/bin/bash
set -e # abort immediately if any subsequent command fails (non-zero exit code)

APP_NAME="PhotoMetadataScanner" # defines var for name of app
BUNDLE="${APP_NAME}.app" # defines var for the app bundle folder name

echo "==> Cleaning previous build..."
rm -rf "$BUNDLE" "${APP_NAME}.zip"

echo "==> Creating app bundle structure..." 
mkdir -p "$BUNDLE/Contents/MacOS" # creates internal folder where the executable binary must live inside a mac app
mkdir -p "$BUNDLE/Contents/Resources" # creates the internal folder used to store app assets like icons and images
cp Info.plist "$BUNDLE/Contents/Info.plist" # copies the required metadata config file into the root of the app bundle

echo "==> Compiling Swift source..."
swiftc main.swift -O -framework AppKit -o "$BUNDLE/Contents/MacOS/$APP_NAME" # compiles the main.swift file, uses -O for optimization, linkes Apple's UI framework, and outputs the compiled binary into the app bundle
chmod +x "$BUNDLE/Contents/MacOS/$APP_NAME" # grants execution permission to the compiled binary so mac can run it

echo "==> Ad-hoc signing (required to run on Apple Silicon)..."
xattr -cr "$BUNDLE" # strips hidden Finder metadata and resource forks so code signing passes
codesign --force --deep --sign - "$BUNDLE" # applies an ad-hoc (unsigned/local) digital signature to the bundle, --force overwrites any existing signature, --deep signs everything nested in the bundle, and - specifies an ad-hoc identity, which is mandatory for binaries running on Apple Silicon

echo "==> Zipping for sharing..."
ditto -c -k --sequesterRsrc --keepParent "$BUNDLE" "${APP_NAME}.zip" # ditto compresses app bundle into a zip archive, --sequesterRsrc preserves mac-specific metadata and resource forks, --keepParent ensures the root folder is included inside the zip so it doesn't extract loose files

echo ""
echo "Done! ${APP_NAME}.zip is ready."
echo "Tell whoever you send it to: unzip it, then right-click the app"
echo "and choose 'Open' the first time (macOS will warn about an"
echo "unidentified developer since this isn't notarized by Apple)."
