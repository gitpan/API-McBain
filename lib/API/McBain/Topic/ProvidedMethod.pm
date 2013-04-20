package API::McBain::Topic::ProvidedMethod;

use warnings;
use strict;

=head1 NAME

API::McBain::Topic::ProvidedMethod - Provided method class

=head1 VERSION

version 0.1

=head1 DESCRIPTION

Every provided method in a C<McBain> topic (that uses L<API::McBain::Topic>)
is blessed into this class. This happens entirely internally and normally
you would not have/need access to these objects; however, you could have
access to these objects by simply keeping the return value of your method
decleration, like so:

	# in a topic
	my $method = provide('somefunc')
		->param('someparam' => { required => 1 })
		->callback(sub { # do something });

	# $method will now hold the API::McBain::Topic::ProvidedMethod object

=head1 CONSTRUCTOR

=head2 new( \%params )

Creates a new provided method object. Only called internally.

=cut

sub new {
	my $class = shift;
	my $self = bless {@_}, $class;
	$self->{params} ||= {};
	return $self;
}

=head1 OBJECT ATTRIBUTES

All of these attributes (except C<params>) are read-write. If called
with no arguments, the current value of the attribute is returned.
If called with an argument, it is set as the new value of the attribute,
and the I<object itself> is returned for chaining.

=head2 name( [$new_name] )

The name of the method - string (no spaces, don't use the separator
in method names).

=head2 description( [$new_description] )

The description of the method - free text string.

=head2 callback( [$new_callback] )

The callback of the method - an anonymouse subroutine, the actual
logic of the method.

=head2 returns ( [$new_returns] )

The return type of the method - free text string.

=cut

no strict 'refs';
foreach my $m (qw/name description callback returns/) {
	*{__PACKAGE__.'::'.$m} = sub {
		if ($_[1]) {
			$_[0]->{$m} = $_[1];
			return $_[0];
		} else {
			return $_[0]->{$m};
		}
	};
}
use strict 'refs';

=head2 params()

The L<Brannigan> parameter specification for the method,
declaring input parameters and their constraints.

=cut

sub params { $_[0]->{params} }

=head1 OBJECT METHODS

=head2 param( $name, \%spec )

Adds a new input parameter specification to the object.
C<$name> is the name of the input parameter and C<\%spec>
is the C<Brannigan> specification for that parameter.
Returns the I<object itself> for chaining.

=cut

sub param { $_[0]->params->{$_[1]} = $_[2]; $_[0] }

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-API-McBain@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=API-McBain>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc API::McBain::Topic::ProvidedMethod

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=API-McBain>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/API-McBain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/API-McBain>

=item * Search CPAN

L<http://search.cpan.org/dist/API-McBain/>

=back

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Ido Perlmuter C<< ido@ido50.net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
__END__
