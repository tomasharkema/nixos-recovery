package startup

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os/exec"
)

func bootMgr(ctx context.Context, arg ...string) {
	var buffer bytes.Buffer

	cmd := exec.CommandContext(ctx, "efibootmgr", arg...)

	cmd.Stdout = &buffer
	// cmd.Stderr = &buffer

	err := cmd.Run()

	if err != nil {
		println("ERROR!", err)
		log.Fatalln(err)
		return
	}

	lineScanner := NewScanner(&buffer)

	for lineScanner.Scan() {
		txt := lineScanner.Text()

		fmt.Println("line", txt)

	}

	// println(records)
}

func bootNext(ctx context.Context, next string) {
	bootMgr(ctx, "-n", next)
}

func bootList(ctx context.Context) {
	bootMgr(ctx)
}

func Startup(now bool) {
	ctx := context.Background()

	println("startup")
	bootList(ctx)
	// bootMgr(ctx, "")

}
