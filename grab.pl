#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper;
use WWW::Mechanize;
use Data::Dumper;
use JSON::XS;
use File::Slurp;

my $mech = WWW::Mechanize->new(autocheck => 0);

my $ep_pg_scraper = scraper {
	process 'li.videoItem', 'items[]' => scraper {
		process 'a[data-videoid]', 'id' => '@data-videoid', 'title' => '@data-title';
	};
};

my $ep_view_scraper = scraper {
	process '#pageDescription', 'details' => scraper {
		process 'li.airDate', 'air_date' => 'TEXT';
		process '#description', 'description' => 'TEXT';
	};
};

sub dbg {
	my $msg = shift @_;
	print STDERR "-- $msg\n";
}

sub getEpisodeListPage {
	my $page = shift @_;
	
	my $url = 'http://video.pbs.org/program/woodwrights-shop/episodes/?page=' . $page;
	$mech->get($url);
	
	if ($mech->success) {
		return $mech->content;
	} else {
		return undef;
	}
} # getEpisodeListPage

sub getEpisodeViewPage {
	my $id = shift @_;
	my $url = 'http://video.pbs.org/video/' . $id . '/';
	$mech->get($url);
	
	if ($mech->success) {
		return $mech->content;
	} else {
		return undef;
	}
} # getEpisodeViewPage()

sub getEpisodeJSON {
	my $id = shift @_;
	
	my $url = 'http://video.pbs.org/videoInfo/' . $id . '/?callback=video_info&format=json';
	
	$mech->get($url);
	if ($mech->success) {
		return $mech->content;
	} else {
		return '{}';
	}
} # getEpisodeJSON()


my $DL_list = {};


my $page;
for (my $i = 5; $i >= 1; $i--) {
	dbg "Pulling page $i of episode listing.";
	if ($page = getEpisodeListPage($i)) {
		my $eps = $ep_pg_scraper->scrape($page);
		dbg 'Found ' . (scalar @{$eps->{items}}) . ' episode(s) on page.';
		foreach my $ep (@{$eps->{items}}) {
		
			my $ep_cache_file = 'cache/'. $ep->{id} . '.json';
			my $raw_json = '{}';
			my $ep_json;
			if (! -f $ep_cache_file) {
				dbg "Pulling metadata for \"$ep->{title}\" ($ep->{id}).";
				$raw_json = getEpisodeJSON($ep->{id});
				
				dbg "Pulling view page for $ep->{id}.";
				my $view_page = getEpisodeViewPage($ep->{id});
				my $cnt = 0;
				while (! defined $view_page && $cnt++ < 5) {
					sleep 1;
					dbg "retrying...";
					$view_page = getEpisodeViewPage($ep->{id});
				}
				
				my $view = $ep_view_scraper->scrape($view_page);
				$ep_json->{air_date} = $view->{details}->{air_date};
				$ep_json->{description} = $view->{details}->{description};
				$view->{details}->{air_date} =~ s/Aired:\s+//;
				
				
				#print Dumper($raw_json);
				$ep_json = decode_json($raw_json);
				
			} else {
				dbg "Using cached metadata for \"$ep->{title}\" ($ep->{id}).";
				$raw_json = read_file($ep_cache_file);
				$ep_json = decode_json($raw_json);
			}
			
			$ep_json->{clean_title} = lc($ep->{title});
			$ep_json->{clean_title} =~ s/[^A-Za-z0-9]+/-/g;
			
			
			
			write_file($ep_cache_file, encode_json($ep_json));
			
			#print Dumper($ep_json);
		}
	} else {
		print "\n\nCouldn't pull page $i\n\n";
	}
}