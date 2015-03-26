#!/usr/bin/perl
use strict;
use warnings;
use URI::Encode qw(uri_encode);
use Web::Scraper;
use WWW::Mechanize;
use Data::Dumper;
use JSON::XS;
use File::Slurp;
use Text::Unidecode qw(unidecode);
use Text::Levenshtein qw(distance);

if (scalar @ARGV < 1) {
	print "Usage: best-match.pl <episode-name>\n\n";
	exit(1);
}

my $name = join(' ', @ARGV);

my $show = decode_json(read_file('cache/shows/the-woodwrights-shop.json'));


sub bestMatch {
	my $ep_name = shift @_;
	
	my $best = {
		distance => 1000000000,
		ep => {}
	};
	
	foreach my $s_num (sort keys %{ $show->{seasons} }) {
		my $s = $show->{seasons}->{$s_num};
		foreach my $e_num (sort keys %{ $s->{episodes} }) {
			my $e = $s->{episodes}->{$e_num};
			if (!$e->{used}) {
				my $d = distance($e->{name}, $ep_name);
				if ($d < $best->{distance}) {
					$best->{distance} = $d;
					$best->{ep} = $e;
				}
			}
		}
	}
	return $best;
}

my $ep = bestMatch($name);
print Dumper($ep);
