#!/usr/bin/perl -Tw

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

# This was written to help Christopher Kesthely on 2015-11-11
# The script takes GenBank files with one sequence and renames
# them based on the DEFINITION lines.

use strict;
use warnings;
use Carp qw( carp croak );
use English qw( -no_match_vars );
use File::Slurp;
use File::Copy;

$OUTPUT_AUTOFLUSH = 1;

if ( scalar @ARGV > 0 ) {
    carp "Usage: $PROGRAM_NAME";
    exit;
}

# make prints perlcritic nicer
my $ignore;

# Read the directory listing
opendir my $dh, q{.} or croak "can't opendir current directory: $ERRNO";
my @listing = readdir $dh;
closedir $dh;

# For each entry...
foreach my $entry (@listing) {

    # Check if it is a regular file...
    if ( -f $entry ) {

        # Read the whole file into a string.
        my $data = read_file($entry);

        # check if it is a sequence file.
        if ( $data =~ /^LOCUS/xsm ) {

            my $chkdata = $data;
            $chkdata =~ s/LOCUS//gxsm;
            if ( ( length $chkdata ) + ( length q{LOCUS} ) != length $data ) {
                $ignore = print "$entry: MULTI-SEQUENCE FILE IGNORED\n";
            }
            else {
                $ignore = print "$entry: ";
                if ( has_definition($data) == 0 ) {
                    croak "MISSING DEFINITION TAG\n";
                }
                if ( get_tag_after_definition($data) !~ /^ACCESSION/xsm ) {
                    croak "Unexpected tag following DEFINITION\n";
                }

                # untaint the source name.
                my $source = q{};
                if ( $entry =~ /(.*)/xsm ) {
                    $source = $1;
                }

                if ( $data =~ /DEFINITION(.*)ACCESSION/xsm ) {
                    my $definition = $1;
                    $definition =~ s/\s\s*/ /gxsm;
                    $definition =~ s/^\s*//gxsm;
                    my $destination = $definition;
                    move( $source, $destination );
                    $ignore = print "moved.\n";
                }
                else {
                    croak "Can't find definition block\n";
                }
            }
        }
    }
}

sub has_definition {
    my ($data) = @_;
    my $retval = 0;

    $data =~ s/\r/\n/gxsm;
    $data =~ s/\n\n/\n/gxsm;
    my @lines = split /\n/xsm, $data;
    my @tags  = grep { /^\S/xsm } @lines;
    my @check = grep { /^DEFINITION/xsm } @tags;
    if ( scalar @check > 0 ) {
        $retval = 1;
    }
    return $retval;
}

sub get_tag_after_definition {
    my ($data) = @_;

    $data =~ s/\r/\n/gxsm;
    $data =~ s/\n\n/\n/gxsm;
    my @lines = split /\n/xsm, $data;
    my @tags = grep { /^\S/xsm } @lines;

    while ( ( scalar @tags ) > 0 && $tags[0] !~ /^DEFINITION/xsm ) {
        my $dropped = shift @tags;
    }
    my $dropped = shift @tags;
    my $end_tag = shift @tags;
    return $end_tag;
}
