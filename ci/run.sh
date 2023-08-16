#!/bin/bash

# This script runs site checks in parallel and produces a rough and ready markdown table showing which features we can lean on to render sites without using a full html rendering engine

cat sites | parallel -j 64 ./check.lua {} >> ../results.md
