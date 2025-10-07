# yclock

A simple analog clock application for macOS, inspired by
[xclock](https://www.x.org/releases/X11R7.6/doc/man/man1/xclock.1.xhtml)
from X11 that you're used to on Linux and the BSDs.

## Features

- Analog and digital clock modes (toggle with ⌘D)
- Optional seconds display (toggle with ⌘S)
- Real-time updates every second
- Clean, minimal interface with no window chrome
- Draggable anywhere on the clock face
- Translucent window
- Themeable via configuration file
- Command line options for startup mode

## Screenshots
<img
  src="doc/yclock-analogue.png"
  alt="yclock analogue"
/>

<img
  src="doc/yclock-digital.png"
  alt="yclock digital"
/>

## Usage

```bash
yclock [OPTIONS]

Options:
  --digital         Start in digital mode
  --analog          Start in analog mode (default)
  --analogue        Same as --analog
  --seconds         Show seconds hand/display
  --help            Show this help message

Examples:
  yclock --digital --seconds
  yclock --analog
```

## Configuration

`yclock` can be themed by creating a configuration file. The app looks
for config files in the following order:
1. `~/.yclock.conf`
2. `~/.config/yclock/yclock.conf`
3. `$XDG_CONFIG_HOME/yclock/yclock.conf`

See `conf/yclock.conf` for the format. The default theme is Catppuccin
Macchiato.

Example configuration:
```perl
# Colors in RGB hex format
background = #24273a
foreground = #cad3f5
second_hand = #ed8796

# Clock mode (analog or digital)
mode = analog

# Window dimensions
width = 164
height = 164
```

## Requirements

- macOS 11.0 or later
- Xcode Command Line Tools (for swiftc compiler)

## Building

Build the application:
```bash
$ make clean && make build
```

## Running

Run the application:
```bash
$ make run
```

Or run directly with options:
```bash
$ ./build/yclock.app/Contents/MacOS/yclock --digital --seconds
```

## Testing

Run the test suite:
```bash
$ make test
```

Or using Swift Package Manager:
```bash
$ swift test
```

## Installing

Install the application to /Applications:
```bash
$ make install
```

## Development

The project uses Swift Package Manager for dependency management and testing.
The codebase is split into:
- `yClockLib` - Core clock functionality (testable library)
- `yclock` - Main executable and command line interface

Available make targets:
- `make build` - Build the application
- `make run` - Build and run the application
- `make test` - Run tests
- `make clean` - Clean build artifacts
- `make install` - Install to /Applications

## License

This project is licensed under the Apache License 2.0 - see the
[LICENSE](LICENSE) file for details.
