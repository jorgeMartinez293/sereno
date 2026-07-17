# Makefile for sereno (familia vaho) — manager app + bundled terminal installer

BUNDLE    = SerenoApp
APP_NAME  = sereno
BINARY    = .build/apple/Products/Release/$(BUNDLE)
APP_DIR   = build/$(APP_NAME).app
CONTENTS  = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources
FRAMEWORKS_DIR = $(CONTENTS)/Frameworks

# Signing identity. Prefers the Apple Development certificate (stable designated
# requirement); ad-hoc otherwise. Override with `make SIGN_IDENTITY=-`.
SIGN_IDENTITY ?= $(shell security find-identity -v -p codesigning 2>/dev/null \
	| grep -m1 -o '"Apple Development: [^"]*"' | tr -d '"')
ifeq ($(strip $(SIGN_IDENTITY)),)
SIGN_IDENTITY = -
endif

.PHONY: all build app run clean dmg release

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
	# Bundle the terminal installer (scripts + sprites) so the .app is self-contained:
	# the app offers to run it on first launch (see AppDelegate.launchInstaller).
	@mkdir -p $(RESOURCES_DIR)/installer
	@cp ../install.sh ../uninstall.sh ../greet.sh ../pick_random.sh ../get_color.py ../fastfetch.jsonc $(RESOURCES_DIR)/installer/
	@chmod +x $(RESOURCES_DIR)/installer/install.sh $(RESOURCES_DIR)/installer/uninstall.sh $(RESOURCES_DIR)/installer/greet.sh
	@cp -R ../sprites $(RESOURCES_DIR)/installer/sprites
	# Embed Sparkle.framework (auto-update): swift build links against it but doesn't
	# copy it into the bundle, and Sparkle can't run from outside the app.
	@SPARKLE_FW=$$(find .build -maxdepth 8 -name 'Sparkle.framework' -type d | head -1); \
	if [ -z "$$SPARKLE_FW" ]; then echo "ERROR: Sparkle.framework not found in .build"; exit 1; fi; \
	cp -R "$$SPARKLE_FW" $(FRAMEWORKS_DIR)/
	@install_name_tool -add_rpath @executable_path/../Frameworks $(MACOS_DIR)/$(BUNDLE) 2>/dev/null || true
	@codesign --force --deep --sign "$(SIGN_IDENTITY)" $(FRAMEWORKS_DIR)/Sparkle.framework
	@codesign --force --deep --sign "$(SIGN_IDENTITY)" $(APP_DIR)
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
	codesign --force --sign "$(SIGN_IDENTITY)" dist/$(APP_NAME).dmg

## Open the app (builds first if needed)
run: app
	@open $(APP_DIR)

## Remove build artifacts
clean:
	swift package clean
	rm -rf build/
