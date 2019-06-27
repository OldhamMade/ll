#/bin/bash

echo "Configuring Nim"
source $HOME/.asdf/asdf.sh
source $HOME/.asdf/completions/asdf.bash
asdf global nim v0.20.0

echo "Starting test run"
export NIM_LIB_PREFIX=$HOME/.asdf/installs/nim/v0.20.0
nimble build -y --nilseqs:on && nimble test -y
