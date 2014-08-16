package Adapter::Async::Bus;
$Adapter::Async::Bus::VERSION = '0.006';
use strict;
use warnings;

use parent qw(Mixin::Event::Dispatch);
use constant EVENT_DISPATCH_ON_FALLBACK => 0;

=head1 NAME

Adapter::Async::Bus - 

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub new { my $class = shift; bless { @_ }, $class }

=head1 EVENTS

=cut

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014. Licensed under the same terms as Perl itself.
