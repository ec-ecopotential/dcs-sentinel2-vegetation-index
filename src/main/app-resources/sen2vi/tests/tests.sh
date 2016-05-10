#!/bin/env bash

setUp() {

  echo "setup test environment"

  export SHUNIT2_HOME=/usr/share/shunit2/
  # make sure set -x is not on
  set +x 

  export _ROOT=$(dirname $0)
  mkdir -p ${_ROOT}/runtime
  export _TEST=${_ROOT}/runtime
  export _ARTIFACT=${_ROOT}/artifacts

  # source libs
  . ${_ROOT}/../lib/functions.sh
}

tearDown() {

  echo "test enviroment tear down"
 
  [ -d ${_TEST} ] && rm -fr ${_TEST}

}

test_updateMetadataField_value() {
  
  # test first function signature 
  local target_xml=${_TEST}/eop_instance.xml

  cp ${_ROOT}/../etc/eop_template.xml ${target_xml}   
 
  updateMetadataField \
    ${target_xml} \
    "//EarthObservation/metaDataProperty/EarthObservationMetaData/productType" \
    "S2MSI2Bp"

  value="$( xmlstarlet sel -t -v "//EarthObservation/metaDataProperty/EarthObservationMetaData/productType" ${target_xml} )" 

  assertEquals "S2MSI2Bp" "${value}"

}


test_updateMetadataField_xpath() {

  # test second function signature
  local target_xml=${_TEST}/eop_instance.xml
  local source_xml=${_ROOT}/artifacts/S2A_USER_PRD_MSIL2A_PDMC_20160209T011325_R008_V20160208T104841_20160208T104841.SAFE/S2A_USER_MTD_SAFL2A_PDMC_20160209T011325_R008_V20160208T104841_20160208T104841.xml

  cp ${_ROOT}/../etc/eop_template.xml ${target_xml}

  updateMetadataField \
   ${target_xml} \
   "//EarthObservation/phenomenonTime/TimePeriod/beginPosition" \
   "//x:Level-2A_User_Product/x:General_Info/L2A_Product_Info/PRODUCT_START_TIME" \
   ${source_xml}

  value="$( xmlstarlet sel -t -v "//EarthObservation/phenomenonTime/TimePeriod/beginPosition" ${target_xml} )"

  assertEquals "2016-02-08T10:48:41.464Z" "${value}"

}

test_updateMetadata() {

  local target_xml=${_TEST}/eop_instance.xml
  local source_xml=${_ROOT}/artifacts/S2A_USER_PRD_MSIL2A_PDMC_20160209T011325_R008_V20160208T104841_20160208T104841.SAFE/S2A_USER_MTD_SAFL2A_PDMC_20160209T011325_R008_V20160208T104841_20160208T104841.xml
  
  cp ${_ROOT}/../etc/eop_template.xml ${target_xml}

  # set the variables
  l2b_identifier="S2A_USER_PRD_MSIL2B_PDMC_20160209T011325_R008_V20160208T104841_20160208T104841"
  counter=0

  updateMetadata \
    ${source_xml} \
    ${target_xml}

  assertEquals "" "$(diff ${_TEST}/eop_instance.xml ${_ARTIFACT}/eop_target.xml)"

} 

test_fail() {
 assertEquals 1 1

}

# load shunit2
  export SHUNIT2_HOME=/usr/share/shunit2/
. $SHUNIT2_HOME/shunit2
