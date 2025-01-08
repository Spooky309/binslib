#!/bin/sh

[ ! -d build ] && mkdir build

odin build test_program -debug -out:build/test_program
