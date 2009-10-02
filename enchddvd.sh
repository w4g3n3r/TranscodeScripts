#!/bin/sh

#########################################
# Converts an mkv into an mpg suitable
# for authoring to an HD-DVD.
#########################################

dvd5=4482
dvd9=8147

Calc()
{
	return `scale=2; $1 | bc -l`
}

GetAudioSize()
{
	if [ $1 -ne "" ] ; then
		Calc "$1 * (384 / 8.192)"		
		return $?
	fi
	return 0
}


GetAudioSize 1000
echo $?

if [ $# -eq 2 ] ; then
  input=$1
  
  if [ $2 -gt 24000 ] ; then
  	$2 = 24000
	fi
	
  lavcoptsVbr=$2
  mpegoptsVbr=$2
  
  if [$lavcoptsVbr -gt 16000] ; then
  	$lavcoptsVbr *= 1000
	fi
  
  output="$input.mpg"
  
  aspect=16/9
  
  vid=vcodec=mpeg2video:vbitrate=$lavcoptsVbr:vrc_maxrate=28950:vrc_buf_size=2867:aspect=$aspect
  aud=acodec=ac3:abitrate=384
  key=vb_strategy=0:vratetol=1000:keyint=18:sc_threshold=500000000:sc_factor=4
  fil=trell:dia=-10:predia=-10:mv0:vqmin=1:lmin=1:cbp:dc=10
  chl=-channels 6 -af channels=6:6:0:0:4:1:1:2:2:3:3:4:5:5
    
  mencoder $input \
    -ofps 24000/1001 \
    -ovc lavc \
    -oac lavc \
    -of mpeg \
    -mpegopts format=dvd:tsaf:vaspect=$aspect:vbitrate=$mpegoptsVbr:muxrate=131072 \
    -vf harddup,scale=1280:720 \
    -lavcopts threads=4:$vid:$key:$fil:$aud \
    -o $output -channels 6 -af channels=6:6:0:0:4:1:1:2:2:3:3:4:5:5

else
  echo "Expected a source file on the command line."  
fi
