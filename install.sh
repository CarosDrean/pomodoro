#!/usr/bin/env bash
#
# Build and install Pomodoro as a macOS menu bar app.
#
#   ./install.sh                 # build Release and install to /Applications
#   ./install.sh --debug         # build Debug instead
#   ./install.sh --dest ~/Applications
#   ./install.sh --no-open       # install without launching
#   ./install.sh --uninstall     # remove the installed app
#
# Two build paths are supported:
#   * xcodebuild + xcodegen  (full Xcode installed)  — preferred
#   * swiftc                 (Command Line Tools only) — automatic fallback
#
set -euo pipefail

APP_NAME="Pomodoro"
SCHEME="Pomodoro"
XCODEPROJ="Pomodoro.xcodeproj"
CONFIGURATION="Release"
INSTALL_DIR="/Applications"
OPEN_AFTER_INSTALL=1
UNINSTALL=0

BUNDLE_ID="com.drean.pomodoro"
MARKETING_VERSION="1.0.0"
BUILD_VERSION="1"
DEPLOY_TARGET="14.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DERIVED_DATA="$SCRIPT_DIR/build"

# pretty output ---------------------------------------------------------------
if [[ -t 1 ]]; then
  BOLD="$(tput bold 2>/dev/null || true)"; RED="$(tput setaf 1 2>/dev/null || true)"
  GREEN="$(tput setaf 2 2>/dev/null || true)"; YELLOW="$(tput setaf 3 2>/dev/null || true)"
  RESET="$(tput sgr0 2>/dev/null || true)"
else
  BOLD=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi

info()  { printf '%s==>%s %s\n' "$BOLD" "$RESET" "$*"; }
ok()    { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()   { printf '%s✗%s %b\n' "$RED" "$RESET" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
${BOLD}Usage:${RESET} ./install.sh [options]

Options:
  -c, --configuration <name>   Build configuration (Release|Debug). Default: Release
  -d, --debug                  Shorthand for --configuration Debug
  -r, --release                Shorthand for --configuration Release
      --dest <dir>             Install destination. Default: /Applications
      --no-open                Do not launch the app after installing
  -u, --uninstall              Remove the installed app and exit
  -h, --help                   Show this help
EOF
}

# args ------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--configuration) [[ $# -ge 2 ]] || die "--configuration needs a value"; CONFIGURATION="$2"; shift 2 ;;
    -d|--debug)         CONFIGURATION="Debug"; shift ;;
    -r|--release)       CONFIGURATION="Release"; shift ;;
    --dest)             [[ $# -ge 2 ]] || die "--dest needs a value"; INSTALL_DIR="${2/#\~/$HOME}"; shift 2 ;;
    --no-open)          OPEN_AFTER_INSTALL=0; shift ;;
    -u|--uninstall)     UNINSTALL=1; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  usage; die "unknown option: $1" ;;
  esac
done

case "$CONFIGURATION" in
  Release|Debug) ;;
  *) die "unsupported configuration: $CONFIGURATION (use Release or Debug)" ;;
esac

APP_DEST="$INSTALL_DIR/$APP_NAME.app"

quit_running_app() {
  if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    info "Quitting running ${APP_NAME}…"
    osascript -e "quit app \"$APP_NAME\"" >/dev/null 2>&1 || pkill -x "$APP_NAME" || true
    for _ in $(seq 1 20); do
      pgrep -x "$APP_NAME" >/dev/null 2>&1 || break
      sleep 0.25
    done
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  fi
}

# uninstall -------------------------------------------------------------------
if [[ "$UNINSTALL" -eq 1 ]]; then
  quit_running_app
  if [[ -d "$APP_DEST" ]]; then
    rm -rf "$APP_DEST"
    ok "Removed $APP_DEST"
  else
    warn "$APP_DEST is not installed"
  fi
  exit 0
fi

cd "$SCRIPT_DIR"

# build: xcodebuild + xcodegen (preferred) ------------------------------------
have_full_xcode() { xcodebuild -version >/dev/null 2>&1; }
have_xcodegen()    { command -v xcodegen >/dev/null 2>&1; }

build_with_xcodebuild() {
  info "Generating ${XCODEPROJ}…"
  xcodegen generate --quiet

  info "Building $APP_NAME ($CONFIGURATION) with xcodebuild…"
  xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA" \
    build \
    | (command -v xcbeautify >/dev/null 2>&1 && xcbeautify || cat)
}

# build: swiftc (fallback when Xcode / xcodegen are unavailable) --------------
make_icns() {
  local iconset="$1" out="$2"
  local assets="$SCRIPT_DIR/Pomodoro/Assets.xcassets/AppIcon.appiconset"
  [[ -f "$assets/1024.png" ]] || return 1

  rm -rf "$iconset"; mkdir -p "$iconset"
  local pair
  for pair in "16 16x16" "32 16x16@2x" "32 32x32" "64 32x32@2x" \
              "128 128x128" "256 128x128@2x" "256 256x256" \
              "512 256x256@2x" "512 512x512" "1024 512x512@2x"; do
    local size="${pair%% *}" name="${pair##* }"
    [[ -f "$assets/$size.png" ]] || continue
    cp "$assets/$size.png" "$iconset/icon_${name}.png"
  done
  iconutil -c icns "$iconset" -o "$out" 2>/dev/null || return 1
}

build_with_swiftc() {
  local sdk arch tmp app exe
  sdk="$(xcrun --show-sdk-path 2>/dev/null)" || true
  [[ -n "$sdk" && -d "$sdk" ]] || die "No macOS SDK found. Install Xcode or the Command Line Tools."

  arch="$(uname -m)"
  app="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
  exe="$app/Contents/MacOS/$APP_NAME"

  info "Building $APP_NAME ($CONFIGURATION) with swiftc…"
  rm -rf "$app"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

  local sources flags=()
  sources="$(find "$SCRIPT_DIR/Pomodoro" -name '*.swift' | sort)"
  [[ -n "$sources" ]] || die "No Swift sources found in $SCRIPT_DIR/Pomodoro"

  # Since the macOS 26 SDK, SwiftUI's @State/@Binding/… are macros. The macro
  # plugin ships only inside Xcode, never with the Command Line Tools.
  local plugin_dir="" candidate dir
  for candidate in "$(xcode-select -p 2>/dev/null || true)" \
                   /Applications/Xcode.app/Contents/Developer \
                   /Applications/Xcode-beta.app/Contents/Developer; do
    dir="$candidate/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins"
    if [[ -f "$dir/libSwiftUIMacros.dylib" ]]; then
      plugin_dir="$dir"
      break
    fi
  done
  if [[ -n "$plugin_dir" ]]; then
    flags+=(-plugin-path "$plugin_dir")
  else
    warn "SwiftUI macro plugin not found in any Xcode toolchain; relying on the compiler defaults."
  fi

  flags+=(-parse-as-library -swift-version 5)
  flags+=(-target "${arch}-apple-macos${DEPLOY_TARGET}")
  flags+=(-sdk "$sdk")
  if [[ "$CONFIGURATION" == "Release" ]]; then
    flags+=(-O)
  fi
  # shellcheck disable=SC2086
  swiftc "${flags[@]}" -o "$exe" $sources

  # Info.plist with build settings substituted
  sed -e "s|\$(EXECUTABLE_NAME)|$APP_NAME|g" \
      -e "s|\$(PRODUCT_NAME)|$APP_NAME|g" \
      -e "s|\$(PRODUCT_BUNDLE_IDENTIFIER)|$BUNDLE_ID|g" \
      -e "s|\$(MARKETING_VERSION)|$MARKETING_VERSION|g" \
      -e "s|\$(CURRENT_PROJECT_VERSION)|$BUILD_VERSION|g" \
      -e "s|\$(MACOSX_DEPLOYMENT_TARGET)|$DEPLOY_TARGET|g" \
      "$SCRIPT_DIR/Pomodoro/Info.plist" > "$app/Contents/Info.plist"
  printf 'APPL????' > "$app/Contents/PkgInfo"

  tmp="$(mktemp -d)"
  if make_icns "$tmp/$APP_NAME.iconset" "$app/Contents/Resources/$APP_NAME.icns"; then
    ok "Generated app icon"
  else
    warn "Could not generate the app icon — continuing without it"
  fi
  rm -rf "$tmp"

  # Ad-hoc signature (required on Apple Silicon)
  codesign --force --sign - --timestamp=none "$app" >/dev/null 2>&1 \
    || warn "Ad-hoc codesign failed — the app may not launch"
}

# pick a build path -----------------------------------------------------------
if have_full_xcode && have_xcodegen; then
  build_with_xcodebuild
elif have_full_xcode; then
  warn "xcodegen not found — falling back to a plain swiftc build."
  warn "Run 'brew install xcodegen' to use the standard Xcode build."
  build_with_swiftc
else
  warn "Full Xcode not found (active dir: $(xcode-select -p))."
  warn "Falling back to a plain swiftc build with the Command Line Tools."
  build_with_swiftc
fi

BUILT_APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
[[ -d "$BUILT_APP" ]] || die "Build finished but $BUILT_APP was not found."
ok "Built $(basename "$BUILT_APP")"

# install ---------------------------------------------------------------------
quit_running_app

if [[ ! -d "$INSTALL_DIR" ]]; then
  info "Creating ${INSTALL_DIR}…"
  mkdir -p "$INSTALL_DIR"
fi

if [[ ! -w "$INSTALL_DIR" ]]; then
  info "Installing to $INSTALL_DIR (needs sudo)…"
  sudo rm -rf "$APP_DEST"
  sudo cp -R "$BUILT_APP" "$APP_DEST"
  sudo chown -R "$(whoami)" "$APP_DEST" 2>/dev/null || true
  sudo xattr -dr com.apple.quarantine "$APP_DEST" 2>/dev/null || true
else
  rm -rf "$APP_DEST"
  cp -R "$BUILT_APP" "$APP_DEST"
  xattr -dr com.apple.quarantine "$APP_DEST" 2>/dev/null || true
fi
ok "Installed $APP_DEST"

if [[ "$OPEN_AFTER_INSTALL" -eq 1 ]]; then
  # Refresh Launch Services so the menu bar app is found right away.
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$APP_DEST" 2>/dev/null || true
  open "$APP_DEST"
  ok "Launched $APP_NAME — look for the tomato in your menu bar 🍅"
else
  ok "Run it with: open \"$APP_DEST\""
fi
