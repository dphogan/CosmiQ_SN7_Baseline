#!/bin/bash

echo Test
cd $(dirname "$0")
source activate solaris
time python src/sn7_test_prep.py $1 output/test
time python test.py
time python src/sn7_extract.py $1 $2
