package Quagmire::Party;
use Moose;
use MooseX::Storage;
use YAML;
use Quagmire::Entity;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

with Storage('format' => 'YAML', 'io' => 'File');

has 'name' => (is=>'rw',isa=>'Str',required=>1,default=>'');
has 'entities' => (is => 'rw', isa => 'ArrayRef[Quagmire::Entity]', default => sub{[]}, required=>1);

sub remove_entity {
	my $s = shift;
	my $which = shift or die "remove_entity: need entity to be deleted!";
	my @new_party;
	foreach my $m (@{$s->entities}) {push (@new_party,$m) if ($m->name ne $which);}
	$s->entities(\@new_party);
}

sub add_entity {
	my $s = shift;
	my $which = shift or die "add_entity: need entity to be added!";
	push (@{$s->entities},$which);
}

sub clone_from {
	my $s = shift;
	my $party = shift or die "clone_from: need party to clone from!";
	$s->name($party->name);
	$s->entities([]);
	foreach my $ent (@{$party->entities}) {
		$s->add_entity($ent);
	}
}

__PACKAGE__->meta->make_immutable();
1;
