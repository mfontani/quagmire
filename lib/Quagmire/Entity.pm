package Quagmire::Entity;
use Quagmire::Entity::Condition;
use Moose;
use MooseX::Storage;
use YAML;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

with Storage('format' => 'YAML', 'io' => 'File');

has 'name' => (is=>'rw',isa=>'Str',default=>'',required=>1);

has 'race' => (is=>'rw',isa=>'Str',default=>'',required=>1);

# doubles as role for monsters
has 'class' => (is=>'rw',isa=>'Str',default=>'',required=>1);

has 'level' => (is=>'rw',isa=>'Int',default=>0,required=>1);

has 'initiative' => (is=>'rw',isa=>'Int',default=>0,required=>1);
has 'initiative_bonus' => (is=>'rw',isa=>'Int',default=>0,required=>1);

has 'speed' => (is=>'rw',isa=>'Int',default=>0,required=>1);
# action points
has 'ap' => (is=>'rw',isa=>'Int',default=>0,required=>1);

has 'hp' => (is=>'rw',isa=>'Int',default=>0,required=>1);
has 'hp_current' => (is=>'rw',isa=>'Int',default=>0,required=>1);
has 'hp_temp' => (is=>'rw',isa=>'Int',default=>0,required=>1);

has 'ac' => (is=>'rw',isa=>'Int',default=>0,required=>1);
has 'fort' => (is=>'rw',isa=>'Int',default=>0,required=>1);
has 'ref' => (is=>'rw',isa=>'Int',default=>0,required=>1);
has 'will' => (is=>'rw',isa=>'Int',default=>0,required=>1);

foreach my $abi (qw/str con dex int wis cha/) {
        has $abi => (is=>'rw',isa=>'Int',default=>0,required=>1);
        has "${abi}_mod" => (is=>'rw',isa=>'Int',lazy=>1,required=>1,default=>sub {
                my $S = shift;
                return sub {$S->modifier($abi);} if (!$S->monster());
                return 0;
        });
}

# has 'daily_powers_used' => (is=>'rw',isa=>'Int',default=>0,required=>1);

has 'powers' => (is=>'rw',isa=>'ArrayRef[Quagmire::Power]',default=>sub{[]},required=>1);

has 'notes' => (is=>'rw',isa=>'Str',default=>'',required=>1);

has 'conditions' => (is=>'rw',isa=>'ArrayRef[Quagmire::Entity::Condition]',required=>1,default=>sub{[]});

has 'xp' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'monster' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'page' => (is=>'rw',isa=>'Str',required=>1,default=>0);

sub surge_value {
	return int (shift->hp / 4);
}

sub modifier {
	my ($self,$score) = @_;
	return 0 if (!defined $score);
	return 0 if ($score !~ /^\d+$/x); # not a number
	$score -= 10;
	return (($score-1)/2) if ($score % 2);
	return ($score/2);
}

__PACKAGE__->meta->make_immutable();
1;