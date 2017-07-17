#!/usr/bin/perl

# Copyright (C) 2015  Mark Tompsett
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this; if not, see <http://www.gnu.org/licenses>.

use Const::Fast;
use Carp;
use English qw( -no_match_vars );
use Getopt::Long;
use Modern::Perl;

const my $TAGSIZE              => 3;
const my $IND1_LOCATION        => 6;
const my $IND2_LOCATION        => 7;
const my $SUBFIELDS_START      => 8;
const my $NONCONTROL_TAG_START => 10;

my $input_file  = 'input.mrk';
my $output_file = 'sorted.mrk';
my $key_string  = q{100$a,245$a,264$a/260$a,300$a,490$a,700$a};
my @key_fields;

GetOptions(
    'input|i=s'  => \$input_file,
    'output|o=s' => \$output_file,
    'key|k=s'    => \$key_string,
);

@key_fields = split /,/xsm, $key_string;

my $fh;
my @data;
if ( !open $fh, '<:encoding(UTF-8)', $input_file ) {
    carp "Can not open $input_file: $ERRNO";
}

@data = <$fh>;
close $fh;

my @records;
my $record_data = q{};
foreach my $line (@data) {
    $line =~ s/^\s*//xsm;
    $line =~ s/\s*$//xsm;
    if ( $line eq q{} ) {
        if ($record_data) { chop $record_data; }    # this is a windows file.
        if ($record_data) { chop $record_data; }
        if ($record_data) { push @records, $record_data; }
        $record_data = q{};
    }
    else {
        $record_data .= $line . "\r\n";
    }
}
if ($record_data) {
    if ($record_data) { chop $record_data; }           # this is a windows file.
    if ($record_data) { chop $record_data; }
    if ($record_data) { push @records, $record_data; }
}

my @sorted =
  sort { build_hash( $a, \@key_fields ) cmp build_hash( $b, \@key_fields ) }
  @records;

if ( !open $fh, '>:encoding(UTF-8)', $output_file ) {
    carp "Can't make $output_file: $ERRNO";
}

foreach my $sorted_record (@sorted) {
    my $line = $sorted_record . "\r\n\r\n";
    print {$fh} $line;
}
close $fh;

sub build_hash {
    my ( $current_record, $keyfields ) = @_;

    my @fields = split /\r\n/, $current_record;
    my $hashed_data;
    foreach my $field (@fields) {
        my $tag = substr $field, 1, $TAGSIZE;
        my $ind1 = substr $field, $IND1_LOCATION, 1;
        my $ind2 = substr $field, $IND2_LOCATION, 1;
        my $subfields = substr $field, $SUBFIELDS_START;
        $hashed_data->{$tag}->{'ind1'} = $ind1;
        $hashed_data->{$tag}->{'ind2'} = $ind2;
        if ( $tag eq 'LDR' || int($tag) < $NONCONTROL_TAG_START ) {
            $hashed_data->{$tag}->{q{@}} = $subfields;
        }
        else {
            $subfields = substr $subfields, 1;    # ignore first $
            my @subfield_data = split /\$/, $subfields;
            my @subfield_hashes = map {
                { 'subtag' => substr( $_, 0, 1 ), 'value' => substr $_, 1 }
            } @subfield_data;
            foreach my $subfield_hash (@subfield_hashes) {
                my $subtag = $subfield_hash->{'subtag'};
                my $value  = $subfield_hash->{'value'};
                $hashed_data->{$tag}->{$subtag} = $value;
            }
        }
    }
    my @key_values;
    foreach my $key_piece ( @{$keyfields} ) {

        # No multiple conditions to build.
        if ( $key_piece !~ /\// ) {
            my ( $keytag, $keysubtag ) = split /\$/, $key_piece;
            my $key_value = $hashed_data->{$keytag}->{$keysubtag} // q{};
            push @key_values, $key_value;
        }
        else {
            my $part_found = 0;
            my @conditions = split /\//, $key_piece;
            foreach my $condition (@conditions) {
                my ( $keytag, $keysubtag ) = split /\$/, $key_piece;
                my $key_value = $hashed_data->{$keytag}->{$keysubtag};
                if ( defined $key_value ) {
                    push @key_values, $key_value;
                    $part_found = 1;
                    break;
                }
            }
            if ( $part_found == 0 ) {
                push @key_values, q{};
            }
        }
    }
    my $key = join q{}, @key_values;
    return $key;
}
