package WRS;

use Moose;

use strict;
use warnings;
use Data::Dumper;
use JSON::XS;
use File::Slurp;
use Text::Levenshtein qw(distance);

my $show = decode_json(read_file('cache/shows/the-woodwrights-shop.json'));


#print Dumper($show); exit(0);

sub bestMatch {
	my $self = shift @_;
	my $ep_name = shift @_;
	
	my $best = {
		distance => 1000000000,
		ep => {}
	};
	
	foreach my $s_num (sort keys %{ $show->{seasons} }) {
		my $s = $show->{seasons}->{$s_num};
		foreach my $e_num (sort keys %{ $s->{episodes} }) {
			my $e = $s->{episodes}->{$e_num};
			my $d = distance($e->{name}, $ep_name);
			#print STDERR "Checking \"$ep_name\" against \"$e->{name}\" : $d\n";
			if ($d < $best->{distance}) {
				$best->{distance} = $d;
				$best->{ep} = $e;
				if ($d == 0) {
					last;
				}
			}
		}
	}
	return $best;
}

#my $ep = bestMatch($name);


1;