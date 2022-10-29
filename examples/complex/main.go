/*
Copyright 2022 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"os"

	"github.com/chainguard-dev/terraform-google-prober/pkg/prober"
)

func main() {
	prober.Go(context.Background(), prober.Func(func(ctx context.Context) error {
		if os.Getenv("FOO") != "bar" {
			return errors.New("didn't get expected environment variable FOO=bar")
		}

		// This will cause us to fail roughly 5% of probes!
		if num := rand.Intn(100); num < 5 {
			return fmt.Errorf("failing because we got %d", num)
		}
		return nil
	}))
}
