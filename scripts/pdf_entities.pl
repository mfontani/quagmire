#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Getopt::Long;
use Quagmire::Encounter;
use Quagmire::Entity;
use Quagmire::Entity::PDF;
our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

sub usage {
        warn "Error: @_\n" if (@_);
        print "Usage: $0 [OPTIONS] [--encounter 1.yaml[,2.yaml,...]] [--entity 3.yaml,4.yaml] output.pdf\n";
        print "  Will load encounter.yaml and create a PDF for all the entities in the encounters\n";
        print "By default, both players and monsters are printed\n";
        print "OPTIONS: [--no-players][--no-monsters], apply to all encounter files only\n";
        print "Entities added via --entity are always added.\n";
        exit;
}

my $do_players = 1;
my $do_monsters = 1;
my $show_usage = 0;
my @encounters;
my @entities;
my $rc = GetOptions (
        'players!' => \$do_players,
        'monsters!' => \$do_monsters,
        'encounter=s' => \@encounters,
        'entity=s' => \@entities,
        'help|?' => \$show_usage,
);
usage() if (!$rc || $show_usage);
@encounters = split(/,/,join(',',@encounters));
@entities = split(/,/,join(',',@entities));

my $pdf_filename = pop;
usage('need pdf output file name') if (!defined $pdf_filename);

usage('too many arguments: ',@ARGV) if (@ARGV);

usage('need --encounter or --entity specified') if (!@encounters && !@entities);

foreach my $encfn (@encounters) {
        usage("encounter file name", $encfn, "does not exist") if (!-f $encfn);
}
foreach my $entfn (@entities) {
        usage("entity file name", $entfn, "does not exist") if (!-f $entfn);
}

my @entities_to_print;
foreach my $encounter_filename (@encounters) {
        my $encounter = Quagmire::Encounter->load($encounter_filename);
        push (@entities_to_print,@{$encounter->monsters->entities}) if ($do_monsters);
        push (@entities_to_print,@{$encounter->party->entities}) if ($do_players);
}
foreach my $entity_filename (@entities) {
        my $ent = Quagmire::Entity->load($entity_filename);
        push(@entities_to_print,$ent);
}

my $pdf = Quagmire::Entity::PDF->new(
	filename=>$pdf_filename,
	entities => \@entities_to_print,
);
print "Done\n";
