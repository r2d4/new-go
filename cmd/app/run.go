package app

import (
	"os"

	"matt-rickard.com/new-go/cmd/app/cmd"
)

func Run() error {
	c := cmd.NewRootCommand(os.Stdout, os.Stderr)
	return c.Execute()
}
