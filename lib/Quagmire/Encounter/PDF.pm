package Quagmire::Encounter::PDF;
use Quagmire::Encounter;
use Quagmire::Entity;
use Moose;
require PDF::API2::Simple;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

=head1 EXAMPLES

my $enc = Quagmire::Encounter->load('test.encounter');
my $pdf = Quagmire::Encounter::PDF->new(
	filename => 'test.pdf',
	encounter => $enc,
);
# file saved

=head1 new() PARAMETERS

=over 4

=item encounter

Needs a Quagmire::Encounter. Must be provided at class creation, is read-only.

=item filename

Needs a Str containing a file name. Must be provided at class creation, is read-only.

=back

=cut

our $DEBUG = 0;

has 'encounter' => (is=>'ro',isa=>'Quagmire::Encounter',required=>1);
has 'filename' => (is=>'ro',isa=>'Str',required=>1);

has '_pdf' => (is=>'rw',isa=>'PDF::API2::Simple',required=>1,lazy=>1,default=>sub{
	my $S = shift;
	my $pdf = new PDF::API2::Simple(file => $S->filename());
	$pdf->add_page();
	#{{{ sets LANDSCAPE:
	my $w = $pdf->height;
	my $h = $pdf->width;
	$pdf->height($h);
	$pdf->width($w);
	$pdf->pdf->mediabox( $w, $h );
	$pdf->_set_relative_values();
	$pdf->_reset_x_and_y();
	#}}} end sets LANDSCAPE
	$pdf->add_font('Helvetica');
	$pdf->add_font('HelveticaBold');
	$pdf->add_font('Courier');
	return $pdf;
});
has '_should_do_players' => (is=>'rw',isa=>'Num',required=>1,default=>1);

our $MAXENTITIES = 12; # 8

sub BUILD {
	my $S = shift;
	my $n_players = $#{$S->encounter->party->entities}+1;
	my $n_monsters = $#{$S->encounter->monsters->entities}+1;
	if ($n_players + $n_monsters > $MAXENTITIES) {
		warn('PDF may come out crowded when using more than ', $MAXENTITIES, ' entities. Will not be printing out player characters.',"\n");
		$S->_should_do_players(0); # only monsters will be outputed
	}
	my $col = 0;
	foreach my $ent (@{$S->encounter->entities}) {
		$col = $S->pdf_encounter($ent,$col);
		$col++;
	}
	$S->finalize_encounter();
}

=head2 hp_matrix

Returns an HP matrix, outlining max hp and bloodied values, on the pdf passed.

=cut

sub hp_matrix {
	my ($char, $pdf, $hp_per_row,$_start_x, $_y, $_width) = @_;
	$DEBUG and print "hp_matrix ($hp_per_row per row) done on X $_start_x Y $_y\n";
	my $_x = $_start_x;
	if (!defined($_width)) {
		$_width = 12.75;
	} else {
		$_x += ($_width * 5/100);
		$_width /= $hp_per_row;
		$_width *= 0.90;
	}
	my $mhp = $char->hp();
	my $bloodied;
	if (defined($char->{bloodied})) {
		$bloodied = $char->{bloodied};
	} else {
		use integer;
		$bloodied = $mhp/2;
	}
	#print "max hp: $mhp Bloodied: $bloodied\n";
	my $W = $_width;
	my $H = $_width;
	my $rows = $mhp / $hp_per_row + 1; #every row is 10 hp, plus the 3 ts/death
	my $currhp = 1;
	local $|=1;
	my $row = 0;
	#print "Should do $rows rows\n";
	# row for three TS vs death
	for my $tsdn (0..2) {
		$pdf->rect(x => $_x + $tsdn*$W, y => $_y-($row*$H), to_x => $_x + $tsdn*$W+$W, to_y => $_y-($row*$H)-$H,
			stroke => 'on',fill_color=>'#E0E0E0',fill=>'yes',width => 0.8);
		$pdf->text('D' . ($tsdn+1),x => $_x + $tsdn*$W+2, y => $_y-($row*$H)-$H/2,align => 'left',font => 'Helvetica',font_size=>5);
	}
	$row++;
	# HP rows
	while ($row < $rows) { # writes down a row
		#print "Row $row.. ";
		# how many HP in this row?
		my $hp_in_row = ($currhp + ($hp_per_row-1) >= $mhp) ? $mhp - $currhp + 1 : ($hp_per_row);
		#print "HP in row: $hp_in_row\n";
		foreach my $hp (0..$hp_in_row-1) {
			#print "hp $hp (curr: $currhp).. ";
			# writes one hp box, increasing $currhp
			my $block;
			{use integer; $block = ($hp) / $hp_per_row;}
			my $__x = $_x+$hp*$W + ($block*$W/2);
			my $__y = $_y-($row*$H);
			if ($currhp == $mhp || $currhp == $bloodied) {
				$pdf->rect(x => $__x, y => $__y, to_x => $__x + $W, to_y => $__y-$H,stroke => 'on',fill_color=>'grey',fill=>'yes');
			} else {
				$pdf->rect(x => $__x, y => $__y, to_x => $__x + $W, to_y => $__y-$H,stroke => 'on');
			}
			$pdf->text($currhp, x =>$__x, y => $__y - $H/2, align => 'left',font => 'Helvetica',font_size=>5, fill_color => 'black');
			$currhp++;
			$hp++;
		}
		$row++;
	}

	return $pdf;
}

=head2 finalize_encounter

Finalizes the encounter pdf, by calculating xp total and writing the name of the encounter.
Also, saves the pdf

=cut

sub finalize_encounter {
	my ($S) = @_;
	my $pdf = $S->_pdf;
        my $_curx = $pdf->margin_right;
        my $_cury = $pdf->height - $pdf->margin_top;

        my $LOC_SHEET_WIDTH = ($pdf->effective_width/$MAXENTITIES);
        my $LOC_SHEET_HEIGHT = ($pdf->effective_height);
        my $SHEET_WIDTH = $LOC_SHEET_WIDTH - 3;
        my $SHEET_HEIGHT = $LOC_SHEET_HEIGHT - 3;

	my $TOOLTIP_FONT_SIZE = 6;
	my $VALUE_FONT_SIZE = 9;

        my $_width = $SHEET_WIDTH*($MAXENTITIES-1)/25;

	# Creates the encounter matrix on top (showing rounds count)
	$pdf = encounter_matrix($pdf,25,$_curx, $_cury, $_width);

	# Name of the encounter
        $pdf->text($S->encounter->monsters->name,x => $pdf->effective_width-2, y=> $_cury - $pdf->line_height,
        	align => 'right', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
        );

	# XP of the encounter
	my $xp_total = 0;
	map {$xp_total += $_->xp} @{$S->encounter->monsters->entities};
	if ($xp_total) {
	        $pdf->text($xp_total . ' xp',x => $pdf->effective_width-2, y=> $_cury - $pdf->line_height*2,
        		align => 'right', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
	        );
	}

	$pdf->saveas();
	return $pdf;
}

=head2 encounter_matrix

Creates the round ticker on top of the page

=cut

sub encounter_matrix {
	my ($pdf,$rounds,$_x, $_y, $_width) = @_;
	$DEBUG and print "encounter_matrix ($rounds per row) done on X $_x Y $_y\n";
	$_width = 12.75 if (!defined($_width));
	my $W = $_width;
	my $H = $_width;
	foreach my $rnd (0..$rounds-1) {
		my $__x = $_x+$rnd*$W;
		my $__y = $_y;
		if ($rnd==0 || ($rnd+1) % 5 == 0) {
			$pdf->rect(x => $__x, y => $__y, to_x => $__x + $W, to_y => $__y-$H,stroke => 'on',fill_color=>'grey',fill=>'yes');
		} else {
			$pdf->rect(x => $__x, y => $__y, to_x => $__x + $W, to_y => $__y-$H,stroke => 'on');
		}
		$pdf->text(($rnd+1), x =>$__x+ ($W/2), y => $__y - $H/2, align => 'center',font => 'Helvetica',font_size=>7, fill_color => 'black');
	}
	return $pdf;
}

=head2 defenses

Creates a matrix of all defenses on a pdf

=cut

sub defenses {
	my ($char, $pdf, $_start_x, $_y, $_width,$_height,$_tooltipsize,$_valuesize) = @_;
	my $defx = $_start_x + ($_width * 20/100);
	foreach my $defname (qw/ac ref fort will/) {
		my $defvalue = $char->$defname();
		$pdf->rect(
			x => $defx,
			y => $_y,
			to_x => ($defx+$_width),
			to_y => ($_y-$_height),
			stroke => 'on',
		);
		# defense value
		$pdf->text($defvalue, x => ($defx+2+$_width/2), y => $_y - $_height/2*1.25+1,
			align => 'center', font => 'Helvetica', font_size => $_valuesize, fill_color => 'black',
		);
		# defense name
		$pdf->text($defname, x => ($defx+2+$_width/2), y => $_y - $_height+1,
			align => 'center', font => 'Helvetica', font_size => $_tooltipsize, fill_color => 'black',
		);
		$defx += $_width*1.2;
	}
	return $pdf;
}

=head2 pdf_encounter

Outputs a PDF for an encounter tracking

=cut

sub pdf_encounter {
	my $S = shift;
	my $ent = shift or confess("need entity");
	my $nx = shift;
	$nx = 0 if (!defined($nx));
	my $TOOLTIP_FONT_SIZE = 6;
	my $VALUE_FONT_SIZE = 9;
	my $pdf = $S->_pdf;
	my $maxentities = $S->_should_do_players ? scalar @{$S->encounter->entities} : scalar @{$S->encounter->monsters};
	$maxentities = 8 if ($maxentities<8);

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

	my $LOC_SHEET_WIDTH = ($pdf->effective_width/$maxentities);
	my $LOC_SHEET_HEIGHT = ($pdf->effective_height);
	my $SHEET_WIDTH = $LOC_SHEET_WIDTH - 3;
	my $SHEET_HEIGHT = $LOC_SHEET_HEIGHT - 3;
	my $_curx = $pdf->margin_right + $nx*$LOC_SHEET_WIDTH;
	my $_cury = $pdf->height - $pdf->margin_top;

	$DEBUG and print "Curx: $_curx  Cury: $_cury\n";

	my $_width = $SHEET_WIDTH*($maxentities-1)/25;
	$_cury -= $_width + $pdf->line_height/2;

	# character box, whole thing
	$pdf->rect(x => $_curx, y => $_cury,
		to_x => ($_curx+$SHEET_WIDTH),
		to_y => ($_cury-$SHEET_HEIGHT),
		stroke => 'on',
	);

	my $CLN = 0; # Current Line Number (for text)

	# Name
	$CLN += $pdf->line_height;
	$pdf->line(x => $_curx+2, y => $_cury-$CLN,to_x =>($_curx+$SHEET_WIDTH)-2,to_y =>$_cury-$CLN);
	$pdf->text($ent->name(),
		x => $_curx + $SHEET_WIDTH/2 , y =>$_cury-$CLN+2,
		align => 'center', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
	);
	$CLN += $pdf->line_height;
	if ($ent->monster) {
		my $txt = $ent->xp() . ' xp';
		$txt .= ' -- ' . $ent->page() if ($ent->page());
		$pdf->text($txt,
			x => $_curx + $SHEET_WIDTH/2 , y =>$_cury-$CLN+2,
			align => 'center', font => 'Helvetica', font_size => $VALUE_FONT_SIZE, fill_color => 'black',
		);
	}
	$pdf->line(x => $_curx+2, y => $_cury-$CLN,to_x =>($_curx+$SHEET_WIDTH)-2,to_y =>$_cury-$CLN);

	$CLN += $pdf->line_height;
	$pdf = defenses($ent, $pdf, $_curx,$_cury-$CLN, ($SHEET_WIDTH/5),2*$pdf->line_height,$TOOLTIP_FONT_SIZE,$VALUE_FONT_SIZE);

	$CLN += $pdf->line_height*2;
	$pdf = hp_matrix($ent,$pdf, 7, # hp per row
		$_curx,# 5,
		$_cury - $CLN - 2,
		# 16.50
		$SHEET_WIDTH
	);
	return $nx;
}

__PACKAGE__->meta->make_immutable();
1;
