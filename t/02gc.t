#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok("Tie::RefHash::Weak") }

sub Tie::RefHash::Weak::cnt {
	my $s = shift;
	scalar keys %{ $s->[0] }
}

my @types = (
	sub { my $v = shift; \$v },
	sub { [ $_[0] ] },
	sub { { value => $_[0] } },
);

my $n = 10; # create a large hunk of 

tie my %hash, 'Tie::RefHash::Weak'; my @copies;
%hash = map { $_ => 1 } @copies = map {bless new_ref($_), "Some::Class"} 1 .. 1 << $n;

sub new_ref {
	my $v = shift;
	push @types, my $h = shift @types;
	$h->( $v );
}

is(scalar keys %hash, 1 << $n, "scalar keys");
is((tied %hash)->cnt, 1 << $n, "cnt");

splice(@copies, 0, 1 << ($n-1)); # throw some away

is((tied %hash)->cnt, 1 << ($n-1), "cnt");
is(scalar keys %hash, 1 << ($n-1), "scalar keys");

splice(@copies, 0, 1 << ($n-2)); # throw some away

for (my $i = 0; $i <= 1 << $n; $i++){
	exists $hash{$copies[-$i] || 'foo'};
	$hash{$copies[-$i] || 'foo'}++;
}

is((tied %hash)->cnt, 1 << ($n-2), "cnt");

@copies = ();

is((tied %hash)->cnt, 0, "cnt" );
