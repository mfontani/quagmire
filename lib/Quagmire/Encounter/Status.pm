package Quagmire::Encounter::Status;
use Moose;
use MooseX::Storage;
use Quagmire::Entity;
our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';
with Storage('format' => 'YAML', 'io' => 'File');

has 'filename' => (is => 'rw', isa => 'Str', default=>'', required=>1);
has 'round'  => (is => 'rw', isa => 'Int', default=>0, required=>1);

our $_turn;
our $_turn_name;
sub turn {
	my $S = shift;
	my $set = shift;
	if (!defined $set) {
		return $_turn
	}
	if (ref $set eq 'Quagmire::Entity') {
		$_turn = $set;
		$_turn_name = $set->name;
	} else {
		warn "Can't turn() a non-Entity: ", ref $set;
	}
	return $_turn;
}

__PACKAGE__->meta->make_immutable;
1;
