#!/usr/bin/env bash

export PORT=3443
export NODE_ENV="production"

export TLV_BASIC_AUTH="true"
export TLV_USER="user"
export TLV_PASS="pass"

export TLV_USE_SSL="true"
export TLV_SSL_KEY="hogehoge.key"
export TLV_SSL_CRT="fugafuga.crt"

forever start -c coffee app.coffee
