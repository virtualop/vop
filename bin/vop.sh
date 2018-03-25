#!/bin/bash

VOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )

cd $VOP_DIR
bundle exec exe/vop "$*"

cd - >/dev/null
