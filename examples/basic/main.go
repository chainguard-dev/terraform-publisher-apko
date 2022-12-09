/*
Copyright 2022 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"context"
	"log"
	"os"

	"github.com/chainguard-dev/terraform-google-prober/pkg/prober"
)

func main() {
	prober.Go(context.Background(), prober.Func(func(ctx context.Context) error {
		honk := os.Getenv("EXAMPLE_ENV")
		if honk == "" {
			log.Fatal("Expected EXAMPLE_ENV environment variable to be configured.")
		}
		log.Printf("Got a probe with special env var %s!", honk)
		return nil
	}))
}
