#!/bin/env bash

setUp() {

  echo "setup test environment"

}

tearDown() {

  echo "test enviroment tear down"
 
  [ -d ${_TEST} ] && rm -fr ${_TEST}

}


test_fail() {
 assertEquals 1 1

}

# load shunit2
  export SHUNIT2_HOME=/usr/share/shunit2/
. $SHUNIT2_HOME/shunit2
