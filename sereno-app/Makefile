# Makefile for sereno (familia vaho) — manager app + bundled terminal installer

BUNDLE    = SerenoApp
APP_NAME  = sereno
BINARY    = .build/apple/Products/Release/$(BUNDLE)
APP_DIR   = build/$(APP_NAME).app
CONTENTS  = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources
FRAMEWORKS_DIR = $(CONTENTS)/Frameworks

# Signing identity, in order of preference:
#   1. Developer ID Application — the only identity other Macs accept and the only one Apple
#      will notarize. Everything we ship must use it.
#   2. Apple Development — local fallback for a machine without the Developer ID cert.
#   3. Ad-hoc ("-") — cdhash-only designated requirement, which CHANGES every build and so
#      silently voids any TCC grant on each rebuild.
# `find-identity -v` also lists REVOKED certs (CSSMERR_TP_CERT_REVOKED); filter them or
# codesign fails late with a confusing error. `make SIGN_IDENTITY=-` forces ad-hoc.
IDENTITIES = security find-identity -v -p codesigning 2>/dev/null | grep -v CSSMERR_TP_CERT_REVOKED
SIGN_IDENTITY ?= $(shell $(IDENTITIES) | grep -m1 -o '"Developer ID Application: [^"]*"' | tr -d '"')
ifeq ($(strip $(SIGN_IDENTITY)),)
SIGN_IDENTITY := $(shell $(IDENTITIES) | grep -m1 -o '"Apple Development: [^"]*"' | tr -d '"')
endif
ifeq ($(strip $(SIGN_IDENTITY)),)
SIGN_IDENTITY := -
endif

# Hardened runtime + secure timestamp: both hard requirements for notarization. sereno needs
# no entitlements alongside them — the bundled installer is shell scripts (no Mach-O to sign
# separately), and the app does no dlopen of foreign dylibs, no AppleScript and no JIT, which
# are the things hardened runtime would otherwise block.
# Skipped for ad-hoc: --timestamp round-trips to Apple and simply fails offline.
ifeq ($(SIGN_IDENTITY),-)
CODESIGN_FLAGS =
else
CODESIGN_FLAGS = --options runtime --timestamp
endif

.PHONY: all build app run clean dmg release check-devid notarize-app notarize-dmg

all: app
release: app

## Compile the Swift sources (release, universal)
build:
	swift build -c release --arch arm64 --arch x86_64

## Assemble the .app bundle from the compiled binary
app: build
	@echo "📦 Ensamblando $(APP_NAME).app..."
	@rm -rf $(APP_DIR)
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@mkdir -p $(FRAMEWORKS_DIR)
	@cp $(BINARY) $(MACOS_DIR)/$(BUNDLE)
	@cp Info.plist $(CONTENTS)/Info.plist
	@if [ -f "icon.icns" ]; then \
		cp icon.icns $(RESOURCES_DIR)/AppIcon.icns; \
	elif [ -f "icon.png" ]; then \
		echo "🎨 Generando icono..."; \
		mkdir -p AppIcon.iconset; \
		sips -z 16 16     icon.png --out AppIcon.iconset/icon_16x16.png > /dev/null; \
		sips -z 32 32     icon.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null; \
		sips -z 32 32     icon.png --out AppIcon.iconset/icon_32x32.png > /dev/null; \
		sips -z 64 64     icon.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null; \
		sips -z 128 128   icon.png --out AppIcon.iconset/icon_128x128.png > /dev/null; \
		sips -z 256 256   icon.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null; \
		sips -z 256 256   icon.png --out AppIcon.iconset/icon_256x256.png > /dev/null; \
		sips -z 512 512   icon.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null; \
		sips -z 512 512   icon.png --out AppIcon.iconset/icon_512x512.png > /dev/null; \
		sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null; \
		iconutil -c icns AppIcon.iconset -o $(RESOURCES_DIR)/AppIcon.icns; \
		rm -R AppIcon.iconset; \
	fi
	# Bundle the terminal installer (scripts) so the .app is self-contained: the app
	# offers to run it on first launch (see AppDelegate.launchInstaller). Sprites no
	# longer ship with the repo — they come from sprite-packs/ via the app.
	@mkdir -p $(RESOURCES_DIR)/installer
	@cp ../install.sh ../uninstall.sh ../greet.sh ../pick_random.sh ../get_color.py ../fastfetch.jsonc $(RESOURCES_DIR)/installer/
	@chmod +x $(RESOURCES_DIR)/installer/install.sh $(RESOURCES_DIR)/installer/uninstall.sh $(RESOURCES_DIR)/installer/greet.sh
	# Embed Sparkle.framework (auto-update): swift build links against it but doesn't
	# copy it into the bundle, and Sparkle can't run from outside the app.
	@SPARKLE_FW=$$(find .build -maxdepth 8 -name 'Sparkle.framework' -type d | head -1); \
	if [ -z "$$SPARKLE_FW" ]; then echo "ERROR: Sparkle.framework not found in .build"; exit 1; fi; \
	cp -R "$$SPARKLE_FW" $(FRAMEWORKS_DIR)/
	@install_name_tool -add_rpath @executable_path/../Frameworks $(MACOS_DIR)/$(BUNDLE) 2>/dev/null || true
	# Sign inner-out. NOT `--deep`: Apple documents it as unsuitable for distribution because
	# it re-signs nested code with the OUTER bundle's entitlements and options, and
	# notarization rejects the result. Sign each nested executable explicitly, deepest first,
	# or the outer signature seals mis-signed code.
	@set -e; SPK=$(FRAMEWORKS_DIR)/Sparkle.framework/Versions/B; \
	for x in "$$SPK"/XPCServices/*.xpc "$$SPK/Updater.app" "$$SPK/Autoupdate"; do \
	  [ -e "$$x" ] || continue; \
	  codesign --force $(CODESIGN_FLAGS) --sign "$(SIGN_IDENTITY)" "$$x"; \
	done; \
	codesign --force $(CODESIGN_FLAGS) --sign "$(SIGN_IDENTITY)" "$$SPK"
	@codesign --force $(CODESIGN_FLAGS) --sign "$(SIGN_IDENTITY)" $(APP_DIR)
	@codesign --verify --deep --strict $(APP_DIR)
	@echo "✅ Listo: $(APP_DIR) (firmado: $(SIGN_IDENTITY))"

# DMG for first-time downloads (auto-updates travel as .zip via Sparkle).
# Stable, unversioned name: the landing links releases/latest/download/sereno.dmg.
dmg:
	rm -f dist/$(APP_NAME).dmg
	mkdir -p dist
	create-dmg --volname "$(APP_NAME)" --window-size 500 320 --icon-size 96 \
	  --icon "$(APP_NAME).app" 120 130 --app-drop-link 380 130 \
	  --hide-extension "$(APP_NAME).app" \
	  dist/$(APP_NAME).dmg $(APP_DIR)
	codesign --force $(CODESIGN_FLAGS) --sign "$(SIGN_IDENTITY)" dist/$(APP_NAME).dmg

# ── Notarization ──────────────────────────────────────────────────────────────
# Apple scans the build and issues a ticket Gatekeeper trusts, so a downloaded app opens on
# a double-click: no right-click → Open, no `xattr -dr com.apple.quarantine`. Needs hardened
# runtime + secure timestamp (CODESIGN_FLAGS) and a Developer ID identity.
#
# NOTE: notarization does NOT grant TCC permissions. Those the user approves by hand.
#
# One Apple account covers the whole vaho family, so all four apps share the same notarytool
# Keychain profile. Created once with:
#   xcrun notarytool store-credentials vaho-notary --apple-id <id> --team-id XZVWF6BXDQ
NOTARY_PROFILE ?= vaho-notary
NOTARIZE_ZIP = .notarize-upload.zip

check-devid:
	@case "$(SIGN_IDENTITY)" in \
	  "Developer ID Application"*) ;; \
	  *) echo "ERROR: notarization requires a Developer ID Application identity."; \
	     echo "       Current SIGN_IDENTITY: $(SIGN_IDENTITY)"; exit 1 ;; \
	esac

# Staple the app BEFORE zipping it for Sparkle or copying it into the dmg: stapling attaches
# the ticket to the bundle on disk, so first launch works with no network.
notarize-app: check-devid
	@test -d $(APP_DIR) || { echo "ERROR: $(APP_DIR) not found — run 'make app' first"; exit 1; }
	rm -f $(NOTARIZE_ZIP)
	ditto -c -k --keepParent $(APP_DIR) $(NOTARIZE_ZIP)
	@echo "Submitting $(APP_DIR) to Apple (queue is usually minutes, can be over an hour)..."
	xcrun notarytool submit $(NOTARIZE_ZIP) --keychain-profile $(NOTARY_PROFILE) --wait
	rm -f $(NOTARIZE_ZIP)
	xcrun stapler staple $(APP_DIR)
	spctl -a -vvv -t exec $(APP_DIR)

# The dmg is its own downloaded file, so Gatekeeper checks it separately from the app inside.
notarize-dmg: check-devid
	@test -f dist/$(APP_NAME).dmg || { echo "ERROR: dist/$(APP_NAME).dmg not found — run 'make dmg' first"; exit 1; }
	xcrun notarytool submit dist/$(APP_NAME).dmg --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple dist/$(APP_NAME).dmg
	xcrun stapler validate dist/$(APP_NAME).dmg

## Open the app (builds first if needed)
run: app
	@open $(APP_DIR)

## Remove build artifacts
clean:
	swift package clean
	rm -rf build/
