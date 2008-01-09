#!/usr/bin/perl

package Devel::INC::Sorted;
use base qw(Exporter Tie::Array);

use strict;
use warnings;

use sort 'stable';

use Scalar::Util qw(blessed reftype);
use Tie::RefHash;

our $VERSION = "0.01";

our @EXPORT_OK = qw(inc_add_floating inc_float_entry inc_unfloat_entry untie_inc);

tie our %floating, 'Tie::RefHash';

sub import {
	my ( $self, @args ) = @_;
	$self->tie_inc( grep { ref } @args ); # if a code ref is given, pass it to TIEARRAY
	$self->export_to_level(1, $self, @args);
}

sub _args {
	my ( $self, @args );

	if (
		( blessed($_[0]) or defined($_[0]) && !ref($_[0]) ) # class or object
			and
		( $_[0]->isa(__PACKAGE__) )
	) {
		$self = shift;
	} else {
		$self = __PACKAGE__;
	}

	return ( $self->tie_inc, @_ );
}

sub inc_add_floating {
	my ( $self, @args ) = &_args;

	$self->inc_float_entry(@args);

	$self->PUSH(@args);
}

sub inc_float_entry {
	my ( $self, @args ) = &_args;
	
	@floating{@args} = ( (1) x @args );

	$self->_fixup;
}

sub inc_unfloat_entry {
	my ( $self, @args ) = &_args;

	delete @floating{@args};

	$self->_fixup;
}

sub tie_inc {
	my ( $self, @args ) = @_;
	return $self if ref $self;
	return tied @INC if tied @INC;
	tie @INC, $self, $args[0], @INC;
}

sub untie_inc {
	my ( $self ) = &_args;
	no warnings 'untie'; # untying while tied() is referenced elsewhere warns
	untie @INC;
	@INC = @{ $self->{array} };
}

# This code was adapted from Tie::Array::Sorted::Lazy
# the reason it's not a subclass is because neither ::Sorted nor ::Sorted::Lazy
# provide a stably sorted array, which is bad for our default comparator

sub TIEARRAY {
	my ( $class, $comparator, @orig ) = @_;

	$comparator ||= sub {
		my ( $left, $right ) = @_;
		exists $floating{$right} <=> exists $floating{$left};
	};

	bless {
		array => \@orig,
		comp  => $comparator,
	}, $class;
}

sub STORE {
	my ($self, $index, $elem) = @_;
	$self->{array}[$index] = $elem;
	$self->_fixup();
	$self->{array}[$index];
}

sub PUSH {
	my $self = shift;
	my $ret = push @{ $self->{array} }, @_;
	$self->_fixup();
	$ret;
}

sub UNSHIFT {
	my $self = shift;
	my $ret = unshift @{ $self->{array} }, @_;
	$self->_fixup();
	$ret;
}

sub _fixup {
	my $self = shift;
	$self->{array} = [ sort { $self->{comp}->($a, $b) } @{ $self->{array} } ];
	$self->{dirty} = 0;
}

sub FETCH {
	$_[0]->{array}->[ $_[1] ];
}

sub FETCHSIZE { 
	scalar @{ $_[0]->{array} } 
}

sub STORESIZE {
	$#{ $_[0]->{array} } = $_[1] - 1;
}

sub POP {
	pop(@{ $_[0]->{array} });
}

sub SHIFT {
	shift(@{ $_[0]->{array} });
}

sub EXISTS {
	exists $_[0]->{array}->[ $_[1] ];
}

sub DELETE {
	delete $_[0]->{array}->[ $_[1] ];
}

sub CLEAR { 
	@{ $_[0]->{array} } = () 
}

__PACKAGE__

__END__

=pod

=head1 NAME

Devel::INC::Sorted - Keep your hooks in the begining of C<@INC>

=head1 SYNOPSIS

	use Devel::INC::Sorted qw(inc_add_floating);

	inc_add_floating( \&my_inc_hook );
	unshift @INC, \&other_hook;

	use lib 'blah';

	push @INC, 'foo';

	warn $INC[0]; # this is still \&my_inc_hook
	warn $INC[3]; # but \&other_hook was moved down to here

=head1 DESCRIPTION

This module keeps C<@INC> sorted much like L<Tie::Array::Sorted>.

The default comparator partitions the members into floating and non floating,
allowing you to easily keep certain hooks in the begining of C<@INC>.

The sort used is a stable one, to make sure that the order of C<@INC> for
unsorted items remains unchanged.

=head1 EXPORTS

All exports are optional

=over 4

=item inc_add_floating

Add entries to C<@INC> and call C<inc_float_entry> on them.

=item inc_float_entry

Mark the arguments as floating (in the internal refhash).

=item inc_unfloat_entry

Remove the items from the hash.

=item untie_inc

Untie C<@INC>, leaving all it's current elements in place. Further
modifications to C<@INC> will not cause resorting to happen.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


