package Adapter::Async::OrderedList::Array;
$Adapter::Async::OrderedList::Array::VERSION = '0.007';
use strict;
use warnings;

use parent qw(Adapter::Async::OrderedList);

=head1 NAME

Adapter::Async::OrderedList::Array - arrayref adapter

=head1 VERSION

Version 0.007

=head1 DESCRIPTION

See L<Adapter::Async::OrderedList> for the API.

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{data} ||= [];
	$self
}

sub clear {
	my $self = shift;
	@{$self->{data}} = ();
	$self->bus->invoke_event('clear');
	Future->wrap
}

sub splice:method {
	my ($self, $idx, $len, $data) = @_;
	$data ||= [];
	my @rslt = splice @{$self->{data}}, $idx, $len, @$data;
	$self->bus->invoke_event(splice => $idx, $len, $data => \@rslt);
	Future->wrap($idx, $len, $data, \@rslt);
}

# XXX weakrefs
sub move {
	my ($self, $idx, $len, $offset) = @_;
	my @data = splice @{$self->{data}}, $idx, $len;
	splice @{$self->{data}}, $idx + $offset, 0, @data;
	$self->bus->invoke_event(move => $idx, $len, $offset);
	Future->wrap($idx, $len, $offset);
}

# XXX needs updating
sub modify {
	my ($self, $idx, @cols) = @_;
	die "row out of bounds" unless @{$self->{data}} >= $idx;
	$self->{data}[$idx][$_] = $cols[$_] for 0..$#cols;
	Future->wrap
}

sub delete {
	my ($self, $idx) = @_;
	$self->splice($idx, 1, [])
}

=head1 count

=cut

sub count {
	my $self = shift;
	Future->wrap(scalar @{$self->{data}});
}

=head1 get

=cut

sub get {
	my ($self, %args) = @_;
	return Future->fail('unknown item') if grep $_ > @{$self->{data}}, @{$args{items}};
	my @items = @{$self->{data}}[@{$args{items}}];
	if(my $code = $args{on_item}) {
		my @idx = @{$args{items}};
		$code->(shift(@idx), $_) for @items;
	}
	Future->wrap(\@items)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2014. Licensed under the same terms as Perl itself.
