#!/usr/bin/env bash

export PORT=3443
export NODE_ENV="production"

export TLV_USER="user"
export TLV_PASS="pass"

export KEY_PATH="hogehoge.key"
export CRT_PATH="fugafuga.crt"

forever start -c coffee app.coffee
