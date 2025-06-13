#!/bin/bash
cd /home/rpereira/repo/XSBench/openmp-threading/
./aurora-aml-exp/launch.sh > ./aurora-aml-exp/results-$(hostname).csv
