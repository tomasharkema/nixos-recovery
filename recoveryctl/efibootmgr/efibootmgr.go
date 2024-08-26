package efibootmgr

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os/exec"
	"strings"

	log "github.com/sirupsen/logrus"
)

const supportVersionUpTo = 18

func cmd(ctx context.Context, buffer *bytes.Buffer, arg ...string) error {

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

func List(ctx context.Context, efiPath string) (*BootEntry, error) {

	versionSupported := isVersionSupported(ctx)
	log.Infoln("versionSupported", versionSupported)

	if !versionSupported {
		return nil, errors.New("version not supported")
	}

	var buffer bytes.Buffer
	err := cmd(ctx, &buffer)
	if err != nil {
		return nil, err
	}

	lineScanner := NewScanner(&buffer)

	for lineScanner.Scan() {
		entry := lineScanner.Text()
		log.Infoln("Found line:", entry)

		if strings.HasSuffix(entry.Device, efiPath) {
			log.Infoln("Found recovery entry:", entry)
			return &entry, nil
		}

		fileSuffix := fmt.Sprintf("File(%s)", efiPath)
		if strings.HasSuffix(entry.Device, fileSuffix) {
			log.Infoln("Found recovery entry:", entry, fileSuffix)
			return &entry, nil
		}

	}
	return nil, errors.New("no entry found")
}
