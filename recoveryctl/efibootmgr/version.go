package efibootmgr

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"regexp"
	"strconv"

	log "github.com/sirupsen/logrus"
)

var versionRegex = regexp.MustCompile(`version (.*)`)

func Version(ctx context.Context) (int, error) {
	var buffer bytes.Buffer
	err := cmd(ctx, &buffer, "--version")
	if err != nil {
		return 0, err
	}

	lineScanner := bufio.NewScanner(&buffer)
	if !lineScanner.Scan() {
		return 0, errors.New("not found line")
	}

	l := lineScanner.Text()
	result := versionRegex.FindStringSubmatch(l)
	if len(result) < 2 {
		return 0, errors.New("Could not parse version...")
	}
	versionString := result[1]
	log.Infoln("found version", versionString)

	versionInt, err := strconv.Atoi(versionString)
	if err != nil {
		return 0, err
	}
	log.Infoln("found version int", versionInt)
	return versionInt, nil
}

func isVersionSupported(ctx context.Context) bool {
	version, err := Version(ctx)
	if err != nil {
		log.Errorln("Encountered version error", err)
		return false
	}

	return version <= supportVersionUpTo
}
