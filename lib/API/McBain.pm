package API::McBain;

# ABSTRACT: Framework for building auto-validating, self-documenting APIs.

our $VERSION = "0.1";
$VERSION = eval $VERSION;

use warnings;
use strict;

use Carp;
use Module::Pluggable;
use Try::Tiny;

use Exception::Class (
	'API::McBain::Exception' => {
		fields		=> 'code'
	},

	'API::McBain::Exception::NotFound' => {
		isa => 'API::McBain::Exception',
		description => 'when a request is made to a resource that does not exist',
	},

	'API::McBain::Exception::BadRequest' => {
		isa => 'API::McBain::Exception',
		description => 'when the request has illegal syntax or parameters failed validation',
		fields => 'rejects',
	}
);

=head1 NAME

API::McBain - Framework for building auto-validating, self-documenting APIs.

=head1 VERSION

version 0.1

=head1 SYNOPSIS

HOW YOU WRITE YOUR API

	package MyAPI;

	use API::McBain			# also imports warnings and strict
		separator => '.';	# that is the default, you can drop this or use something else

	1;

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

HOW YOU/OTHERS USE YOUR API:

	use MyAPI;

	my $api = MyAPI->new;

	print $api->call('math.add', one => 1, two => 4); # prints 5
	print $api->call('math.add', one => 1); # throws exception

HOW YOU/OTHERS LEARN YOUR API:

	# echoing this in the command line:
	$ mcbain describe MyAPI::Math

	# will result in the following output:
	> MyAPI::Math
	> 
	> Provided methods:
	>   * add
	>     Description: Receives two integers, returns their sum.
	>     Parameters:
	>        one: required, integer
	>        two: required, integer
	>     Return type: integer

=head1 DESCRIPTION

WARNING: this is an early release. API is subject to change, bugs may lurk under your bed.

C<McBain> is a simple framework for building APIs in Perl. It takes the burden of validating parameters so you don't need to repeat yourself with endless sanity checks; helps ensuring your APIs are written in a consistent manner; and also makes documenting them easier, making that process at least semi-automatic.

While Perl subroutines being endlessly flexible is one of the language's main strengths, there are some cases where finer grained control over them could be welcome. APIs that are meant to be used by others (say, an API for a web service you created meant to be used by customers) are one such example. You need to make sure that users of your code use it and don't abuse it. You need to express your API methods' requirements explicitly, and validate input in such a way that bad input does not cause problems, and users can understand what they did wrong. This is just two things your API needs to do, but doing them is hard, boring and tedious. While helpers like subroutine signatures are available, they are not flexible enough and are far from actually helping to solve the problem.

C<McBain> provides you with a simple syntax for building such methods and documenting them. It uses L<Brannigan> to validate input according to your specifications, and also provides a command line tool, L<mcbain>, that provides a C<man>-like interface for reading your API's documentation, while automatically parsing input specifications for each method so you don't need to document input requirements yourself.

In C<McBain>, your API methods are categorized into "topics". Each topic is a Perl package that uses L<API::McBain::Topic>. It has a name, and as many "provided methods" as you want. Each method also has a name, of course, and users can call these methods by referring to their complete name, including the topic. For example, if topic "math" has a method called "subtract", users call "math.subtract" to invoke that method (the dot character "." is the default separator between topic and method names, but can be modified to anything you want).

Your API will always start with a top level package that uses this module (C<API::McBain>). The top level package is not a topic and cannot provide methods.

C<McBain> is built to be as lightweight as possible. It does not rely on C<Moose> or any other OO modules, and I plan to keep dependencies to a minimum.

=cut

{
	no strict 'refs';
	sub import {
		warnings->import;
		strict->import;
		return if shift ne 'API::McBain';
		my $class = caller;
		my %args = @_;

		unless ($class eq 'main') {
			$args{separator} ||= '.';

			*{"${class}::new"} = sub {
				my $class = shift;
				my $self = bless {@_}, $class;

				$self->{separator} = $args{separator};
				$self->{topics} = {};

				# load topics (if any)
				Module::Pluggable->import(
					search_path => [$class],
					sub_name => '_topics',
					require => 1,
				);

				# save all topics as an object of the application
				foreach (sort __PACKAGE__->_topics) {
					my $topic = $_->new;
					$self->{topics}->{$topic->topic} = $topic;
				}

				return $self;
			};

			*{"${class}::topics"} = sub { $_[0]->{topics} };

			*{"${class}::separator"} = sub { $_[0]->{separator} };

			*{"${class}::call"} = sub {
				my ($self, $namespace, %params) = @_;

				my $sep = $self->separator;

				my ($topic, $method);
				if ($namespace =~ m/$sep([^$sep]+)$/) {
					$topic = $`;
					$method = $1;
				} else {
					API::McBain::Exception::BadRequest->throw(error => "Illegal namespace $namespace");
				}

				# find this topic
				my $t = $self->topics->{$topic}
					|| API::McBain::Exception::NotFound->throw(error => "Topic $topic does not exist");

				# does this topic have this method
				my $m = $t->provided_methods->FETCH($method)
					|| API::McBain::Exception::NotFound->throw(error => "Topic $topic does not provide a method named $method");

				# process parameters
				my $ret = Brannigan::process({ params => $m->params }, \%params);

				API::McBain::Exception::BadRequest->throw(error => "Parameters failed validation", rejects => $ret->{_rejects})
					if $ret->{_rejects};

				return $m->callback->($self, %params);
			};
		}

		return 1;
	}
}

=head1 DIAGNOSTICS

C<McBain> throws exceptions of C<McBain>-specific classes that extend L<Exception::Class::Base>.
The following exception classes currently exist:

=over

=item * C<API::McBain::Exception::NotFound> - Thrown when a call is made to a topic
and/or method that does not exist. Possible error strings are "Topic %s does not exist"
and "Topic %s does not provide a method named %s".

=item * C<API::McBain::Exception::BadRequest> - Thrown when a call is made with an
illegal namespace (so McBain cannot calculate topic and method, probably due to wrong
or missing separator), in which case "Illegal namespace %s" will be the error text;
or because input parameters for a provided method failed validation, in which case
"Parameters failed validation" will be the error text, and the exception object will
also have a field named "rejects" with L<Brannigan>'s standard "_rejects" structure
(see Brannigan for more info).

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
C<API::McBain> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<API::McBain> depends on the following CPAN modules:

=over

=item * L<Brannigan>

=item * L<Carp>

=item * L<Exception::Class>

=item * L<Module::Pluggable>

=item * L<Tie::IxHash>

=item * L<Try::Tiny>

=back

The command line utility, L<mcbain>, depends on the following CPAN modules:

=over

=item * L<Getopt::Compact::WithCmd>

=item * L<Module::Load>

=item * L<Term::ANSIColor>

=back

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-API-McBain@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=API-McBain>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc API::McBain

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
