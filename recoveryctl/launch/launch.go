package launch

import (
	"context"

	log "github.com/sirupsen/logrus"
	"github.com/tomasharkema/nixos-recovery/recoveryctl/efibootmgr"
)

// func bootNext(ctx context.Context, next string) {
// 	efibootmgrCmd(ctx, nil, "-n", next)
// }

func Launch(ctx context.Context, now bool, efiPath string) {

	log.Infoln("launch", "now", now)
	entry, err := efibootmgr.List(ctx, efiPath)

	if err != nil {
		log.Fatalln(err)
	}

	log.Infoln("entry", entry)
	// bootMgr(ctx, "")

}
