package McBainTestAPI::TestTopic;

use API::McBain::Topic
	topic => 'math';

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

provide('add-then-subtract')
	->description('Receives three integers, adds the first two, subtracts the third.')
	->param(one => { integer => 1, required => 1 })
	->param(two => { integer => 1, required => 1 })
	->param(three => { integer => 1, required => 1 })
	->returns('integer')
	->callback(sub {
		my ($self, %params) = @_;

		return $self->call('math_subtract',
			one => $self->call('math_add', one => $params{one}, two => $params{two}),
			two => $params{three}
		);
	});

1;
