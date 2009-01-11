package Quagmire::Encounter::Status;
use Moose;
use MooseX::Storage;
our $VERSION = '0.01';
our $AUTHORITY = 'cpan:MFONTANI';
with Storage('format' => 'YAML', 'io' => 'File');

has 'filename' => (is => 'rw', isa => 'Str', default=>'', required=>1);
has 'round'  => (is => 'rw', isa => 'Int', default=>0, required=>1);

__PACKAGE__->meta->make_immutable;
1;
