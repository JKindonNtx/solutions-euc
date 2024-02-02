#!/bin/bash
 
trap "echo Exited!; exit;" SIGINT SIGTERM
while [[ 1=1 ]]
do
  zip -FSr scenario.zip $1
  sleep 10
done
