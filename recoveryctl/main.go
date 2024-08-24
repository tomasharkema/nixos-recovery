package main

import (
	"os"

	"github.com/alecthomas/kingpin/v2"
	"github.com/tomasharkema/nixos-recovery/recoveryctl/startup"
)

var (
	app = kingpin.New("recoveryctl", "manage recovery things")

	verbose = app.Flag("verbose", "Verbose mode.").Short('v').Bool()

	startupCmd = app.Command("startup", "Reboot into recovery mode")
	now        = startupCmd.Flag("now", "Reboot now").Bool()
)

func main() {
	println("verbose", *verbose)

	switch kingpin.MustParse(app.Parse(os.Args[1:])) {
	// Register user
	case startupCmd.FullCommand():
		startup.Startup(*now)
	}
}
