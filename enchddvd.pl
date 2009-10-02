#!/usr/bin/perl -w

#########################################
# Converts an mkv into an mpg suitable
# for authoring to an HD-DVD.
#########################################

#$dvd5=4482;
#$dvd9=8147;

sub GetAudioSize()
{
	$audioSize = 0;
	if ($_[0])
	{
		$audioSize = $_[0] * (384 / 8.192);
	}
	$audioSize;
}


$audioSize = &GetAudioSize(1000);
print $audioSize;

