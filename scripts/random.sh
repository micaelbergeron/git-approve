#!/bin/bash

R=$RANDOM
echo $R:$(md5sum <<< $R | cut -d' ' -f1)
