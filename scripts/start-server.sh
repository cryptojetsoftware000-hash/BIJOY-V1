#!/usr/bin/env bash

set -e

cd "$(dirname "$0")/../server"

npm install
npm start
