
# define the exit codes
SUCCESS=0
ERR_UNKNOWN_VI=5
ERR_OTB_BANDMATH=10
ERR_NO_LOCAL=15
ERR_NO_IDENTIFIER=20
ERR_EXTRACT=25
ERR_NO_METADATA=30
ERR_GDAL_TRANSLATE=35
ERR_GDAL_VRT=40
ERR_GDAL_WARP=45

# add a trap to exit gracefully
function cleanExit ()
{
  local retval=$?
  local msg=""
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    ${ERR_UNKNOWN_VI}) msg="Unknown band, no expression defined";;
    ${ERR_OTB_BANDMATH}) msg="OTB failed to process expression";;
    ${ERR_NO_LOCAL}) msg="Couldn't retrieve the Sentinel-2 Level 2A product";;
    ${ERR_NO_IDENTIFIER}) msg="Couldn't identify the Sentinel-2 Level 2A identifier";;
    ${ERR_EXTRACT}) msg="Couldn't extract the Sentinel-2 Level 2A product";;
    ${ERR_NO_METADATA}) msg="Couldn't find the Sentinel-2 Level 2A metadata entry point";;
    ${ERR_GDAL_TRANSLATE}) msg="GDAL failed to convert Sentinel-2 Level 2A product in geotiff";;
    ${ERR_GDAL_VRT}) msg="GDAL failed to create the VRT";;
    ${ERR_GDAL_WARP}) msg="GDAL failed to warp the VRT";;
    ${ERR_PUBLISH}) msg="Failed to publish the result";;
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
}

function setOTBenv() {

  . /etc/profile.d/otb.sh

  export otb_ram=2048
  export GDAL_DATA=/usr/share/gdal/
}

function setGDALEnv() {

  export GDAL_HOME=/opt/gdal-2.1
  export PATH=$GDAL_HOME/bin/:$PATH
  export LD_LIBRARY_PATH=$GDAL_HOME/lib/:$LD_LIBRARY_PATH
  export GDAL_DATA=$GDAL_HOME/share/gdal

}

function calcVegetation() {
  local index=$1
  local s2l2a=$2
  local expression=""

# Band 1: B1, central wavelength 443 nm
# Band 2: B2, central wavelength 490 nm
# Band 3: B3, central wavelength 560 nm
# Band 4: B4, central wavelength 665 nm
# Band 5: B5, central wavelength 705 nm
# Band 6: B6, central wavelength 740 nm
# Band 7: B7, central wavelength 783 nm
# Band 8: B9, central wavelength 945 nm
# Band 9: B11, central wavelength 1610 nm
# Band 10: B12, central wavelength 2190 nm
# Band 11: B8A, central wavelength 865 nm
# Band 12: AOT, Aerosol Optical Thickness map (at 550nm)
# Band 13: CLD, Raster mask values range from 0 for high confidence clear sky to 100 for high confidence cloudy
# Band 14: SCL, Scene Classification
#  Categories:
#       0: NODATA
#       1: SATURATED_DEFECTIVE
#       2: DARK_FEATURE_SHADOW
#       3: CLOUD_SHADOW
#       4: VEGETATION
#       5: BARE_SOIL_DESERT
#       6: WATER
#       7: CLOUD_LOW_PROBA
#       8: CLOUD_MEDIUM_PROBA
#       9: CLOUD_HIGH_PROBA
#      10: THIN_CIRRUS
#      11: SNOW_ICE
# Band 15:  SNW, Raster mask values range from 0 for high confidence NO snow/ice to 100 for high confidence snow/ice
# Band 16:  WVP, Scene-average Water Vapour map

  case $index in
    NDVI)
      # NDVI
      expression=" im1b7 > 0 && im1b7 <= 10000 && im1b4 > 0 && im1b4 <= 10000 && 1000*(( im1b7 - im1b4 ) / ( im1b7 + im1b4 )) <= 1000 && 1000*(( im1b7 - im1b4 ) / ( im1b7 + im1b4 )) >=0  ? 1000*(( im1b7 - im1b4 ) / ( im1b7 + im1b4 )) : -9999 "
      ;;

    NDI45)
      # NDI45
      expression=" im1b5 > 0 && im1b5 <= 10000 && im1b4 > 0 && im1b4 <= 10000 && 1000*(( im1b5 - im1b4 ) / ( im1b5 + im1b4 )) <= 1000 && 1000*(( im1b5 - im1b4 ) / ( im1b5 + im1b4 )) >= 0  ? 1000*(( im1b5 - im1b4 ) / ( im1b5 + im1b4 )) : -9999 "
      ;;
    MTCI)
      # MTCI
      expression=" im1b5 > 0 && im1b5 <= 10000 && im1b4 > 0 && im1b4 <= 10000 && im1b6 > 0 && im1b6 && im1b5 - im1b4 != 0 ? 1000*(( im1b6 - im1b5 ) / ( im1b5 - im1b4 )) : -9999 "
      ;;
   MCARI)
      #MCARI
      expression=" im1b5 > 0 && im1b5 <= 10000 && im1b4 > 0 && im1b4 <= 10000 && im1b3 > 0 && im1b3 <= 10000 ? 1000*((( im1b5 - im1b4 )/10000 - 0.2*( im1b5 - im1b3 )/10000)*( im1b5 - im1b4 ) /10000) : -9999 "
      ;;
   GNDVI)
      #GNDVI
      expression=" im1b7 > 0 && im1b7 <= 10000 && im1b3 > 0 && im1b3 <= 10000 && 1000*(( im1b7 - im1b3 ) / ( im1b7 + im1b3 )) <= 1000 && 1000*(( im1b7 - im1b3 ) / ( im1b7 + im1b3 )) >= 0 ? 1000*(( im1b7 - im1b3 ) / ( im1b7 + im1b3 )) : -9999 "
      ;;
   PSSRa)
      #PSSRa
      expression=" im1b7 > 0 && im1b7 <= 10000 && im1b4 > 0 && im1b4 <= 10000 && im1b4 != 0 ? 1000*(im1b7 / im1b4) : -9999 "
      ;;
   S2REP)
      #S2REP
      expression=" im1b7 > 0 && im1b7 <= 10000 && im1b4 >= 0 && im1b4 <= 10000 && im1b5 >= 0 && im1b5 <= 10000 && im1b6 >= 0 && im1b6 <= 10000 ? 1000*(705 + 35*(((( im1b7 + im1b4 ) / ( 2*10000 ) - im1b5 / 10000 ) / ( im1b6 - im1b5 ) /10000)))  : -9999 "
      ;;
   IRECI)
     #IRECI
     expression=" im1b7 >= 0 && im1b7 <= 10000 && im1b4 >= 0 && im1b4 <= 10000 && im1b6 >= 0 && im1b6 <= 10000 && im1b6 != 0 && im1b5 != 0 ? 1000*((( im1b7 - im1b4 )/10000) / ( im1b5 / im1b6 )) : -9999 "
     ;;
   CLD)
     # Raster mask values range from 0 for high confidence clear sky to 100 for high confidence cloudy
     # this is not a vegetation index
     expression=" im1b13 "
     ;;
   SCL)
     # Scene Classification
     # this is not a vegetation index
     expression=" im1b14 "
     ;;
   SNW)
     # Raster mask values range from 0 for high confidence NO snow/ice to 100 for high confidence snow/ice
     # this is not a vegetation index
     expression=" im1b15 "
     ;;
   WVP)
     # Scene-average Water Vapour map
     # this is not a vegetation index
     expression=" im1b16 / 10"
     ;;
  *)
     return ${ERR_UNKNOWN_VI}
     ;;
  esac

  otbcli_BandMath \
    -il ${s2l2a}.TIF \
    -exp ${expression} \
    -out ${s2l2a}_${index}.TIF 1> /dev/null || return ${ERR_OTB_BANDMATH}

}


function updateVRTMetadata() {

  local vrt=$1

   xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="1"]/NoDataValue" \
     -t elem -n "Description" -v "Normalised Difference Vegetation Index (NDVI) expression: (NIR - R)/(NIR + R) i.e. (B7 - B4)/(B7 + B4)" \
     ${vrt}

   xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="2"]/NoDataValue" \
     -t elem -n "Description" -v "Normalised Difference Vegetation Index with bands 4 and 5 (NDI45) expression: (NIR - R)/(NIR + R) i.e. (B5 - B4)/(B5 + B4) " \
     ${vrt}

   xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="3"]/NoDataValue" \
     -t elem -n "Description" -v "MERIS Terrestrial Chlorophyll Index (MTCI) expression: (NIR - RE)/(RE - R) i.e. (B6 - B5)/(B5 - B4) " \
     ${vrt}

   xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="4"]/NoDataValue" \
     -t elem -n "Description" -v "Modified Chlorophyll Absorption in Reflectance Index (MCARI) expression: [(RE - R) - 0.2 x (RE - G)] x (RE - R) i.e. [(B5 - B4) -  0.2 x (B5 - B3)] x (B5 - B4)" \
     ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="5"]/NoDataValue" \
     -t elem -n "Description" -v "Green Normalised Difference Vegetation Index (GNDVI) expression: (NIR - G)/(NIR + G) i.e. (B7 - B3)/(B7 + B3)" \
     ${vrt}

 xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="6"]/NoDataValue" \
     -t elem -n "Description" -v "Pigment Specific Simple Ratio (PSSRa) expression: NIR/R i.e. B7/B4" \
     ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="7"]/NoDataValue" \
     -t elem -n "Description" -v "Sentinel-2 red-edge position (S2REP) expression: 705 + 35 x ((((NIR + R)/2) - RE1)/(RE2 - RE1)) i.e. 705 + 35 x ((((B7 + B4)/2) - B5)/(B6 - B5))" \
     ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="8"]/NoDataValue" \
     -t elem -n "Description" -v "Inverted Red-Edge Chlorophyll Index (IRECI) expression: (NIR - R)/(RE1/RE2) i.e. (B7 - B4)/(B5/B6)" \
     ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="9"]/NoDataValue" \
     -t elem -n "Description" -v "Raster mask values range from 0 for high confidence clear sky to 100 for high confidence cloudy" \
     ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="10"]/NoDataValue" \
     -t elem -n "Description" -v "Scene Classification" \
     ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="11"]/NoDataValue" \
    -t elem -n "Description" -v "Raster mask values range from 0 for high confidence NO snow/ice to 100 for high confidence snow/ice" \
    ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand[@band="12"]/NoDataValue" \
    -t elem -n "Description" -v "Scene-average Water Vapour map" \
    ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand" --type elem -n "Metadata" -v "" ${vrt}

  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand/NoDataValue" --type elem -n "ColorInterp" -v "Gray" ${vrt}
  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand/NoDataValue" --type elem -n "Offset" -v "0.0" ${vrt}
  xmlstarlet ed -L -a "/VRTDataset/VRTRasterBand/NoDataValue" --type elem -n "Scale" -v "1.0" ${vrt}


}

function updateMetadataField() {
set -x
  local target_xml="$1"
  local target_xpath="$2"
  local value="$3"
 
  [ ! -z "$4" ] && { 
    # the value comes from the Sentinel-2 Level 2A XML file
    local source_xpath="$3"
    local source_xml="$4" 

    local namespace="https://psd-13.sentinel2.eo.esa.int/PSD/User_Product_Level-2A.xsd"
    xmlstarlet ed -L \
     -u "${target_xpath}" \
     -v "$( xmlstarlet sel -N x="${namespace}" -t -v "${source_xpath}" ${source_xml} )" \
     ${target_xml} 
  } || {
    # a simple value is used
    xmlstarlet ed -L \
     -u "${target_xpath}" \
     -v "${value}" \
     ${target_xml} 

  }
 set +x  
}



function updateMetadata() {

  local source_xml="$1"
  local target_xml="$2"

  # copy the template locally
  cp /application/sen2vi/etc/eop_template.xml ${target_xml}

  # update time coverage
  updateMetadataField \
   ${target_xml} \
   "//EarthObservation/phenomenonTime/TimePeriod/beginPosition" \
   "//x:Level-2A_User_Product/x:General_Info/L2A_Product_Info/PRODUCT_START_TIME" \
   ${source_xml}
 
  updateMetadataField \
   ${target_xml} \
   "//EarthObservation/phenomenonTime/TimePeriod/endPosition" \
   "//x:Level-2A_User_Product/x:General_Info/L2A_Product_Info/PRODUCT_STOP_TIME" \
   ${source_xml}

  # TODO add cloud coverage target
  #updateMetadataField \
  # ${source_xml} \
  # ${target_xml} \
  # "//x:Level-2A_User_Product/x:Quality_Indicators_Info/Cloud_Coverage_Assessment" \
  # "/"

  updateMetadataField \
   ${target_xml} \
   "//EarthObservation/metaDataProperty/EarthObservationMetaData/identifier" \
   "${l2b_identifier}_${counter}" 

  #updateMetadataField \
  # ${target_xml} \
  # "${l2b_identifier}_${counter}" \
  # "//EarthObservation/metaDataProperty/EarthObservationMetaData/parentIdentifier" 
  
  updateMetadataField \
    ${target_xml} \
    "//EarthObservation/metaDataProperty/EarthObservationMetaData/productType/" \
    "S2MSI2Bp" 

   updateMetadataField \
    ${target_xml} \
    "//EarthObservation/metaDataProperty/EarthObservationMetaData/processing/ProcessingInformation/processingCenter" \
    "Terradue Cloud Platform"
}



