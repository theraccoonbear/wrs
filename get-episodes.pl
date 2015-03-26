#!/usr/bin/perl
use strict;
use warnings;
use URI::Encode qw(uri_encode);
use Web::Scraper;
use WWW::Mechanize;
use Data::Dumper;
use JSON::XS;
use File::Slurp;
use Text::Levenshtein qw(distance);
use Getopt::Long;

my $mech = WWW::Mechanize->new(autocheck => 0);

my $show_search_scraper = scraper {
	process "//table[\@id='listtable']/tr[position() > 1]", 'shows[]' => scraper {
		process '//td[1]/a', 'name' => 'TEXT';
		process '//td[2]', 'lang' => 'TEXT';
		process '//td[3]', 'id' => 'TEXT';
	};
};

my $season_list_scraper = scraper {
	process '//div[@id=\'content\']/a', 'seasons[]' => 'TEXT';
};

my $episode_list_scraper = scraper {
	process "//table[\@id='listtable']/tr[position() > 1]", 'episodes[]' => scraper {
		process '//td[1]/a', 'season_ep_num' => 'TEXT', 'url' => '@href';
		process '//td[2]/a', 'name' => 'TEXT';
		process '//td[3]', 'air_date' => 'TEXT';
	};
};

sub dbg {
	my $msg = shift @_;
	print STDERR "-- $msg\n";
}

sub findShowByName {
	my $name = shift @_;
	
	my $url = 'http://thetvdb.com/?string=' . uri_encode($name) . '&searchseriesid=&tab=listseries&function=Search';
	$mech->get($url);
	
	my $ret_val = {dist => 100000000};
	if ($mech->success) {
		my $results = $show_search_scraper->scrape($mech->content);
		foreach my $r (@{$results->{shows}}) {
			$r->{name} =~ s/^\s*(.+?)\s*$/$1/;
			$r->{lang} =~ s/^\s*(.+?)\s*$/$1/;
			if (lc($r->{lang}) eq 'english') {
				$r->{dist} = distance($r->{name}, $name);
				if ($r->{dist} < $ret_val->{dist}) {
					$ret_val = $r;
				}
				
				if ($r->{dist} == 0) {
					last;
				}
			}
		}
	}
	
	return $ret_val;
} # findShowByName()

sub getSeasonInfo {
	my $show_id = shift @_;
	
	#my $url = 'http://thetvdb.com/?tab=series&id=' . $show_id . '&lid=7';
	my $url = 'http://thetvdb.com/?tab=seasonall&id=' . $show_id . '&lid=7';
	
	$mech->get($url);
	my $ret_val = {};
	if ($mech->success) {
		#my $results = $season_list_scraper->scrape($mech->content);
		my $results = $episode_list_scraper->scrape($mech->content);
		my $seasons = {};
		foreach my $ep (@{ $results->{episodes} }) {
			my($s_num, $e_num) = split(/\s+x\s+/, $ep->{season_ep_num});
			my($junk, $qs) = split(/\?/, $ep->{url});
			
			my @q_params = split(/&/, $qs);
			my $qsp = {};
			foreach my $nvp (@q_params) {
				my($n, $v) = split(/=/, $nvp);
				$qsp->{$n} = $v;
			}
			
			
			if (! defined $seasons->{$s_num}) {
				$seasons->{$s_num} = {
					id => $qsp->{seasonid},
					episodes => {}
				};
			}
			
			$ep->{season} = $s_num;
			$ep->{id} = $qsp->{id};
			$ep->{number} = $e_num;
			delete $ep->{season_ep_num};
			
			$seasons->{$s_num}->{episodes}->{$e_num} = $ep;
		}
		$ret_val = $seasons;
	}
	
	return $ret_val;
} # getSeasonInfo()

my $show_name = "The Woodwright's Shop";

GetOptions('show=s' => \$show_name);

my $csn = lc($show_name);
$csn =~ s/'//g;
$csn =~ s/[^A-Za-z0-9]+/-/g;

my $show = findShowByName($show_name);

print Dumper($show);

my $seasons = getSeasonInfo($show->{id});

$show->{seasons} = $seasons;

print Dumper($seasons);

write_file("cache/shows/" . $csn . ".json", encode_json($show));