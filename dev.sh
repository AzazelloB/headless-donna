#!/usr/bin/env bash

OUT_DIR="build/dev"

mkdir -p $OUT_DIR

odin run src -out:$OUT_DIR/headless-donna.exe "$@"
