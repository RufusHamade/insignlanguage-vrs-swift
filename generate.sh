#!/bin/bash

ROOT_NAME=ISLicon

for i in 20 29 58 87 40 60 80 120 76 152 167 120 180 512 1024; do
  inkscape --export-background=#{background_colour}  --export-png pngs/${ROOT_NAME}_${i}x${i}.png -w $i ${ROOT_NAME}.svgz
done
