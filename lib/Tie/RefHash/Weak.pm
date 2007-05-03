#!/usr/bin/perl

package Tie::RefHash::Weak;
use base qw/Tie::RefHash/;

use strict;
use warnings;

use overload ();

our $VERSION = 0.01;

use Scalar::Util qw/weaken/;

sub purge {
	my $self = shift;
	$self->[3] = 0;

	foreach my $key (keys %{ $self->[0] }){
		delete $self->[0]{$key} unless defined $self->[0]{$key}[0]; # delete if the reference became undef
	}
}

sub maybe_purge {
	my $self = shift;
	$self->purge if ++$self->[3] > (10 + ($self->[4] ||= 15) * log(scalar keys %{ $self->[0] } || 1));
}

sub STORE {
	my($s, $k, $v) = @_;
	$s->maybe_purge;

	if (ref $k) {
		# make sure we use the same function that RefHash is using for ref keys
		my $kstr = Tie::RefHash::refaddr($k);
		weaken(($s->[0]{$kstr} = [$k, $v])->[0]);
	}
	else {
		$s->[1]{$k} = $v;
	}
	$v;
}

sub FETCH {
	my ($s, $k) = @_;
	$s->maybe_purge;
	$s->SUPER::FETCH($k);
}

sub EXISTS {
	my ($s, $k) = @_;
	$s->maybe_purge;
	$s->SUPER::EXISTS($k);
}

sub NEXTKEY {
	my $s = shift;

	my ($k, $v);

	if (!$s->[2]){
		while (($k, $v) = each %{ $s->[0] }) {
			if (defined $v->[0]){ # weak refs wiuth no referants (thingys) become undef
				$s->[3]-- if $s->[3] > 0;
				return $v->[0];
			} else {
				delete $s->[0]{$k};
			}
		}

		$s->[2] = 1; # we're out of references, so lets iterate the "regular" hash.
	}

	return each %{ $s->[1] };
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

=head1 STRUCTURE MAINTAINCE

In perl when weak refernces go bad, they become undef. L<Tie::RefHash::Weak>
needs to occasionally go through it's structures and clean out the stale keys.

It does this on two occasions:

=over 4

=item As necessary

When an aggregate operation, like L<keys> and L<values> (even in scalar
context), or list context interpolation of the hash is made, the whole hash's
state must be validated.

This is done lazily, within each call to L<NEXTKEY>. If you need to ensure a
low latency, then only iterate with L<each>.

=item Occasionally

A counter is raised on each update. It's stored in C<$self->[3]>. The counter
is incremented via the C<maybe_purge> method. If the counter is bigger than ten
plus C<$self->[4]> (which defaults to 15) times the natural logarithm of the
number of actual reference keys in the hash (before we know how many are
stale), then the hash is iterated and purged. This value tries to ensure that
purges aren't made too often, so that they don't take up too much time, but the
cleanup is still made in order to prevent leaking data, and to decrement the
reference counts of the I<values> of the hash.

If you know that your hash will not be accessed often, and 

=back

You can disable purging by making C<maybe_purge> a no-op in your subclass.

You can forcibly purge by calling

	(tied %hash)->purge;

You can tweak the occasional purging by playing setting

	(tied %hash)->[4] = $x;

=head1 TODO

=over 4

=item Hook Perl_magic_killbackrefs

Maybe some day the code which undefines weak references will be hooked with XS
to purge the hash in a more real-time fashion.

=back

=head1 THREAD SAFETY

L<Tie::RefHash> version 1.32 and above have correct handling of threads (with
respect to changing reference addresses). If your module requires
Tie::RefHash::Weak to be thread aware you need to depend on both
L<Tie::RefHash::Weak> and L<Tie::RefHash> version 1.32.

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
