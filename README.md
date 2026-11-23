# yclock

<img src="yclock/yclock.png" alt="yclock icon" width="128"/>

A simple analog clock application for macOS, inspired by
[xclock](https://www.x.org/releases/X11R7.6/doc/man/man1/xclock.1.xhtml)
from X11 that you're used to on Linux and the BSDs.

## Features

- Analog and digital clock modes (toggle with ⌘D)
- Optional seconds display (toggle with ⌘S)
- Real-time updates every second
- Clean, minimal interface with no window chrome
- Draggable anywhere on the clock face
- Translucent window that floats above other windows and is visible on all desktops
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
  --show-in-dock    Show app in Dock and Cmd+Tab switcher
  --font-name NAME  Specify font name for digital clock
  --help            Show this help message

Examples:
  yclock --digital --seconds
  yclock --analog
  yclock --digital --font-name Menlo
  yclock --font-name "Courier New" --seconds
  yclock --show-in-dock
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
# --- Colors ---

# Colors in #RRGGBB or #RRGGBBAA hex format (AA = alpha, 00 hides the element)
background = #24273af2
foreground = #cad3f5
second_hand = #ed8796

# Circle color (default: the foreground color); #RRGGBB00 hides the circle
# circle_color = #cad3f5

# Mark colors (#RRGGBBAA; alpha 00 hides the tier)
# Quarter marks (12, 3, 6, 9); default: the foreground color
# quarter_mark_color = #cad3f5
# Hour marks (other multiples of 5 minutes); default: the foreground color
# hour_mark_color = #cad3f5
# Minute marks (all other positions); default: the foreground color, hidden
# minute_mark_color = #cad3f500

# --- Mode, font, dock ---

# Clock mode (analog or digital)
mode = analog

# Font name for digital clock (optional)
# Examples: Menlo, Monaco, Courier, Helvetica, Arial
font = Menlo

# Show app in Dock and Cmd+Tab switcher (default: false)
# When false, app runs as an accessory and doesn't appear in Dock or Cmd+Tab
# show_in_dock = false

# Show seconds hand/display at startup (default: false)
# show_seconds = false

# --- Window ---

# Window size in base units; on-screen pixels = value * scale
width = 100
height = 100

# Pixels per base unit (default: 1.64)
scale = 1.64

# Window opacity, 0.0 (transparent) to 1.0 (opaque), applies to the whole window (default: 0.85)
# opacity = 0.85

# Window corner radius in base units, must be >= 0 (default: 7.3)
# Capped at half the shorter side: a large value (e.g. 1000) makes the window round/capsule
# corner_radius = 7.3

# Window shadow: default, enable or disable (default: default)
# Follows the visible shape: with a round window it appears as a ring around it
# window_shadow = default

# --- Clock face ---

# Clock circle diameter in base units, must be > 0 (default: 87.8)
# With the default 100x100 window this leaves a small margin; larger values are clipped
# clock_size = 87.8

# Hand widths in base units, must be >= 0, 0 hides the hand (defaults: 3.7, 2.4, 1.2)
# hour_hand_width = 3.7
# minute_hand_width = 2.4
# second_hand_width = 1.2

# Circle line width in base units, must be >= 0 (default: 1.2); 0 hides the circle
# circle_width = 1.2

# Mark sizes WxL in base units (defaults: 1.2x4.4 for hour and quarter, 1.2 for minute)
# W is the width along the circle, L the length towards the centre
# Two numbers >= 0 with any non-numeric separator (1.2x4.4, 1.2:4.4); a single number N means NxN
# quarter_mark_size = 1.2x4.4
# hour_mark_size = 1.2x4.4
# minute_mark_size = 1.2

# Distance from the clock circle to the outer end of dashes or the centre of dots, must be >= 0 (default: 2.2)
# mark_inset = 2.2

# Mark style: dashes or dots (default: dashes); a dot is a WxL ellipse, so size N gives a round dot
# mark_style = dashes
# Dotted face without the circle:
#   circle_color = #cad3f500
#   mark_style = dots
#   minute_mark_color = #cad3f5
#   minute_mark_size = 1
#   hour_mark_size = 2
#   quarter_mark_size = 3
```

## Requirements

- macOS 11.0 or later
- Xcode Command Line Tools (for swiftc compiler)

## Building

```bash
$ make clean && make build
```

## Running

```bash
$ make run
```

## Testing

```bash
$ make test
```

## Installing

Install the application and man page to /Applications:
```bash
$ make install
```

This will install both the application bundle and the man page. After
installation, you can view the manual with:

```bash
$ man yclock
```
and start the application with:

```bash
$ yclock
```

## License

This project is licensed under the Apache License 2.0 - see the
[LICENSE](LICENSE) file for details.
