#! /usr/bin/env bash

#
# Script for install software to the image.
#

set -e # Exit immidiately on non-zero result

echo_stamp() {
  # TEMPLATE: echo_stamp <TEXT> <TYPE>
  # TYPE: SUCCESS, ERROR, INFO

  # More info there https://www.shellhacks.com/ru/bash-colors/

  TEXT="$(date '+[%Y-%m-%d %H:%M:%S]') $1"
  TEXT="\e[1m${TEXT}\e[0m" # BOLD

  case "$2" in
    SUCCESS)
    TEXT="\e[32m${TEXT}\e[0m";; # GREEN
    ERROR)
    TEXT="\e[31m${TEXT}\e[0m";; # RED
    *)
    TEXT="\e[34m${TEXT}\e[0m";; # BLUE
  esac
  echo -e ${TEXT}
}

# https://gist.github.com/letmaik/caa0f6cc4375cbfcc1ff26bd4530c2a3
# https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/templates/header.sh
my_travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n${ANSI_RED}The command \"$@\" failed. Retrying, $count of 3.${ANSI_RESET}\n" >&2
    }
    # ! { } ignores set -e, see https://stackoverflow.com/a/4073372
    ! { "$@"; result=$?; }
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -gt 3 ] && {
    echo -e "\n${ANSI_RED}The command \"$@\" failed 3 times.${ANSI_RESET}\n" >&2
  }

  return $result
}

echo_stamp "Update apt cache"
apt-get update -qq

echo_stamp "Software installing"
apt-get install --no-install-recommends -y \
screen=4.5.0-6 \
byobu=5.112-1  \
nmap=7.40-1 \
lsof=4.89+dfsg-0.1 \
dnsmasq=2.76-5+rpt1+deb9u1  \
tmux=2.3-4 \
git \
cmake \
libboost-system-dev \
libboost-program-options-dev \
libboost-thread-dev \
libreadline-dev\
&& echo_stamp "Everything was installed!" "SUCCESS" \
|| (echo_stamp "Some packages wasn't installed!" "ERROR"; exit 1)

echo_stamp "Clone and build cmavnode" \
&& cd /home/pi \
&& git clone https://github.com/CopterExpress/cmavnode.git \
&& cd cmavnode \
&& git submodule update --init --recursive \
&& mkdir build && cd build && cmake .. && make && make install \
&& systemctl enable cmavnode \
&& echo_stamp "Everything was built!" "SUCCESS" \
|| (echo_stamp "Something went wrong!" "ERROR"; exit 1)

echo_stamp "Change cmavnode repo owner to pi"
chown -Rf pi:pi /home/pi/cmavnode/

echo_stamp "Clean apt cache"
apt-get clean -qq > /dev/null

echo_stamp "End of software installation"
