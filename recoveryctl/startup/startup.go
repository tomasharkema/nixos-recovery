package startup

import (
	"bytes"
	"context"
	"errors"
	"strings"

	"os/exec"

	log "github.com/sirupsen/logrus"
)

func bootMgr(ctx context.Context, buffer *bytes.Buffer, arg ...string) error {

	log.Infoln("Execute efibootmgr", arg)

	cmd := exec.CommandContext(ctx, "efibootmgr", arg...)

	if buffer != nil {
		buf := buffer
		cmd.Stdout = buf
	}
	// cmd.Stderr = &buffer

	err := cmd.Run()

	if err != nil {
		return err
	}
	return nil
	// println(records)
}

func bootNext(ctx context.Context, next string) {
	bootMgr(ctx, nil, "-n", next)
}

func bootList(ctx context.Context) (*BootEntry, error) {
	var buffer bytes.Buffer
	err := bootMgr(ctx, &buffer)

	if err != nil {
		return nil, err
	}

	lineScanner := NewScanner(&buffer)

	for lineScanner.Scan() {
		entry := lineScanner.Text()
		log.Infoln("Found line:", entry)

		if strings.HasSuffix(entry.Device, `\EFI\recovery.efi`) {
			log.Infoln("Found recovery entry:", entry)
			return &entry, nil
		}
	}
	return nil, errors.New("no entry found")
}

func Startup(ctx context.Context, now bool) {

	log.Infoln("startup", "now", now)
	entry, err := bootList(ctx)

	if err != nil {
		log.Fatalln(err)
	}

	log.Infoln("entry", entry)
	// bootMgr(ctx, "")

}
