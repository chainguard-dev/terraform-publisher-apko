/*
Copyright 2022 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"context"
	"log"

	"github.com/chainguard-dev/terraform-google-prober/pkg/prober"
)

func main() {
	prober.Go(context.Background(), prober.Func(func(ctx context.Context) error {
		log.Print("Got a probe!")
		return nil
	}))
}
