package PBS::Video;

use Moose;
use strict;
use warnings;

extends 'PBS';

sub getVideoInfo {
	my $self = shift @_;
	my $id = shift @_;
	
	my $url = 'http://video.pbs.org/videoInfo/' . $id . '/?format=json';
	my $resp = $self->pullURL($url);
	my $ret_val = {};
	if ($resp) {
		$ret_val = $self->json->decode($resp);
	}
	
	return $ret_val;
}


1;