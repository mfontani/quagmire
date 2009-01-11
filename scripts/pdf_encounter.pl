#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Quagmire::Encounter;
use Quagmire::Encounter::PDF;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';

sub usage {
	warn "Error: @_\n" if (@_);
	print "Usage: $0 encounter.yaml encounter.pdf\n";
	print " Will load encounter.yaml and create a PDF for the encounter\n";
	exit;
}

my $encfn = shift;
usage("need encounter file name") if (!defined $encfn);
usage("encounter file name does not exist") if (!-f $encfn);
my $pdffn = shift;
usage("need pdf output file name") if (!defined $pdffn);

my $enc = Quagmire::Encounter->load($encfn);
my $pdf = Quagmire::Encounter::PDF->new(
	filename=>$pdffn,
	encounter=>$enc,
);
print "Done\n";
