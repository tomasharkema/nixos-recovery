package main

import (
	"context"
	"os"
	"os/signal"
	"path/filepath"
	"strings"

	"github.com/alecthomas/kingpin/v2"
	"github.com/tomasharkema/nixos-recovery/recoveryctl/launch"

	log "github.com/sirupsen/logrus"
)

var (
	app = kingpin.New("recoveryctl", "manage recovery things")

	verbose = app.Flag("verbose", "Verbose mode.").Short('v').Bool()
	dryRun  = app.Flag("dry-run", "don't execute sideeffects").Bool()
	efiPath = app.Flag("efi-path", "Override the EFI path").Default(`\EFI\recovery.efi`).String()

	launchCmd = app.Command("launch", "Reboot into recovery mode.")
	now       = launchCmd.Flag("now", "Reboot now.").Bool()
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	log.Infoln("args", os.Args)

	parsedCommand := kingpin.MustParse(app.Parse(os.Args[1:]))

	rvn, err := isRunningFromNix()
	if err != nil {
		log.Fatalln(err)
	}

	log.Infoln("Is running from nix", rvn)
	log.Infoln("Is running dryRun", *dryRun)

	if *verbose {
		log.SetLevel(log.DebugLevel)
		log.Infoln("Set verbose mode!")

	} else {
		log.SetLevel(log.WarnLevel)
	}

	log.Infoln("Parsed command", parsedCommand)

	switch parsedCommand {
	case launchCmd.FullCommand():
		log.Infoln("Run startup command...")
		launch.Launch(ctx, *now, *efiPath)
	}
}

func isRunningFromNix() (bool, error) {

	nixStore, succeeded := os.LookupEnv("NIX_STORE")
	if !succeeded {
		log.Infoln("NO NIX_STORE!")
		return false, nil
	}
	log.Infoln("nixStore", nixStore)

	ex, err := os.Executable()
	if err != nil {
		return false, err
	}
	exPath := filepath.Dir(ex)

	log.Infoln("exPath", exPath)

	return strings.HasPrefix(exPath, nixStore), nil
}
