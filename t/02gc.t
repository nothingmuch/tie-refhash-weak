#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok("Tie::RefHash::Weak") }

sub Tie::RefHash::Weak::cnt {
	my $s = shift;
	scalar keys %{ $s->[0] }
}

my $n = 10; # create a large hunk of 

tie my %hash, 'Tie::RefHash::Weak'; my @copies;
%hash = map { $_ => 1 } @copies = map {bless \$_, "Some::Class"} 1 .. 1 << $n;

is(scalar keys %hash, 1 << $n, "scalar keys");
is((tied %hash)->cnt, 1 << $n, "cnt");

splice(@copies, 0, 1 << ($n-1)); # throw some away

is((tied %hash)->cnt, 1 << $n, "cnt");
is(scalar keys %hash, 1 << ($n-1), "scalar keys"); # iterate lots of NEXTKEY
is((tied %hash)->cnt, 1 << ($n-1), "cnt");

splice(@copies, 0, 1 << ($n-2)); # throw some away

for (my $i = 0; $i <= 1 << $n; $i++){
	exists $hash{$copies[-$i] || 'foo'};
	$hash{$copies[-$i] || 'foo'}++;
}

is((tied %hash)->cnt, 1 << ($n-2), "cnt");

