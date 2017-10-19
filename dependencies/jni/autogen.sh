#!/bin/sh -e

aclocal
libtoolize --install --copy
autoconf
