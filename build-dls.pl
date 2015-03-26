#!/usr/bin/perl
use strict;
use warnings;
use File::Slurp;
use JSON::XS;
use Data::Dumper;
use Text::Unidecode;

opendir DFH, 'cache';
my @FILES = readdir DFH;
closedir DFH;


my $DLs = {};

my $SBY = {};

foreach my $f (@FILES) {
	$f = "cache/$f";
	if ($f =~ m/\.json$/) {
		my $ep = decode_json(read_file($f));
		
		my @ADP = split(/\//, $ep->{air_date});
		#print $ep->{title} . ' = ' . $ep->{air_date} . "\n";
		my $m = 1 * $ADP[0];
		my $d = 1 * $ADP[1];
		my $y = 1 * $ADP[2];
		
		if (! defined $SBY->{$y}) {
			$SBY->{$y} = {};
		}
		
		my $md = sprintf('%02d', $m) . sprintf('%02d', $d);

		
		$SBY->{$y}->{$md} = {
			ep => $ep,
			url => $ep->{alternate_encoding}->{url},
			season => sprintf('%02d', ($ADP[2] - 1980)),
			name => "s" . sprintf('%02d', ($ADP[2] - 1980)) . 'eXXX - ' . $ep->{title} . '.mpg'
		};
	}
	
}

my @DLs = ();

foreach my $year (sort keys %{ $SBY }) {
	my $ep_num = 0;
	foreach my $mon_day (sort keys %{ $SBY->{$year} }) {
		my $ep = $SBY->{$year}->{$mon_day};
		$ep_num++;
		my $title = unidecode($ep->{ep}->{title});
		$title =~ s/[^A-Za-z0-9\.\s\,\']+//gi;
		my $file_name = "videos/The Woodwright's Shop - s" . ($ep->{season}) . 'e' . sprintf('%02d', $ep_num) . ' - ' . $title . ".mpg";
		my $command = "wget -O \"$file_name\" $ep->{url}";
		push @DLs, $command;
	}
}

print Dumper(\@DLs);
write_file('download-videos.sh', join("\n", @DLs));