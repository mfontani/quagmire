package Quagmire;
use Moose;
use Carp;
use File::Basename;
use Tk;
use Tk::LabFrame;
use Tk::HList;
use Tk::ItemStyle;
use Tk::FileSelect;
use Quagmire::Encounter;
use Quagmire::GUI::Tk::Initiative;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

has 'encounter' => (is=>'rw',isa=>'Quagmire::Encounter',required=>1,default=>sub{Quagmire::Encounter->new});

has 'window' => (is=>'ro',isa=>'Any',required=>1,default=>sub{
	my $mw = MainWindow->new(
		-title => 'Quagmire v.' . $VERSION,
		#-width => '850',
	);
	$mw->geometry('850x400');
	Tk::CmdLine::SetArguments();
	return $mw;
});

has '_status' => (is=>'rw',isa=>'Any',required=>1,default=>'');

has '_encounter_frame' => (is=>'rw',isa=>'Any',required=>1,default=>'');
has '_initiative_frame' => (is=>'rw',isa=>'Any',required=>1,default=>'');
has '_entity_frame' => (is=>'rw',isa=>'Any',required=>1,default=>'');

has '_tk_menu' => (is=>'rw',isa=>'Any',required=>1,default=>'');
has '_tk_initiative' => (is=>'rw',isa=>'Any',required=>1,default=>'');
has '_tk_entity' => (is=>'rw',isa=>'Any',required=>1,default=>'');

has '_tk_roundno' => (is=>'rw',isa=>'Any',required=>1,default=>'');
has '_tk_roundwho' => (is=>'rw',isa=>'Any',required=>1,default=>'');
has '_tk_roundnext' => (is=>'rw',isa=>'Any',required=>1,default=>'');

sub refresh {
	my $s = shift;
	$s->_tk_roundno->configure(-text => "Round #" . $s->encounter->status->round);
	$s->_tk_roundwho->configure(-text => 'Turn: ' .
		(defined $s->encounter->turn ? $s->encounter->turn->name : '?')
	);
	$s->_tk_roundnext->configure(-text => 'Next: ' . $s->encounter->next('pretend')->name);
	return $s;
}

sub status {
	my $s = shift;
	my $txt = "@_";
	chomp($txt);
	$s->_status->configure(-text => $txt);
	return $s;
}

sub info {
	my $s = shift;
	my $title = shift or die "info(): need title";
	my $msg = shift or die "info(): need message";
	my $dlg = $s->window->DialogBox(
		-title => $title,
		-buttons => [qw/Ok/],
		-default_button => 'Ok',
	);
	$dlg->Subwidget('top')->Label(-text=>$msg)->pack(-side=>'top',-fill=>'x',-expand=>1);
	return $dlg->Show;
}

sub BUILD {
	my $s = shift;
	#$s->_init_menu();
	my $tk = $s->window;
	$s->_status(
		$tk->Frame( # gives the relief and border to the label
			-borderwidth=>1,-relief=>'sunken'
		)->pack(
			-fill=>'x',-side=>'bottom',-anchor=>'nw'
		)->Label( # aligns left
			-height=>1,
		)->pack(
			-side => 'top',-anchor=>'nw',
		)
	);
	my $parentpaned = $tk->Panedwindow(
		-showhandle=>1, -orient=>'horizontal',
	)->pack(-fill=>'both',-expand=>1);
	$s->_encounter_frame($tk->LabFrame(-label=>'Encounter'));
	$parentpaned->add($s->_encounter_frame);
	my $rightpaned = $tk->Panedwindow(
		-showhandle=>1,-orient=>'vertical',
	)->pack(-fill=>'both',-expand=>1,-anchor=>'nw');
	#$s->_party_frame($tk->LabFrame(-label=>'Party'));
	$s->_initiative_frame($tk->Frame);
	$rightpaned->add($s->_initiative_frame);
	#$s->_entity_frame($tk->LabFrame(-label=>'Entity'));
	$s->_entity_frame($tk->Toplevel(title=>'test'));
	#$rightpaned->add($s->_entity_frame);
	$s->_entity_frame->protocol('WM_DELETE_WINDOW',[sub{shift->withdraw},$s->_entity_frame]);
	$s->_entity_frame->withdraw;
	$parentpaned->add($rightpaned);
	$s->_tk_initiative(
		Quagmire::GUI::Tk::Initiative->new(
			quagmire=>$s,
			window=>$s->_initiative_frame,
			encounter => $s->encounter,
		)
	);
	$s->_tk_initiative->tk->pack(-fill=>'both',-expand=>1);
	$s->reconfigure_tk_initiative;
	$s->_tk_entity(
		Quagmire::GUI::Tk::Entity->new(
			quagmire=>$s,
			set_title=>0,
			display_commit=>0,
			window=>$s->_entity_frame
		)
	);
	$s->_tk_entity->tk->pack(-fill=>'both',-expand=>1);
	$s->reconfigure_tk_initiative;
	$s->reconfigure_tk_entity;
	$s->init_encounter_tab;
	$s->status('loaded');
	$s->refresh;
	return $s;
}

sub load_encounter {
	my ($s, $fn) = @_;
	if (!defined $fn || !-f $fn) {
		$s->status('Error: new encounter file name does not exist');
		return $s;
	}
	my $rc = eval{$s->encounter(Quagmire::Encounter->load($fn))};
	if ($@) {
		my $err = $@;
		$s->status('Error loading encounter from file ',$fn);
		carp 'Error loading encounter from file',$fn,': ',$err;
		return $s;
	}
	$s->_tk_initiative->encounter($s->encounter);
	$s->_tk_initiative->refresh();
	$s->refresh;
	$s->status('Loaded encounter from file ', $fn);
}

sub init_encounter_tab {
	my $s = shift;
	my $nb = $s->_encounter_frame->NoteBook->pack(
		-fill => 'both',
		-expand => 1,
	);
	my $nb_g = $nb->add('General', -label => 'General');
	$s->_tk_roundno(
		$nb_g->Label(
			-text => "Round ",
		)->pack(-fill=>'x')
	);
	$s->_tk_roundwho(
		$nb_g->Label(
			-text => "Turn ",
		)->pack(-fill=>'x')
	);
	$s->_tk_roundnext(
		$nb_g->Label(
			-text => "Next ",
		)->pack(-fill=>'x')
	);
	$nb_g->Button(
		-text => 'Next entity',
		-command => sub {
			# sets all initiatives if not already set
			my %mob;
			foreach my $ent (@{$s->encounter->entities}) {
				if (!$ent->initiative()) {
					if ($ent->monster() && defined $mob{$ent->name}) {
						$ent->initiative($mob{$ent->name});
						next;
					}
					my $D = Quagmire::Entity::Initiative->new(tk=>$s,entity=>$ent);
					my $r = $D->show();
					$ent->initiative($r);
					if ($ent->monster()) {
						$mob{$ent->name} = $r;
						foreach my $monster (@{$s->encounter->monsters->entities}) {
							$mob{$monster->name} = $monster->initiative if ($monster->initiative());
							$monster->initiative($mob{$monster->name}) if (!$monster->initiative && defined($mob{$monster->name}));
						}
					}
					$s->_tk_initiative->refresh();
				}
			}
			# Anything to save against for current entity?
			my $lastent = $s->encounter->turn;
			if (defined $lastent) {
				foreach my $cond (@{$lastent->conditions},@{$lastent->ongoing}) {
					if ($cond->until >0 && $cond->until <= $s->encounter->status->round) {
						$s->info($lastent->name,'Is no longer affected by ' . $cond->name);
						$cond->until(-2);
					}
					if ($cond->until == -1) { # save ends
						$cond->tk_show_saves($s->window,$lastent);
					}
				}
				$lastent->update_conditions();
			}
			# NEXT ENTITY!
			my $ent = $s->encounter->next;
			return if (!defined $ent);
			foreach my $ong (@{$ent->ongoing}) {
				$ong->show(); # also deals damage/heals if wanted
			}
			$s->_tk_initiative->refresh($ent);
			$s->refresh;
		}
	)->pack(-fill=>'x');

	#### ADMIN
	my $nb_a = $nb->add('Admin', -label => 'Admin');
	$s->window->bind('<Alt-a>',sub{$nb->raise('Admin');$nb_a->focus;});
	$nb_a->Button(
		-text => "Load new encounter",
		-command => sub {
			my $fd = $s->window->FileSelect(
				#-defaultextension => 'yaml',
			);
			my $fn = $fd->Show();
			$s->load_encounter($fn);
		}
	)->pack(-fill=>'x');
	$nb_a->Button(
		-text=>'Save Encounter',
		-command=>sub {
			warn "Save Encounter\n";
			if (! $s->encounter->status->filename) {
				my $fd = $s->window->FileSelect(
				);
				my $fn = $fd->Show();
				return $s if (!defined $fn);
				$s->encounter->status->filename($fn);
			} elsif (!-f $s->encounter->status->filename) {
				my $fd = $s->window->FileSelect(
					-directory => dirname($s->encounter->status->filename), # start dir
				);
				my $fn = $fd->Show();
				return $s if (!defined $fn);
				$s->encounter->status->filename($fn);
			} else {
				# non-empty and is a file: good as-is
			}
			$s->encounter->store(
				$s->encounter->status->filename
			);
		}
	)->pack(-fill=>'x');
	$nb_a->Button(
		-text => 'Reset Encounter',
		-command => sub {
			carp "Reset encounter!"
		}
	)->pack(-fill=>'x');
	$nb_a->Button(
		-text=>'Quit',
		-command=>sub{
			my $choice = $s->window->Dialog(
				-title => 'Quitting...',
				-text => "Are you sure?",
				-default_button => 'No',
				-buttons => [qw/Yes No/],
			)->Show;
			$s->window->destroy if ($choice eq 'Yes');
		},
	)->pack(-side=>'bottom',-fill=>'x');

	$nb_a->Button(
		-text=>'Load/Replace Party',
		-command=>sub {
			my $fd = $s->window->FileSelect(
				-directory => dirname($s->encounter->status->filename), # start dir
			);
			my $fn = $fd->Show();
			return $s if (!defined $fn);
			my $p;
			eval {$p = Quagmire::Party->load($fn);};
			my $err= $@;
			if ($err) {
				$s->status('Problems loading party: ' . $err);
				return;
			}
			$s->encounter->party->clone_from($p);
			$s->_tk_initiative->refresh();
			$s->status('Loaded party from ' . $fn);
		},
	)->pack(-side=>'bottom',-fill=>'x');
	$nb_a->Button(
		-text=>'Save Party',
		-command=>sub {
			my $fd = $s->window->FileSelect(
				-directory => dirname($s->encounter->status->filename), # start dir
			);
			my $fn = $fd->Show();
			return $s if (!defined $fn);
			$s->encounter->party->store($fn);
			$s->status('Saved party as ' . $fn);
		}
	)->pack(-side=>'bottom',-fill=>'x');

	$nb_a->Button(
		-text=>'Load/Replace Monsters',
		-command=>sub {
			my $fd = $s->window->FileSelect(
				-directory => dirname($s->encounter->status->filename), # start dir
			);
			my $fn = $fd->Show();
			return $s if (!defined $fn);
			my $p;
			eval {$p = Quagmire::Party->load($fn);};
			my $err= $@;
			if ($err) {
				$s->status('Problems loading monsters: ' . $err);
				return;
			}
			$s->encounter->monsters->clone_from($p);
			$s->_tk_initiative->refresh();
			$s->status('Loaded monsters from ' . $fn);
		},
	)->pack(-side=>'bottom',-fill=>'x');
	$nb_a->Button(
		-text=>'Save Monsters',
		-command=>sub {
			my $fd = $s->window->FileSelect(
				-directory => dirname($s->encounter->status->filename), # start dir
			);
			my $fn = $fd->Show();
			return $s if (!defined $fn);
			$s->encounter->monsters->store($fn);
			$s->status('Saved monsters as ' . $fn);
		}
	)->pack(-side=>'bottom',-fill=>'x');

	return $s;
}

sub reconfigure_tk_entity {
	my $s = shift;
	# TODO
	return;
}

sub reconfigure_tk_initiative {
	my $s = shift;
	$s->window->bind('<Alt-i>',sub{$s->_tk_initiative->initiativelist->focus;});
	return;
}

sub _init_menu {
	my ($s) = shift;
	my $m = $s->window->Menubar;
	my $file = $m->Menubutton("-text" => "Encounter","-underline" => 0,-tearoff => 0);
	$file->command("-label","Load new encounter","-command" => sub {
		my $fd = $s->{TK}->FileSelect(
			#-defaultextension => 'yaml',
		);
		my $fn = $fd->Show();
		$s->{ENCOUNTER} = Quagmire::Encounter->new(
			filename => $fn,
		);
	},"-underline" => 0);
	$file->command("-label","Save encounter","-command" => sub { print "Save Encounter\n" },"-underline" => 0);
	$file->separator;
	$file->command("-label","Quit program","-command" => sub { $s->{TK}->destroy },"-underline" => 0);
	$s->_tk_menu($m->pack(-anchor => 'nw'));
	return;
}

sub run {
	my $s = shift;
	$s->window->MainLoop;
	return;
}


1;
