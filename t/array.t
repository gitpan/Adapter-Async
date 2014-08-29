use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Adapter::Async::OrderedList::Array;

my $array = new_ok('Adapter::Async::OrderedList::Array');
is($array->count->get, 0, 'starts empty');

# Test an insert
$array->bus->subscribe_to_event(
	splice => sub {
		my ($ev, $idx, $len, $data) = @_;
		is($idx, 0, 'splice event for insert had expected index');
		is($len, 0, 'zero length');
		is_deeply($data, ['x'], 'and our expected data');
		$ev->unsubscribe;
	}
);
is(exception {
	$array->insert(0, ['x'])->get
}, undef, 'can insert item');
is($array->count->get, 1, 'now have one item');
is_deeply($array->get(
	items => [0],
	on_item => sub {
		my ($idx, $item) = @_;
		is($item, 'x', 'had expected item in callback');
	}
)->get, ['x'], 'now have one item');

# Now for an append
$array->bus->subscribe_to_event(
	splice => sub {
		my ($ev, $idx, $len, $data) = @_;
		is($idx, 1, 'splice event for append had expected index');
		is($len, 0, 'zero length');
		is_deeply($data, [qw(y z)], 'and our expected data');
		$ev->unsubscribe;
	}
);
is(exception {
	$array->append(0, [qw(y z)])->get
}, undef, 'can append two more items');
is($array->count->get, 3, 'count is now 3');
{
	my @expected = qw(x y z);
	is_deeply($array->get(
		items => [0..2],
		on_item => sub {
			my ($idx, $item) = @_;
			is($item, splice(@expected, $idx, 1, undef), "had expected item $idx in callback");
		}
	)->get, [qw(x y z)], 'have our 3 items');
	is_deeply(\@expected, [(undef) x 3], 'callback fired for all expected items');
}

# now we move
$array->bus->subscribe_to_event(
	move => sub {
		my ($ev, $idx, $len, $offset) = @_;
		is($idx, 2, 'move event had expected index');
		is($len, 1, 'correct length');
		is($offset, -1, 'correct offset');
		$ev->unsubscribe;
	}
);
is(exception {
	$array->move(2, 1, -1)->get
}, undef, 'can move last element back by one');
is($array->count->get, 3, 'count unchanged');

is_deeply($array->get(
	items => [0..2],
)->get, [qw(x z y)], 'elements were reordered');

# and move in the other direction
$array->bus->subscribe_to_event(
	move => sub {
		my ($ev, $idx, $len, $offset) = @_;
		is($idx, 0, 'move event had expected index');
		is($len, 1, 'correct length');
		is($offset, 1, 'correct offset');
		$ev->unsubscribe;
	}
);
is(exception {
	$array->move(0, 1, 1)->get
}, undef, 'can move first element forward by one');
is($array->count->get, 3, 'count unchanged');

is_deeply($array->get(
	items => [0..2],
)->get, [qw(z x y)], 'elements were reordered');

# and reorder back to original
is(exception {
	$array->move(0, 1, 2)->get
}, undef, 'can move last element back to original place');
is($array->count->get, 3, 'count unchanged');

is_deeply($array->get(
	items => [0..2],
)->get, [qw(x y z)], 'elements back in original order');

is(exception {
	$array->clear->get
}, undef, 'can clear');
is($array->count->get, 0, 'count now zero');

{
	my $modified = 0;
	$array->bus->subscribe_to_event(
		modify => sub {
			my ($ev, $idx, $data) = @_;
			is($idx, 2, 'modify event had expected index');
			is($data, 'x', 'correct value');
			++$modified;
			$ev->unsubscribe;
		}
	);
	is(exception {
		$array->push([qw(a b c d)])->get;
	}, undef, 'can push');
	is($array->count->get, 4, 'count now 4');
	is($modified, 0, 'not yet modified');
	is(exception {
		$array->modify(2, 'x')->get;
	}, undef, 'can modify');
	is($modified, 1, 'was modified');
}

done_testing;

