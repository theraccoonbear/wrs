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
use Getopt::Long;

my $mech = WWW::Mechanize->new(autocheck => 0);


my $rename = 0;

GetOptions('rename' => \$rename) or die "error in arguments: $!";

my $show = decode_json(read_file('cache/shows/the-woodwrights-shop.json'));

my $base_dir = 'videos/tmp';

opendir DFH, $base_dir;
my @files = grep { /\.mp[g4]$/; } readdir DFH;
closedir DFH;

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

#An English Garden Wheelbarrow, Pt.1  Woodwright's Shop with Roy UnderHill.mp4

foreach my $f (@files) {
	if ($f =~ m/s\d{2}e\d{2}\s+-\s+(?<name>.+?)\.(?<ext>mp[4g])$/ ||
			$f=~ m/^(?<name>.+?)\s+Woodwright's\s+Shop\s+with\s+Roy\s+UnderHill\.(?<ext>mp[g4])$/ ||
			$f =~ m/^(?<name>.+?)\.(?<ext>mp[g4])$/) {
		my $ep_name = $+{name};
		my $ext = $+{ext};
		my $match = bestMatch($ep_name);
		
		my $season = sprintf('%02d', $match->{ep}->{season});
		my $episode = sprintf('%02d', $match->{ep}->{number});
		#$match->{ep}->{used} = 1;
		
		my $old_name = "$base_dir/$f";
		my $new_name = "$base_dir/The Woodwright's Shop - s${season}e${episode} - $match->{ep}->{name}.$ext";
		
		if ($match->{distance} > 7) {
			print STDERR "Here' an odd one....\n";
			print STDERR "$f\n";
			print STDERR Dumper($match);
			print STDERR "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n";
			
		} else {
			if (-f $new_name) {
				print STDERR "$old_name looks good!\n";
			} else {
				print STDERR $match->{distance} . ' :: ' . unidecode("mv \"$old_name\" \"$new_name\"\n");
				if ($rename) {
					rename $old_name, $new_name;
				}
			}
		}
		
		#print "\"$ep_name\" => \"$match->{ep}->{name}\"\n";
		#print Dumper($match);
		#print "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n";
	}
	
}

