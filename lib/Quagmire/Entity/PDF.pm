package Quagmire::Entity::PDF;
use Quagmire::Entity;
use Quagmire::Encounter;
use Quagmire::Encounter::PDF;
use Moose;
require PDF::API2::Simple;
our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

=head1 EXAMPLES

my $ent = Quagmire::Entity->load('test.entity');
# or:
# my $ent = $encounter->monsters->entities->[3];
my $pdf = Quagmire::Entity::PDF->new(
	filename => 'test.pdf',
	entity => $ent,
);
# file saved

=head1 new() PARAMETERS

=over 4

=item entity

Needs a Quagmire::Entity. Must be provided at class creation, is read-only.

=item filename

Needs a Str containing a file name. Must be provided at class creation, is read-only.

=back

=cut

our $DEBUG = 0;

has 'entities' => (is=>'ro',isa=>'ArrayRef[Quagmire::Entity]',required=>1);
has 'filename' => (is=>'ro',isa=>'Str',required=>1);

has '_pdf' => (is=>'rw',isa=>'PDF::API2::Simple',required=>1,lazy=>1,default=>sub{
	my $S = shift;
	my $pdf = new PDF::API2::Simple(file => $S->filename());
	$pdf->add_page();
	$pdf->add_font('Helvetica');
	$pdf->add_font('HelveticaBold');
	$pdf->add_font('Courier');
	return $pdf;
});

sub BUILD {
	my $S = shift;
	my $mobn = 0;
	foreach my $ent (@{$S->entities}) {
		if ($mobn > 3) {
			$S->_pdf->add_page();
			$mobn = 0;
		}
		$S->pdf_entity($ent,int($mobn/2),int($mobn%2));
		$mobn++;
	}
	$S->_pdf->saveas();
}

=head2 pdf_entity

Outputs an entity to the chosen PDF file

=cut

sub pdf_entity {
	my $S = shift;
	my $entity = shift;
	my $nx = shift;
	my $ny = shift;
	$nx = 0 if (!defined($nx));
	$ny = 0 if (!defined($ny));
	my $pdf = $S->_pdf;
	my $TOOLTIP_FONT_SIZE = 6;
	my $VALUE_FONT_SIZE = 9;
	$DEBUG and print "PDF stats:\n",
		"X: ", $pdf->x, " Y: ", $pdf->y, "\n",
		"width: ", $pdf->width, "\n",
		"effective_width: ", $pdf->effective_width, "\n",
		"height: ", $pdf->height, "\n",
		"effective_height: ", $pdf->effective_height, "\n",
		"line_height: ", $pdf->line_height, "\n",
		"margin_left: ", $pdf->margin_left, "\n",
		"margin_right: ", $pdf->margin_right, "\n",
		"margin_top: ", $pdf->margin_top, "\n",
		"margin_bottom: ", $pdf->margin_bottom, "\n",
		'';
	my $LOC_SHEET_WIDTH = ($pdf->effective_width/2);
	my $LOC_SHEET_HEIGHT = ($pdf->effective_height/2);
	my $SHEET_WIDTH = $LOC_SHEET_WIDTH - 3;
	my $SHEET_HEIGHT = $LOC_SHEET_HEIGHT - 3;
	my $_curx = $pdf->margin_right + $nx*$LOC_SHEET_WIDTH;
	my $_cury = $pdf->height - $pdf->margin_top - $ny*$LOC_SHEET_HEIGHT;
	my $CLN = 0; # Current Line Number (for text)
	# character box, whole thing
	$pdf->rect(x => $_curx, y => $_cury,
		to_x => ($_curx+$SHEET_WIDTH),
		to_y => ($_cury-$SHEET_HEIGHT), # half page, 0,0
		stroke => 'on',
	);
	# header box, top
	$pdf->rect(x => $_curx, y => $_cury,
		to_x => ($_curx+$SHEET_WIDTH), # half page, 0,0
		to_y => ($_cury-(2*$pdf->line_height)), # half page, 0,0
		stroke => 'on',
	);
	# Name text (next to initiative count, middle)
	$CLN = $pdf->line_height; # 1
	my $name = $entity->name();
	if ($entity->monster) {
		$name .= ' -- ' . $entity->page();
	}
	$pdf->text('Name: ', x => ($_curx+$SHEET_WIDTH/8)+2, y => $_cury - $CLN - $CLN/2 +1,
		align => 'left', font => 'Helvetica', font_size => $TOOLTIP_FONT_SIZE, fill_color => 'black',
	);
	# Name value
	$pdf->text($name, x => ($_curx+$SHEET_WIDTH/8*2)+2, y => $_cury - $CLN - $CLN/2+1,
		align => 'left', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
	);
	# initiative count (left)
	$CLN = 2*$pdf->line_height; # 2
	$pdf->rect(x => $_curx, y => $_cury,
		to_x => ($_curx+$SHEET_WIDTH/8), # half page, 0,0
		to_y => ($_cury-$CLN), # half page, 0,0
		stroke => 'on',
	);
	# Initiative count text (left)
	{
		my $initiative = "Initiative ";
		$initiative .= $entity->initiative_bonus() if ($entity->monster);
		$DEBUG and print "Initiative text: >$initiative<\n";
		$pdf->text($initiative, x => $_curx + 2, y => $_cury - $CLN +1,
			align => 'left', font => 'Helvetica', font_size => $TOOLTIP_FONT_SIZE, fill_color => 'black',
		);
	}
	# xp (right)
	$CLN = 2*$pdf->line_height; # 2
	$pdf->rect(
		x => ($_curx+$SHEET_WIDTH/8*7),
		y => $_cury,
		to_x => ($_curx+$SHEET_WIDTH), # half page, 0,0
		to_y => ($_cury-$CLN), # half page, 0,0
		stroke => 'on',
	);
	if ($entity->monster) {
		# XP text
		$pdf->text('XP', x => ($_curx+$SHEET_WIDTH-2), y => $_cury - $CLN+1,
			align => 'right', font => 'Helvetica', font_size => $TOOLTIP_FONT_SIZE, fill_color => 'black',
		);
		my $xp = $entity->xp();
		$pdf->text($xp, x => ($_curx+$SHEET_WIDTH-2), y=>$_cury-$CLN/2,
			align=>'right',font=>'Helvetica',font_size=>$VALUE_FONT_SIZE,fill_color=>'black',
		);
	}
	# HP (right)
	$CLN += $pdf->line_height*1;
	$pdf->rect(
		x => ($_curx+$SHEET_WIDTH/8*7),
		y => $_cury - $CLN,
		to_x => ($_curx+$SHEET_WIDTH), # half page, 0,0
		to_y => ($_cury-($CLN+2*$pdf->line_height)), # half page, 0,0
		stroke => 'on',
	);
	# HP VALUE text
	$CLN += $pdf->line_height; # from last to_y
	$pdf->text($entity->hp(),
		x => ($_curx+$SHEET_WIDTH-2), y => $_cury - $CLN+1,
		align => 'right', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
	);
	$CLN += $pdf->line_height;
	# HP text
	$pdf->text('HP',#'Hit Points',
		x => ($_curx+$SHEET_WIDTH-2), y => $_cury - $CLN+1,
		align => 'right', font => 'Helvetica', font_size => $TOOLTIP_FONT_SIZE, fill_color => 'black',
	);
	$CLN += $pdf->line_height;
	# Bloodied (right)
	$pdf->rect(
		x => ($_curx+$SHEET_WIDTH/8*7),
		y => $_cury - $CLN,
		to_x => ($_curx+$SHEET_WIDTH), # half page, 0,0
		to_y => ($_cury-($CLN+2*$pdf->line_height)), # half page, 0,0
		stroke => 'on',
	);
	{
		use integer; # instead of floor()
		# Bloodied VALUE text
		$CLN += $pdf->line_height; # from last to_y
		$pdf->text($entity->hp()/2,#'Hit Points',
			x => ($_curx+$SHEET_WIDTH-2), y => $_cury - $CLN+1,
			align => 'right', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
		);
	}
	$CLN += $pdf->line_height; # from last to_y
	# Bloodied text
	$pdf->text('Bloodied', x => ($_curx+$SHEET_WIDTH-2), y => $_cury - $CLN+1,
		align => 'right', font => 'Helvetica', font_size => $TOOLTIP_FONT_SIZE, fill_color => 'black',
	);

	$CLN = $pdf->line_height * 3;
	$pdf = Quagmire::Encounter::PDF::defenses($entity, $pdf, $_curx+10,$_cury-$CLN, ($SHEET_WIDTH/6),2*$pdf->line_height,$TOOLTIP_FONT_SIZE,$VALUE_FONT_SIZE);

	# abilities
	$CLN += $pdf->line_height * 3;
	my $defx = $_curx+10;
	foreach my $abiname (qw/str con dex int wis cha/) {
		my $abival = $entity->$abiname();
		my $abimod;
		if ($entity->monster) {
			my $f = "${abiname}_mod";
			$abimod = $entity->$f();
		} else {
			$abimod = $entity->modifier($abival);
			$abimod = "+$abimod" if ($abimod >= 0);
		}
		my $abitxt = "$abival ($abimod)";
		$pdf->rect(
			x => $defx,
			y => $_cury - $CLN,
			to_x => ($defx+($SHEET_WIDTH/8)),
			to_y => ($_cury-($CLN+2*$pdf->line_height)),
			stroke => 'on',
		);
		# ability value
		$pdf->text($abitxt, x => ($defx+2+($SHEET_WIDTH/9)/2), y => $_cury - $CLN -$pdf->line_height*1.25+1,
			align => 'center', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
		);
		# ability name
		$pdf->text($abiname, x => ($defx+2+($SHEET_WIDTH/9)/2), y => $_cury - $CLN - 2*$pdf->line_height+1,
			align => 'center', font => 'Helvetica', font_size => $TOOLTIP_FONT_SIZE, fill_color => 'black',
		);
		$defx += ($SHEET_WIDTH/9*1.2);
	}
	# hp matrix
	$CLN += $pdf->line_height*3;
	$pdf = Quagmire::Encounter::PDF::hp_matrix($entity,$pdf, 30, # 20 per row
		#$_curx + 5,
		$_curx,
		$_cury - $CLN,
		$SHEET_WIDTH * 1
	);

=for TODO: working powers

	my $_CLN;

	if ($entity->monster and $DEBUG) {
		$_CLN = $_cury - $CLN - $pdf->line_height*2.5*($entity->hp()/20 +1);
		# shows powers and stuff
		foreach my $p (sort keys %{$entity->{powers}}) {
			$pdf->text("$p:",x => $_curx+2, y => $_CLN, align => 'left',
				font => 'Helvetica', font_size => 7, fill_color => 'black');
			$_CLN -= $pdf->line_height;

			#my $powerstr = Data::Dumper::Dumper($entity->{powers}->{$p});
			my $powerstr = YAML::Dump($entity->{powers}->{$p});
			$powerstr =~ s/\s+/\ /;
			my @str = split(/\n/,$powerstr);
			foreach my $str (@str) {
				$pdf->text($str,x => $_curx+2, y => $_CLN, align => 'left',
					font => 'Helvetica', font_size => 5, fill_color => 'black');
				$_CLN -= $pdf->line_height;
			}
		}
	}
	if (!$entity->monster) {
		$_CLN = $_cury - $CLN -$pdf->line_height - $pdf->line_height*1.5*(int($entity->hp()/20)+1.5);
		foreach my $f (@{$entity->{feats}}) {
			$pdf->text("Feat: $f", x => $_curx+2, y => $_CLN, align => 'left',
				font => 'Helvetica', font_size => 7, fill_color => 'black');
			$_CLN -= $pdf->line_height;
		}
		foreach my $p (@{$entity->{powers}}) {
			my $powertext = "Power: $p ";
			if (defined($DnD4::Powers::POWERS{$p})) {
				my $POWER = $DnD4::Powers::POWERS{$p};
				$powertext .= " " . ucfirst($POWER->{race}) if (defined($POWER->{race}) && $POWER->{race} ne '');
				$powertext .= " " . ucfirst($POWER->{class}) if (defined($POWER->{class}) && $POWER->{class} ne '');
				$powertext .= " " . ucfirst($POWER->{usage}->{times}) . "x" if (defined($POWER->{usage}) && defined($POWER->{usage}->{times}));
				$powertext .= " " . ucfirst($POWER->{usage}->{usage}) if (defined($POWER->{usage}) && defined($POWER->{usage}->{usage}));
				$powertext .= " L $POWER->{level}" if (defined($POWER->{level}) && $POWER->{level} ne '');
				$powertext .= " " . $POWER->{attack} . " vs " . $POWER->{defense} if (defined($POWER->{attack}) && defined($POWER->{defense}));
				$powertext .= " D:" . $POWER->{on_hit}->{damage} if (defined($POWER->{on_hit}) && defined($POWER->{on_hit}->{damage}));
				if (
					defined($POWER->{usage}) && defined($POWER->{usage}->{usage}) && ($POWER->{usage}->{usage} !~ /will/) &&
					defined($POWER->{usage}) && defined($POWER->{usage}->{times})) {
					$powertext .= " [   ]" x $POWER->{usage}->{times} if ($POWER->{usage}->{times} =~ /^\d+$/);
				}
			}
			$pdf->text("$powertext", x => $_curx+2, y => $_CLN, align => 'left',
				font => 'Helvetica', font_size => 7, fill_color => 'black');
			$_CLN -= $pdf->line_height;
		}
		foreach my $i (@{$entity->{items}}) {
			my $itemtext = "Item: $i";
			my $itemdaily = '';
			my $itemproperty = '';
			if (defined($DnD4::Items::ITEMS{$i})) {
				my $ITEM = $DnD4::Items::ITEMS{$i};
				my $dmg = $ITEM->total_damage();
				$itemtext .= " [$dmg]" if (defined($dmg) && $dmg !~ /^\+/);
				my $ac = $ITEM->total_defense_bonus('ac');
				$itemtext .= " [+$ac AC]" if ($ac != 0);
				$itemproperty = $ITEM->{property} if (defined($ITEM->{property}));
				if (defined($ITEM->{power}) && defined($ITEM->{power}->{daily})) {
					my $kwd = defined($ITEM->{power}->{daily}->{keyword}) ? $ITEM->{power}->{daily}->{keyword} : '';
					my $act = defined($ITEM->{power}->{daily}->{action}) ? $ITEM->{power}->{daily}->{action} : '';
					my $eff = defined($ITEM->{power}->{daily}->{effect}) ? $ITEM->{power}->{daily}->{effect} : '';
					$itemdaily .= "[$kwd] " if ($kwd ne '');
					$itemdaily .= "[$act] " if ($act ne '');
					$itemdaily .= "** $eff" if ($eff ne '');
				}
			}
			$pdf->text("$itemtext", x => $_curx+2, y => $_CLN, align => 'left',
				font => 'Helvetica', font_size => 7, fill_color => 'black');
			$_CLN -= $pdf->line_height;
			if ($itemproperty ne '') {
				$pdf->text("PROPERTY: $itemproperty", x => $_curx+7, y => $_CLN, align => 'left',
					font => 'Helvetica', font_size => 5, fill_color => 'black');
				$_CLN -= $pdf->line_height;
			}
			if ($itemdaily ne '') {
				$pdf->text("DAILY: $itemdaily", x => $_curx+7, y => $_CLN, align => 'left',
					font => 'Helvetica', font_size => 5, fill_color => 'black');
				$_CLN -= $pdf->line_height;
			}
		}
	}

=cut

	#$pdf->saveas();
	return $pdf;
}

__PACKAGE__->meta->make_immutable();
1;
