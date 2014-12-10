#!/bin/sh
set -x
sed -i 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers

