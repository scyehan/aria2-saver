APP_NAME = aria2-saver
BUILD_DIR = .build/arm64-apple-macosx/debug
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS

.PHONY: build app clean

build:
	swift build

app: build
	mkdir -p $(MACOS) $(CONTENTS)/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(MACOS)/$(APP_NAME)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp Resources/AppIcon.icns $(CONTENTS)/Resources/AppIcon.icns
	@echo "Built $(APP_BUNDLE)"

clean:
	rm -rf .build

install: app
	rm -rf /Applications/$(APP_NAME).app
	cp -r $(APP_BUNDLE) /Applications/$(APP_NAME).app
	@echo "Installed to /Applications/$(APP_NAME).app"
