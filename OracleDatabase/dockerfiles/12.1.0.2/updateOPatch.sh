#!/bin/bash

# Install the latest OPatch
cd $INSTALL_DIR
unzip -q -o -d $ORACLE_HOME $OPATCH_FILE

# Cleanup
rm -rf $INSTALL_DIR/$OPATCH_FILE
