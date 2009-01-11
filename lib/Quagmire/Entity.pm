package Quagmire::Entity;
use Quagmire::Entity::Condition;
use Quagmire::Power;
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
        has "_${abi}_mod"  => (is=>'rw',isa=>'Int',default=>0,required=>1); # for mobs
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

sub _ability_mod {
        my $S = shift;
        my $abi = shift;
        $S->modifier($abi) if (!$S->monster());
        my $_abi = "_${abi}_mod";
        my $new_value = shift;
        my $ab;
        if (defined $new_value) {
                $ab = $S->$_abi($new_value);
        } else {
                $ab = $S->$_abi();
        }
        return 0 if (!defined $ab);
        return $ab;
}

sub str_mod {shift->_ability_mod('str',shift)}
sub con_mod {shift->_ability_mod('con',shift)}
sub dex_mod {shift->_ability_mod('dex',shift)}
sub int_mod {shift->_ability_mod('int',shift)}
sub wis_mod {shift->_ability_mod('wis',shift)}
sub cha_mod {shift->_ability_mod('cha',shift)}

sub modifier {
	my ($self,$score) = @_;
	return 0 if (!defined $score);
	return 0 if ($score !~ /^\d+$/x); # not a number
	$score -= 10;
	return (($score-1)/2) if ($score % 2);
	return ($score/2);
}

sub heal {
        my $S = shift;
        my $amount = shift;
        return if (!defined $amount);
        $amount = int($amount);
        return if (!$amount);
        if ($S->hp_current() + $amount >= $S->hp) {
                $S->hp_current($S->hp());
                return;
        }
        $S->hp_current($S->hp_current + $amount);
}

sub damage {
        my $S = shift;
        my $amount = shift;
        return if (!defined $amount);
        $amount = int($amount);
        return if (!$amount);
        my $t = $S->hp_temp();
        if ($amount > $t) {
                $amount -= $t;
                $S->hp_temp(0);
                $S->hp_current($S->hp_current - $amount);
        } else {
                $t -= $amount;
                $S->hp_temp($t);
        }
}

sub BUILD {
        my $S = shift;
        if ($S->hp_current == 0) {
                $S->hp_current($S->hp);
        }
}

__PACKAGE__->meta->make_immutable();
1;
