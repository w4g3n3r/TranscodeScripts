#!/bin/sh

#########################################
# Converts an mkv into an mpg suitable
# for authoring to an HD-DVD.
#########################################

if test $# -eq 2
then
  input=$1
  output=`echo $1 | sed 's/mkv/mpg/'`
  
  aspect=16/9
  vbr=$2
  
  vid=vcodec=mpeg2video:vbitrate=$vbr:vrc_maxrate=28950:vrc_buf_size=2867:aspect=$aspect
  aud=acodec=ac3:abitrate=384
  key=vb_strategy=0:vratetol=1000:keyint=18:sc_threshold=500000000:sc_factor=4
  fil=trell:dia=-10:predia=-10:mv0:vqmin=1:lmin=1:cbp:dc=10
  chl=-channels 6 -af channels=6:6:0:0:4:1:1:2:2:3:3:4:5:5
    
  mencoder $input \
    -ofps 24000/1001 \
    -ovc lavc \
    -oac lavc \
    -of mpeg \
    -mpegopts format=dvd:tsaf:vaspect=$aspect:vbitrate=$vbr:muxrate=131072 \
    -vf harddup,scale=1280:720 \
    -lavcopts threads=4:$vid:$key:$fil:$aud \
    -o $output -channels 6 -af channels=6:6:0:0:4:1:1:2:2:3:3:4:5:5

else
  echo "Expected a source file on the command line."  
fi
