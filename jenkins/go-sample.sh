#!/bin/bash
set -e -x

cat > test.go <<EOF
package main

import (
    "fmt"
)

func main() {
    fmt.Println("Hello, playground")
}
EOF

export GOPATH=$WORKSPACE
export PATH=$PATH:$GOPATH/bin

go get github.com/tools/godep
go run test.go
