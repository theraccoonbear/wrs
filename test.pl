#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use lib 'lib';
use File::Slurp;
use JSON::XS;
use PBS::Video;

my $config = decode_json(read_file('config.json'));

my $pbs = new PBS::Video();

if ($pbs->signin($config->{username}, $config->{password})) {
	
	print Dumper($pbs->mech);
	
	my $id = $pbs->getClientID();
	
	print "$id\n\n";
	
	
	
	#
	#my $info = $pbs->getVideoInfo('2172739971');
	#
	#print Dumper($info);
} else {
	print Dumper($pbs->mech);
	print "Sign in failed";
	
}