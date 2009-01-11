#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Quagmire::Encounter;
use Quagmire::Entity::PDF;
our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

sub usage {
        warn "Error: @_\n" if (@_);
        print "Usage: $0 encounter.yaml entities.pdf\n";
        print " Will load encounter.yaml and create a PDF for all the entities in the encounter\n";
        exit;
}

my $encfn = shift;
usage("need encounter file name") if (!defined $encfn);
usage("encounter file name does not exist") if (!-f $encfn);
my $pdffn = shift;
usage("need pdf output file name") if (!defined $pdffn);

my $enc = Quagmire::Encounter->load($encfn);
my $pdf = Quagmire::Entity::PDF->new(
	filename=>$pdffn,
	entities => $enc->entities,
);
print "Done\n";

