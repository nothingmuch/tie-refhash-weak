#!/usr/bin/perl

package Tie::RefHash::Weak;
use base qw/Tie::RefHash/;

use strict;
use warnings;

use overload ();

our $VERSION = 0.04;

use Scalar::Util qw/weaken reftype/;
use Variable::Magic qw/wizard cast getdata/;

my $wiz = wizard free => \&_clear_weakened_sub, data => \&_add_magic_data;

sub _clear_weakened_sub {
	my ( $key, $objs ) = @_;
	foreach my $self ( @{ $objs || [] } ) {
		$self->_clear_weakened($key) if defined $self; # support subclassing
	}
}

sub _add_magic_data {
	my ( $key, $objects ) = @_;
	$objects;
}

sub _clear_weakened {
	my ( $self, $key ) = @_;

	$self->DELETE( $key );
}

sub STORE {
	my($s, $k, $v) = @_;

	if (ref $k) {
		# make sure we use the same function that RefHash is using for ref keys
		my $kstr = Tie::RefHash::refaddr($k);
		my $entry = [$k, $v];

		weaken( $entry->[0] );

		my $objects;

		# blech, any idea how to clean this up?

		if ( reftype $k eq 'SCALAR' ) {
			$objects = getdata( $$k, $wiz )
				or cast( $$k, $wiz, ( $objects = [] ) );
		} elsif ( reftype $k eq 'HASH' ) {
			$objects = getdata ( %$k, $wiz )
				or cast( %$k, $wiz, ( $objects = [] ) );
		} elsif ( reftype $k eq 'ARRAY' ) {
			$objects = getdata ( @$k, $wiz )
				or cast( @$k, $wiz, ( $objects = [] ) );
		} elsif ( reftype $k eq 'GLOB' or reftpe $k eq 'IO' ) {
			$objects = getdata ( *$k, $wiz )
				or cast( *$k, $wiz, ( $objects = [] ) );
		} else {
			die "patches welcome";
		}

		unless ( grep { $_ == $s } @$objects ) {
			push @$objects, $s;
			weaken($objects->[-1]);
		}

		$s->[0]{$kstr} = $entry;
	}
	else {
		$s->[1]{$k} = $v;
	}

	$v;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Tie::RefHash::Weak - A Tie::RefHash subclass with weakened references in the keys.

=head1 SYNOPSIS

	use Tie::RefHash::Weak;

	tie my %h, 'Tie::RefHash::Weak';

	{ # new scope
		my $val = "foo";

		$h{\$val} = "bar"; # key is weak ref
	
		print join(", ", keys %h); # contains \$val, returns regular reference
	}
	# $val goes out of scope, refcount goes to zero
	# weak references to \$val are now undefined

	keys %h; # no longer contains \$val

	# see also Tie::RefHash

=head1 DESCRIPTION

The L<Tie::RefHash> module can be used to access hashes by reference. This is
useful when you index by object, for example.

The problem with L<Tie::RefHash>, and cross indexing, is that sometimes the
index should not contain strong references to the objecs. L<Tie::RefHash>'s
internal structures contain strong references to the key, and provide no
convenient means to make those references weak.

This subclass of L<Tie::RefHash> has weak keys, instead of strong ones. The
values are left unaltered, and you'll have to make sure there are no strong
references there yourself.

=head1 THREAD SAFETY

L<Tie::RefHash> version 1.32 and above have correct handling of threads (with
respect to changing reference addresses). If your module requires
Tie::RefHash::Weak to be thread aware you need to depend on both
L<Tie::RefHash::Weak> and L<Tie::RefHash> version 1.32 (or later).

Version 0.02 and later of Tie::RefHash::Weak depend on a thread-safe version of
Tie::RefHash anyway, so if you are using the latest version this should already
be taken care of for you.

=head1 BUGS

=over 4

=item Value refcount delay

When the key loses it's reference count and goes undef, the value associated
with that key will not be deleted until the next call to purge, which may be
significantly later.

Purge manually in critical sections, or implement
L</Hook Perl_magic_killbackrefs>.

=back

=head1 AUTHORS

Yuval Kogman <nothingmuch@woobling.org>

some maintenance by Hans Dieter Pearcey <hdp@pobox.com>

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2004 Yuval Kogman. All rights reserved
        This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Tie::RefHash>, L<Class::DBI> (the live object cache),
L<mg.c/Perl_magic_killbackrefs>

=cut
