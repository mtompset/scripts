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

use Modern::Perl;
use Getopt::Long;
use Carp;
use Const::Fast;
use Data::Dumper;

const my $TagSize => 3;

my $InputFile  = 'sorted.mrk';
my $OutputFile = 'merged.mrk';
my $KeyString  = '100,245,264,300,490';
my @KeyFields;

GetOptions ("input|i=s"  => \$InputFile,
            "output|o=s" => \$OutputFile,
            "key|k=s"    => \$KeyString,
           );

@KeyFields = split(/,/xsm, $KeyString);
my $fh;
my @data;
if (open $fh, "<:encoding(UTF-8)", $InputFile) {
    @data = <$fh>;
    close $fh;
}
else {
    carp "Can not open $InputFile: $!";
}

my @records;
my $RecordData = q{};
foreach my $line (@data) {
    $line =~ s/^\s*//xsm;
    $line =~ s/\s*$//xsm;
    if ($line eq q{}) {
        if ($RecordData) { chop $RecordData; }
        if ($RecordData) { push @records, $RecordData; }
        $RecordData = q{};
    }
    else {
        $RecordData .= $line . "\n";
    }
}
if ($RecordData) {
    if ($RecordData) { chop $RecordData; }
    if ($RecordData) { push @records, $RecordData; }
}

my @merges;

my $merged = q{};
my $cur_key = q{};
foreach my $Record (@records) {
    my $key = determine_key($Record,\@KeyFields);
    if ($key ne $cur_key) {
        if ($merged) { push @merges, $merged; }
        $merged = $Record;
        $cur_key = $key;
    }
    else {
        $merged .= "\n" . extract_952($Record);
    }
}
if ($merged) { push @merges, $merged; }

if (open $fh, ">:encoding(UTF-8)", $OutputFile) {
    foreach my $RecordData (@merges) {
        print $fh $RecordData . "\n\n";
    }
    close $fh;
}
else {
    carp "Can't make $OutputFile: $!";
}

sub extract_952 {
    my ($tRecordData) = @_;

    my @fields = split(/\n/xsm,$tRecordData);
    my ( $f952,
       );
    foreach my $field (@fields) {
        my $tag = substr($field,0,$TagSize+1);
        if ($tag eq '=952') {
            $f952 = $field;
        }
    }
    $f952 //= q{};
    return $f952;
}

sub determine_key {
    my ($tRecordData,$keyfields) = @_;

    my @Fields2Check = @{$keyfields};
    my @fields       = split(/\n/xsm,$tRecordData);
    my %KeyPieces;
    my $key;
    foreach my $tag (@Fields2Check) {
        $KeyPieces{$tag} = q{};
    }
    foreach my $field (sort @fields) {
        my $tag = substr($field,1,$TagSize);
        my @Matches = grep { $_ eq $tag } @Fields2Check;
        if (@Matches>0) {
            $KeyPieces{$tag} = $field;
        }
    }
    $key = q{};
    foreach my $tag (sort keys %KeyPieces) {
        $key .= $KeyPieces{$tag};
    }
    return $key;
}
