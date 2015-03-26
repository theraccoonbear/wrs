package PBS;

use Moose;
use strict;
use warnings;
use HTTP::Cookies;
use WWW::Mechanize;
use JSON::XS;
use File::Slurp;
use Data::Dumper;

has 'mech' => (
	is => 'rw',
	isa => 'WWW::Mechanize',
	default => sub {
		my $mech = WWW::Mechanize->new(
			autocheck => 0,
			agent => 'PBS_BOT/0.1',
			cookie_jar => HTTP::Cookies->new( file => "/Users/dsmith/pbs-cookies.txt" ) ,
			onerror => sub {
				print STDERR "WWW::Mechanize ERROR\n";
				print STDERR Dumper(@_);
				exit(0);
			}
		);
		
		#$mech->get('http://');
		return $mech;
	}
);

has 'json' => (
	is => 'rw',
	isa => 'JSON::XS',
	default => sub {
		return JSON::XS->new->ascii->pretty->allow_nonref;
	}
);

sub pullURL {
	my $self = shift @_;
	my $url = shift @_;
	my $default = shift @_ || undef;
	my $opts = shift @_ || {};
	
	if ($opts->{headers}) {
		foreach my $name (keys %{ $opts->{headers} }) {
			$self->mech->add_header($name => $opts->{headers}->{$name});
		}
	}
	
	$self->mech->get($url);
	if ($self->mech->success) {
		return $self->mech->content;
	} else {
		return $default;
	}
}

sub signin {
	my $self = shift @_;
	my $username = shift @_;
	my $password = shift @_;
	
	$self->mech->get('https://account.pbs.org/oauth2/login/');
	
	$self->mech->submit_form(
		form_number => 1,
		with_fields => {
			email => $username,
			password => $password,
			keep_logged_in => 'on'
		}
	);
	
	if ($self->mech->success) {
		#print Dumper($self->mech->content);
		return 1;
	} else {
		return 0;
		#print "poop";
	}
}


sub userdata {
	my $self = shift @_;
	
	my $url = 'http://video.pbs.org/userdata/';
	my $resp = $self->pullURL($url);
	print Dumper($resp);
	exit(0);
}

sub getClientID {
	my $self = shift @_;
	my $url = 'http://video.pbs.org/profile/getClientId/';
	
	my $opts = {
		#headers => {
		#	
		#}
	};
	
	my $resp = $self->pullURL($url, undef, $opts);
	my $id = undef;
	if ($resp) {
		my $data = $self->json->decode($resp);
		print Dumper($data); exit(0);
		$id = $data->{client_id};
	}
	
	return $id;
}

#sub BUILD {
#	my $self = shift @_;
#	$self->userdata();
#}

1;