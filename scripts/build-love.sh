#!/usr/bin/env bash
mkdir -p release
rm -f release/return-by-death.love
cd game
zip -r ../release/return-by-death.love *
