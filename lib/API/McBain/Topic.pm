package API::McBain::Topic;

use warnings;
use strict;

use API::McBain::Topic::ProvidedMethod;
use Brannigan 1.0;
use Carp;
use Tie::IxHash;

=head1 NAME

API::McBain::Topic - Interface for writing API topics and methods

=head1 VERSION

version 0.1

=head1 SYNOPSIS

	# in your topic class:
	package MyAPI::Math;

	use API::McBain::Topic		# also imports warnings and strict
		topic => 'math';	# if you don't provide one, McBain will use a lowercased version
					# of the end of the package name (in this case, 'math').

	provide('add')
		->description('Receives two integers, returns their sum.')
		->param(one => { integer => 1, required => 1 })
		->param(two => { integer => 1, required => 1 })
		->returns('integer')
		->callback(sub {
			my ($self, %params) = @_;

			return $params{one} + $params{two};
		});

	provide('subtract')
		->description('Receives two integers, returns their difference.')
		->param(one => { integer => 1, required => 1 })
		->param(two => { integer => 1, required => 1 })
		->returns('integer')
		->callback(sub {
			my ($self, %params) = @_;

			return $params{one} - $params{two};
		});

	# in application code:
	use MyAPI;

	my $api = MyAPI->new;

	print $api->call('math.add', one => 1, two => 4); # prints 5
	print $api->call('math.add', one => 1); # throws exception "Parameters validation failed"
	print $api->call('math.subtract',
		one => $api->call('math.add', one => 2, two => 3),
		two => 5
	); # prints 0

=head1 DESCRIPTION

This class is the main interface L<API::McBain> provides for writing APIs. For a complete
description, see L<API::McBain/"DESCRIPTION">.

=cut

{
	no strict 'refs';
	sub import {
		warnings->import;
		strict->import;
		return unless shift eq 'API::McBain::Topic';
		my $class = caller;
		unless ($class eq 'main') {
			my %args = @_;
			$args{topic} ||= lc(($class =~ m/::([^:]+)$/)[0]);

			*{"${class}::new"} = sub {
				my $class = shift;
				my $self = bless {@_}, $class;
				$self->{topic} = $args{topic};
				return $self;
			};

			*{"${class}::topic"} = sub { $_[0]->{topic} };

			${"${class}::PROVIDED_METHODS"} = Tie::IxHash->new;

			*{"${class}::provided_methods"} = sub { ${"${class}::PROVIDED_METHODS"} };

			*{"${class}::provide"} = sub {
				my $name = shift || 'index';
				my $method = API::McBain::Topic::ProvidedMethod->new(name => $name);
				${"${class}::PROVIDED_METHODS"}->Push($name => $method);
				return $method;
			};
		}

		return 1;
	}
}

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-API-McBain@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=API-McBain>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc API::McBain::Topic

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
