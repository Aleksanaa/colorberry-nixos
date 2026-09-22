// Command colorberry-sidebutton toggles the display and keyboard backlights
// together when the side button is pressed.
package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/warthog618/go-gpiocdev"
	"golang.org/x/sys/unix"
)

type backlight struct {
	display    string
	keyboard   string
	brightness int
}

// on reports whether the display backlight is lit. The keyboard follows the
// display, so only one of the two has to be read back.
func (b backlight) on() (bool, error) {
	buf, err := os.ReadFile(b.display)
	if err != nil {
		return false, err
	}
	v, err := strconv.Atoi(strings.TrimSpace(string(buf)))
	if err != nil {
		return false, fmt.Errorf("%s: %w", b.display, err)
	}
	return v != 0, nil
}

func (b backlight) set(on bool) error {
	display, keyboard := "0", "0"
	if on {
		display, keyboard = "1", strconv.Itoa(b.brightness)
	}
	if err := os.WriteFile(b.display, []byte(display), 0); err != nil {
		return err
	}
	return os.WriteFile(b.keyboard, []byte(keyboard), 0)
}

func (b backlight) toggle() (bool, error) {
	on, err := b.on()
	if err != nil {
		return false, err
	}
	return !on, b.set(!on)
}

// waitFor blocks until every path exists, since the sysfs attributes appear
// only once sharp-drm and beepy-kbd have probed.
func waitFor(timeout time.Duration, paths ...string) error {
	deadline := time.Now().Add(timeout)
	for {
		missing := ""
		for _, p := range paths {
			if _, err := os.Stat(p); err != nil {
				missing = p
				break
			}
		}
		if missing == "" {
			return nil
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("%s did not appear within %s", missing, timeout)
		}
		time.Sleep(time.Second)
	}
}

// findChip resolves a gpiochip label, as printed by gpiodetect, to its device
// name. Line offsets only mean anything relative to a chip, and the chip
// numbering is not stable across boots.
func findChip(label string) (string, error) {
	names := gpiocdev.Chips()
	for _, name := range names {
		c, err := gpiocdev.NewChip(name)
		if err != nil {
			continue
		}
		found := c.Label == label
		c.Close()
		if found {
			return name, nil
		}
	}
	return "", fmt.Errorf("no gpiochip labelled %q among %s", label, strings.Join(names, ", "))
}

// monotonic returns the current CLOCK_MONOTONIC reading, the clock that line
// event timestamps are taken from.
func monotonic() (time.Duration, error) {
	var ts unix.Timespec
	if err := unix.ClockGettime(unix.CLOCK_MONOTONIC, &ts); err != nil {
		return 0, err
	}
	return time.Duration(ts.Nano()), nil
}

func main() {
	log.SetFlags(0)

	var (
		chipLabel  = flag.String("chip", "300b000.pinctrl", "label of the gpiochip carrying the button")
		line       = flag.Int("line", 226, "button line offset on that chip")
		edge       = flag.String("edge", "falling", "edge that counts as a press: rising, falling or both")
		holdoff    = flag.Duration("debounce", 200*time.Millisecond, "ignore further edges for this long after a press")
		brightness = flag.Int("brightness", 255, "keyboard backlight brightness when lit")
		display    = flag.String("display", "/sys/module/sharp_drm/parameters/backlit", "display backlight attribute")
		keyboard   = flag.String("keyboard", "/sys/firmware/beepy/keyboard_backlight", "keyboard backlight attribute")
		timeout    = flag.Duration("timeout", 60*time.Second, "how long to wait for those attributes")
	)
	flag.Parse()

	if *brightness < 0 || *brightness > 255 {
		log.Fatalf("brightness %d out of range 0-255", *brightness)
	}

	var edges gpiocdev.LineReqOption
	switch *edge {
	case "rising":
		edges = gpiocdev.WithRisingEdge
	case "falling":
		edges = gpiocdev.WithFallingEdge
	case "both":
		edges = gpiocdev.WithBothEdges
	default:
		log.Fatalf("unknown edge %q, want rising, falling or both", *edge)
	}

	if err := waitFor(*timeout, *display, *keyboard); err != nil {
		log.Fatal(err)
	}

	chip, err := findChip(*chipLabel)
	if err != nil {
		log.Fatal(err)
	}

	bl := backlight{display: *display, keyboard: *keyboard, brightness: *brightness}

	// Applying the bias moves the line, and the kernel reports that as an
	// edge. Events are stamped from CLOCK_MONOTONIC, so anything older than
	// the request is that artifact rather than a press.
	started, err := monotonic()
	if err != nil {
		log.Fatal(err)
	}

	// The stock rom acts on the first edge and ignores the rest of the bounce
	// rather than waiting for the line to settle, so a short press is never
	// swallowed. Using the timestamp of the edge itself keeps the holdoff
	// independent of how long a toggle takes.
	var last time.Duration
	handler := func(evt gpiocdev.LineEvent) {
		if evt.Timestamp < started {
			return
		}
		if last != 0 && evt.Timestamp-last < *holdoff {
			return
		}
		last = evt.Timestamp
		on, err := bl.toggle()
		if err != nil {
			log.Printf("toggle failed: %v", err)
			return
		}
		log.Printf("backlight %s", map[bool]string{true: "on", false: "off"}[on])
	}

	req, err := gpiocdev.RequestLine(chip, *line,
		gpiocdev.AsInput,
		gpiocdev.WithPullUp,
		edges,
		gpiocdev.WithEventHandler(handler),
	)
	if err != nil {
		log.Fatalf("requesting %s line %d: %v", chip, *line, err)
	}
	defer req.Close()

	log.Printf("watching %s line %d (%s), %s edge", chip, *line, *chipLabel, *edge)

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
}
