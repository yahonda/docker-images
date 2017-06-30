#!/bin/bash
# 
# Since: October, 2014
# Author: monica.riccelli@oracle.com
# Description: script to build a Docker image for FMW Infrastructure
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
# 

usage() {
cat << EOF

Usage: buildDockerImage.sh -v [version] [-c]
Builds a Docker Image for Oracle FMW Infrastructure.
  
Parameters:
   -v: version to build. Required.
       Choose one of: $(for i in $(ls -d */); do echo -n "${i%%/}  "; done)
   -c: enables Docker image layer cache during build


LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}

if [ "$#" -eq 0 ]; then usage; fi

# Parameters
VERSION="12.2.1.2"
SKIPMD5=0
NOCACHE=true

while getopts "hcv:" optname; do
case "$optname" in
    "h")
      usage
      ;;
    "c")
      NOCACHE=false
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done


# FMW Infrastructure Image Name
echo $VERSION
IMAGE_NAME="oracle/fmw-infrastructure:$VERSION"

# Go into version folder
cd $VERSION


echo "====================="

# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during build."
fi


# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build --force-rm=$NOCACHE --no-cache=$NOCACHE $PROXY_SETTINGS -t $IMAGE_NAME -f Dockerfile . ||
  echo "There was an error building the image."
  exit 1
}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""

if [ $? -eq 0 ]; then
cat << EOF
  Fusion Middleware Infrastructure Docker Image for version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.

EOF
else
  echo "FMW Infrastructure Docker Image was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi

