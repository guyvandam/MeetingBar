APP_NAME = MeetingBar
SCHEME = MeetingBar
PROJECT = MeetingBar.xcodeproj
BUILD_DIR = build
CONFIGURATION = Release
APP_PATH = $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app
INSTALL_DIR = /Applications

.PHONY: build install clean

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR) build

install: build
	@echo "Copying $(APP_NAME).app to $(INSTALL_DIR)..."
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R "$(APP_PATH)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed $(APP_NAME) to $(INSTALL_DIR)"

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(BUILD_DIR)
