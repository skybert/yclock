.PHONY: build run clean install test 

APP_NAME = yclock
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
EXECUTABLE = $(MACOS_DIR)/$(APP_NAME)
INSTALL_DIR = /Applications
MAN_DIR = ~/.local/share/man/man1

SOURCES = yclock/main.swift yclock/app-delegate.swift yclock/clock-view.swift yclock/theme.swift
SWIFT_FLAGS = -O

build: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCES) yclock/info.plist
	@echo "Building $(APP_NAME)..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@swift build -c release
	@cp .build/release/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	@cp yclock/info.plist $(CONTENTS_DIR)/Info.plist
	@cp yclock/yclock.icns $(RESOURCES_DIR)/yclock.icns
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
	@echo "Installing man page to $(MAN_DIR)..."
	@mkdir -p $(MAN_DIR)
	@sed 's/AUTHORS_FILE_CONTENTS/Written by '"$$(cat AUTHORS | tr '\n' ',' | sed 's/,$$/\./' | sed 's/,/, /g')"'/' man/yclock.1 > $(MAN_DIR)/yclock.1
	@echo "Man page installed. View with: man yclock"

test:
	@echo "Running tests..."
	@swift test

