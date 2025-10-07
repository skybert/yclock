# yclock

A simple analog clock application for macOS, inspired by
[xclock](https://www.x.org/releases/X11R7.6/doc/man/man1/xclock.1.xhtml)
from X11 that you're used to on Linux and the BSDs.

## Features

- Analog clock face with hour, minute, and second hands
- Real-time updates every second
- Clean, minimal interface

## Building

Build the application:
```bash
$ make build
```

## Installing

Install the application to /Applications:
```bash
$ make install
```

## Running

Run the application:
```bash
$ make run
```

## Cleaning

Clean build artifacts:
```bash
$ make clean
```

## Requirements

- macOS 10.15 or later
- Xcode Command Line Tools (for swiftc compiler)

## License

This project is licensed under the Apache License 2.0 - see the
[LICENSE](LICENSE) file for details.
