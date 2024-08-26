package startup

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os/exec"
)

func bootMgr(ctx context.Context, buffer *bytes.Buffer, arg ...string) error {

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

func bootList(ctx context.Context) error {
	var buffer bytes.Buffer
	err := bootMgr(ctx, &buffer)

	if err != nil {
		return err
	}

	lineScanner := NewScanner(&buffer)

	for lineScanner.Scan() {
		txt := lineScanner.Text()
		fmt.Println("line", txt)
	}
	return nil
}

func Startup(ctx context.Context, now bool) {

	println("startup")
	err := bootList(ctx)

	if err != nil {
		log.Fatalln(err)
	}
	// bootMgr(ctx, "")

}
