APP_NAME = aria2-saver
BUILD_DIR = .build/arm64-apple-macosx/debug
RELEASE_DIR = .build/arm64-apple-macosx/release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
RELEASE_BUNDLE = $(RELEASE_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS

.PHONY: build app release release-app release-install release-dmg clean install dmg

build:
	swift build

app: build
	mkdir -p $(MACOS) $(CONTENTS)/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(MACOS)/$(APP_NAME)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp Resources/AppIcon.icns $(CONTENTS)/Resources/AppIcon.icns
	@echo "Built $(APP_BUNDLE)"

release:
	swift build -c release

release-app: release
	mkdir -p $(RELEASE_BUNDLE)/Contents/MacOS $(RELEASE_BUNDLE)/Contents/Resources
	cp $(RELEASE_DIR)/$(APP_NAME) $(RELEASE_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(RELEASE_BUNDLE)/Contents/Info.plist
	cp Resources/AppIcon.icns $(RELEASE_BUNDLE)/Contents/Resources/AppIcon.icns
	codesign --force --deep --sign - $(RELEASE_BUNDLE)
	@echo "Built $(RELEASE_BUNDLE)"

release-install: release-app
	rm -rf /Applications/$(APP_NAME).app
	cp -r $(RELEASE_BUNDLE) /Applications/$(APP_NAME).app
	@echo "Installed to /Applications/$(APP_NAME).app"

release-dmg: release-app
	rm -rf dmg_content $(APP_NAME).dmg
	mkdir -p dmg_content
	cp -r $(RELEASE_BUNDLE) dmg_content/
	ln -s /Applications dmg_content/Applications
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder dmg_content \
		-ov -format UDZO \
		$(APP_NAME).dmg
	rm -rf dmg_content
	@echo "Created $(APP_NAME).dmg"

clean:
	rm -rf .build

install: app
	rm -rf /Applications/$(APP_NAME).app
	cp -r $(APP_BUNDLE) /Applications/$(APP_NAME).app
	@echo "Installed to /Applications/$(APP_NAME).app"

dmg: app
	rm -rf dmg_content $(APP_NAME).dmg
	mkdir -p dmg_content
	cp -r $(APP_BUNDLE) dmg_content/
	ln -s /Applications dmg_content/Applications
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder dmg_content \
		-ov -format UDZO \
		$(APP_NAME).dmg
	rm -rf dmg_content
	@echo "Created $(APP_NAME).dmg"
