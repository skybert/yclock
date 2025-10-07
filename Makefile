.PHONY: build run clean install

APP_NAME = yclock
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
EXECUTABLE = $(MACOS_DIR)/$(APP_NAME)
INSTALL_DIR = /Applications

SOURCES = yclock/main.swift yclock/app-delegate.swift yclock/clock-view.swift yclock/theme.swift
SWIFT_FLAGS = -O

build: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCES) yclock/info.plist
	@echo "Building $(APP_NAME)..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@swiftc $(SWIFT_FLAGS) -o $(MACOS_DIR)/$(APP_NAME) $(SOURCES) \
		-framework Cocoa \
		-Xcc -Wno-error=module-import-redundancy
	@cp yclock/info.plist $(CONTENTS_DIR)/Info.plist
	@echo "Build complete: $(APP_BUNDLE)"

run: build
	@echo "Running $(APP_NAME)..."
	@open $(APP_BUNDLE)

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@echo "Clean complete"

install: build
	@echo "Installing $(APP_NAME) to $(INSTALL_DIR)..."
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@cp -R $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installation complete: $(INSTALL_DIR)/$(APP_NAME).app"
