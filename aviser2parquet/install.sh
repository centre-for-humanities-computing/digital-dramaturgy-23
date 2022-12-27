#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "$(readlink -f -- ${BASH_SOURCE[0]})")

#set -e
#set -x

PROJECT=017

INPUTFOLDER=/projects/p017/aviser
OUTPUTFOLDER=/projects/p017/parquet/aviser.parquet

mvn clean package

rsync -av $SCRIPT_DIR/target/aviser2parquet-*-jar-with-dependencies.jar "${USER}p${PROJECT}@kac-proj-${PROJECT}.kach.sblokalnet:p005-restructure-jar-with-dependencies.jar"

echo "SSH to '${USER}p${PROJECT}@kac-proj-${PROJECT}.kach.sblokalnet' and run the command below"

echo "hadoop jar ~/aviser2parquet-jar-with-dependencies.jar dk.kb.kac.files2parquet_job.ParquetWriteMapReduceJob '${OUTPUTFOLDER}' '${INPUTFOLDER}'"