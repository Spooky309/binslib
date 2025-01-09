#!/bin/sh

[ ! -d build ] && mkdir build

odin build test_program -debug -sanitize:address -out:build/test_program
