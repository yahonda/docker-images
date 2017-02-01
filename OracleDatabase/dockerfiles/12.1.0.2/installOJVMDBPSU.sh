#!/bin/bash

# Install the latest OPatch
cd $ORACLE_HOME
unzip -q -o -d $ORACLE_HOME $COMBO_OJVM_DBPSU_FILE

# DBPSU
cd $ORACLE_HOME/24433133/24006101
$ORACLE_HOME/OPatch/opatch apply -silent

# Cleanup
cd $ORACLE_HOME
rm -rf $COMBO_OJVM_DBPSU_FILE
