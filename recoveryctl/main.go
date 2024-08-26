package main

import (
	"context"
	"os"
	"os/signal"

	"github.com/alecthomas/kingpin/v2"
	"github.com/tomasharkema/nixos-recovery/recoveryctl/startup"

	log "github.com/sirupsen/logrus"
)

var (
	app = kingpin.New("recoveryctl", "manage recovery things")

	verbose = app.Flag("verbose", "Verbose mode.").Short('v').Bool()

	startupCmd = app.Command("startup", "Reboot into recovery mode.")
	now        = startupCmd.Flag("now", "Reboot now.").Bool()
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()
	p := kingpin.MustParse(app.Parse(os.Args[1:]))

	if *verbose {
		log.SetLevel(log.DebugLevel)
		log.Infoln("Set verbose mode!")

	} else {
		log.SetLevel(log.WarnLevel)
	}

	switch p {
	case startupCmd.FullCommand():
		log.Infoln("Run startup command...")
		startup.Startup(ctx, *now)
	}
}
