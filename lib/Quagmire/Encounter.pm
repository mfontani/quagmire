package Quagmire::Encounter;
use Moose;
use MooseX::Storage;
use Quagmire::Encounter::Status;
use Quagmire::Party;
use YAML;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

with Storage('format' => 'YAML', 'io' => 'File');

has 'monsters' => (is=>'rw',isa=>'Quagmire::Party',required=>1,default=>sub{Quagmire::Party->new});
has 'monsters_filename' => (is=>'rw',isa=>'Str',required=>1,default=>'');

has 'party' => (is=>'rw',isa=>'Quagmire::Party',required=>1,default=>sub{Quagmire::Party->new});
has 'party_filename' => (is=>'rw',isa=>'Str',required=>1,default=>'');

has 'status' => (is => 'rw', isa=>'Quagmire::Encounter::Status',required=>1,default=>sub{Quagmire::Encounter::Status->new});

# Entities is just a shortcut to list of party members then monsters
sub entities {
	my $s = shift;
	return [@{$s->party->entities},@{$s->monsters->entities}];
}

sub remove_entity {
	my $s = shift;
	my $which = shift;
	$s->party->remove_entity($which);
	$s->monsters->remove_entity($which);
}

sub BUILD {
	my $s = shift;
	if ($s->party_filename) {
		# loads party from filename
		my $p = Quagmire::Party->load($s->party_filename);
		$s->party->clone_from($p);
	}
	if ($s->monsters_filename) {
		# loads party from filename
		my $p = Quagmire::Party->load($s->monsters_filename);
		$s->monsters->clone_from($p);
	}
}

sub reset {
	my $s = shift;
	foreach my $ent (@{$s->entities}) {
		$ent->initiative(0);
		$ent->hp_temp(0);
		$ent->hp_current($ent->hp());
	}
	$s->status->turn(undef);
	$s->status->round(0);
}

sub turn {shift->status->turn}

sub next {
	my $s = shift;
	my @ordered = sort {$b->initiative <=> $a->initiative} @{$s->entities};
	if (!defined $s->status->turn) {
		$s->status->turn($ordered[0]);
		return $ordered[0];
	}
	my $curr = $s->status->turn();
	foreach my $nent (0..$#ordered) {
		if ($ordered[$nent] == $curr) {
			if ($nent == $#ordered) {
				warn "new round!";
				$s->status->round($s->status->round+1);
				$s->status->turn($ordered[0]);
				return $ordered[0];
			}
			$s->status->turn($ordered[$nent+1]);
			return $ordered[$nent+1];
		}
	}
	warn "HELP!";
}

__PACKAGE__->meta->make_immutable();
1;
