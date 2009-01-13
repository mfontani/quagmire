package Quagmire::Entity::Condition;
use Moose;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

has 'name' => (is=>'rw',isa=>'Str',required=>1,default=>'');
has 'until' => (is=>'rw',isa=>'Int',required=>1,default=>-1); # -1 == save ends, -2 DELETE IT!
has 'description' => (is=>'rw',isa=>'Str',required=>1,default=>'');

# what the condition may modify
has 'perception' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'grants_combat_advantage_melee' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'grants_combat_advantage_ranged' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'can_see' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_flank' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_hear' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_move' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_teleport' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'one_action' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'can_take_actions' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_immediate' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_opportunity' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_choose_actions' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'can_be_coup_de_graced' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'can_be_pushed_pulled_slided' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'is_prone' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'defenses_melee' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'defenses_ranged' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'do_death_saving_throw' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'is_petrified' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'marked' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'marked_by' => (is=>'rw',isa=>'Maybe[Quagmire::Entity]',required=>1,default=>sub{undef});
has 'attack_roll' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'resist_all_damage' => (is=>'rw',isa=>'Int',required=>1,default=>0);
has 'aware_surroundings' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'ages' => (is=>'rw',isa=>'Int',required=>1,default=>1);
has 'limited_speed' => (is=>'rw',isa=>'Maybe[Int]',required=>1,default=>sub{undef});
has 'damage_modifier' => (is=>'rw',isa=>'Num',required=>1,default=>1); # 1 == 100%
has 'ongoing_damage_modifier' => (is=>'rw',isa=>'Int',required=>1,default=>1); # 1 == 100%

our %descr = (
	blinded => {
		description=>"Grant CA; Can't see: targets have total concealment; -10 Perception; Can't flank",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		can_see=>0,
		perception=>-10,
		can_flank=>0,
	},
	dazed => {
		description=>"Grant CA; Can take ONE action per round; Can't take immediate/opportunity; Can't flank",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		one_action=>1,
		can_immediate=>0,
		can_opportunity=>0,
		can_flank=>0,
	},
	deafened => {
		description=>"Can't hear; -10 Perception",
		can_hear=>0,
		perception=>-10,
	},
	dominated => {
		description=>"(dazed); Grant CA; Can take ONE action per round; Can't take immediate/opportunity; Can't flank; Dominating creature chooses your actions (only at-will powers)",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		one_action=>1,
		can_immediate=>0,
		can_opportunity=>0,
		can_flank=>0,
		can_choose_actions=>0,
	},
	dying => {
		description=>"(unconscious,helpless) Grant CA; Can be target of Coup de Grace; -5 all defenses; can't take actions; Fall prone; Can't flank; <=0 hp; Death saving throw each round (PHB 295)",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		can_be_coup_de_graced=>1,
		defenses_melee=>-5,
		defenses_ranged=>-5,
		can_take_actions=>0,
		is_prone=>1,
		can_flank=>0,
		do_death_saving_throw=>1,
	},
	helpless => {
		description=>"Grant CA; Can be target of Coup de Grace",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		can_be_coup_de_graced=>1,
	},
	immobilized => {
		description=>"Can't move; can teleport; can be pushed/pulled/slided",
		can_move=>0,
	},
	marked => {
		description=>"-2 penalty to attack any other target than who marked you",
		marked=>1,
		## requires marked_by ?
	},
	petrified => {
		description=>"Turned to stone; Can't take actions; Gain resist 20 all damage; Unaware of your surroundings; Don't age",
		is_petrified=>1,
		can_take_actions=>0,
		resist_all_damage=>20,
		aware_surroundings=>0,
		ages=>0,
	},
	prone => {
		description=>"Grant CA to melee; +2 all defenses against ranged; lying on the ground (fly->damage from fall); -2 attack rolls",
		grants_combat_advantage_melee=>1,
		defenses_ranged=>2,
		is_prone=>1,
		attack_roll=>-2,
	},
	restrained => {
		description=>"(immobilized) Grant CA; Can't move, can't be moved by push/pull/slide; -2 attack rolls",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		can_move=>0,
		can_be_pushed_pulled_slided=>0,
		attack_roll=>-2,
	},
	slowed => {
		description=>"Speed is <=2; Doesn't apply to push/pull/slide; Slowed while moving=>stop after 2sq",
		limited_speed=>2,
	},
	stunned => {
		description=>"Grant CA; Can't take actions; Can't flank",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		can_take_actions=>0,
		can_flank=>0,
	},
	surprised => {
		description=>"Grant CA; Can't take actions; Can't flank",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		can_take_actions=>0,
		can_flank=>0,
	},
	unconscious => {
		description=>"(helpless) Grant CA; Can be target of Coup de Grace; -5 all defenses; Can't take actions; Fall prone; Can't flank",
		grants_combat_advantage_melee=>1,
		grants_combat_advantage_ranged=>1,
		can_be_coup_de_graced=>1,
		defenses_melee=>-5,
		defenses_ranged=>-5,
		can_take_actions=>0,
		is_prone=>1,
		can_flank=>0,
	},
	weakened => {
		description=>"Your attacks deal half damage; Ongoing damage you deal is not affected",
		damage_modifier=>0.5,
	},
);

sub _refresh {
	my $S = shift;
	if (defined $descr{$S->name}) {
		foreach my $k (keys %{$descr{$S->name}}) {
			# s-> description ( $descr{$S->name}->{description} );
			# s-> can_flank ( $descr{$S->name}->{can_flank} );
			# ...
			$S->$k( $descr{$S->name}->{$k} );
		}
	} else {
		warn "No information found for condition ", $S->name;
	}
}

sub choose {
	my $S = shift;
	my $tk = shift;
	my $dlg = $tk->window->DialogBox(
		-title => 'Choose a condition',
		-buttons => [qw/Ok Cancel/],
		-default_button => 'Ok',
	);
	my $P_list = $dlg->Subwidget('top')->HList(-columns=>1,-header=>1,-width=>60)->pack(
		-side=>'top',
		-fill=>'x',
		-expand=>1,
	);
	$P_list->header('create',0,-itemtype=>'text',-text=>'Condition');
	$P_list->delete('all');
	foreach my $C (keys %descr) {
		$P_list->add($C);
		$P_list->itemCreate($C,0,-itemtype=>'text',-text=>$C);
	}
	$P_list->configure(
		-browsecmd => [sub {
			my ($list, $self, $which, @others) = @_;
			warn "CONDITION PList clicked: list $list self $self selected >$which<, other params: >@others<\n";
			$self->name($which);
			$self->_refresh;
			warn "Fed back condition ", $self->name;
		}, $P_list, $S
		],
	);
	$dlg->Subwidget('top')->Label(-text=>'Until round')->pack(-side=>'top',-fill=>'x',-expand=>1);
	my $round = -1;
	my $E = $dlg->Subwidget('top')->Entry(
		-textvariable => \$round,
	)->pack(
		-side=>'top',
		-fill=>'x',
		-expand=>1,
	);
	my $rc = $dlg->Show;
	return 0 if $rc =~ /cancel/i;
	$S->until($round);
	return 1;
}

sub BUILD {
	my $S = shift;
	$S->_refresh;
}

sub tk_show_saves {
	my $S = shift;
	my $tk = shift;
	die "tk_show_saves(): need tk to draw to!" if (!defined $tk);
	my $ent = shift;
	die "tk_show_saves(): need entity!" if (!defined $ent);
	my $dlg = $tk->DialogBox(
		-title => 'ST ' . $ent->name,
		-buttons => [qw/Ok Cancel/],
		-default_button => 'Ok',
	);
	$dlg->Subwidget('top')->Label(
		-text => 'Does ' . $ent->name . ' save vs ' . $S->name . '?',
	)->pack(
		-side=>'top',
		-fill=>'x',
		-expand=>1,
	);
	my $rc = $dlg->Show;
	return 0 if $rc =~ /cancel/i;
	$S->until(-2);
	return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
