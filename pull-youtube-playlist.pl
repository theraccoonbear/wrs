#!/usr/bin/perl
use strict;
use warnings;
use URI::Encode qw(uri_encode);
use Web::Scraper;
use WWW::Mechanize;
use Data::Dumper;
use List::Util qw(max min);
use JSON::XS;
use Digest::MD5 qw(md5 md5_hex);
use File::Slurp;
use Text::Unidecode qw(unidecode);
use Text::Levenshtein qw(distance);
use lib "lib";
use WRS;

my $mech = WWW::Mechanize->new(autocheck => 0);
my $wrs = new WRS();

#http://gdata.youtube.com/feeds/api/playlists/PLB-CRhCfD-Fuii5iJMkGOxHLVeAkA3tlI?v=2&alt=json

sub getPlaylist {
	my $p = shift @_;

	my $index = 1;
	my $max_results = 50;
	my $total_results = 10000000;
	my $results_loaded = 0;
	
	my $ret_val = [];
	
	while ($total_results < 0 || $results_loaded < $total_results) {
		my $url = "http://gdata.youtube.com/feeds/api/playlists/$p?v=2&alt=json&max-results=$max_results&start-index=$index";
		
		my $cache_file = 'cache/youtube/' . md5_hex($url) . '.json';
		
		print STDERR "Seeking items $index through " . min($index + $max_results, $total_results) . "...\n";
		
		if (-f $cache_file) {
			print STDERR "...cache hit!\n";
			my $playlist = decode_json(read_file($cache_file));
			$total_results = $playlist->{feed}->{'openSearch$totalResults'}->{'$t'};
							
			foreach my $entry (@{ $playlist->{feed}->{entry} }) {
				push @$ret_val, $entry;
				$results_loaded++;
			}
			
			$index += $max_results;
		} else {
			print STDERR "...Loading from YouTube $url\n";
			$mech->get($url);
			
			if ($mech->success) {
				
				my $raw = $mech->content;
				my $playlist = decode_json($raw);
				write_file($cache_file, $raw);
				
				$total_results = $playlist->{feed}->{'openSearch$totalResults'}->{'$t'};
							
				foreach my $entry (@{ $playlist->{feed}->{entry} }) {
					push @$ret_val, $entry;
					$results_loaded++;
				}
				
				$index += $max_results;
				
			} else {
				print Dumper($mech); exit(0);
			}
		}
	}
	
	return $ret_val;
	
}


my $playlist_id = 'PLB-CRhCfD-Fuii5iJMkGOxHLVeAkA3tlI';
my $playlist = getPlaylist($playlist_id);

print STDERR "\n\n\nCrunching it all...\n\n\n";

foreach my $entry (@{ $playlist }) {
	my $title = $entry->{title}->{'$t'};
	$title =~ s/Woodwright's Shop\s+(.+?)\s+Full\s+Episode/$1/;
	print "Finding episode like \"$title\"\n";
	my $ep = $wrs->bestMatch($title);
	if ($ep->{distance} / length($title) <= 0.25) {
		print "Matched to: s$ep->{ep}->{season}e$ep->{ep}->{number} - $ep->{ep}->{name}\n";
	} else {
		print "Potential match:\n";
		print Dumper($ep);
	}
	
	
	print "\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n";
}