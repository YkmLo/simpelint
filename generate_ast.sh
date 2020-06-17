#!/bin/bash

xcrun swiftc -frontend -emit-syntax $@ | python -m json.tool > ast.json