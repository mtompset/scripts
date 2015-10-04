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

# This was written to help Christopher Kesthely on 2015-10-03
# The script takes a huge GenBank file containing multiple sequences
# and splits them to multiple GenBank files with only one sequence
# in each.
# Thanks goes out to D Ruth Bavousett for showing me $PROGRAM_NAME
# in the English package. It's perlcritic cleaner as a result.

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );

if ($#ARGV!=0) {
    carp 'Usage: ' . $PROGRAM_NAME . ' {GenBank File With Multiple Sequences}';
    exit;
}

my $filename = $ARGV[0];
open my $fh, '<', $filename or croak 'read kaboom!';
my $output_filename = q{};
my $sequence = q{};
my $line = q{};
while ($line = <$fh>) {
    if ($line =~ /^LOCUS/xsm) {
        if ($sequence) {
            if (-e $output_filename) {
                print STDERR "ERROR: $output_filename exists\n";
            }
            else {
                open my $fh2, '>', $output_filename or croak 'write kaboom!';
                print $fh2 $sequence;
                my $rv = close $fh2;
            }
        }
        $sequence = $line;
        if ($line =~ /^LOCUS\s*(\S*)\s*/xsm) {
            $output_filename = $1;
            print "PROCESSING $output_filename\n";
        }
    }
    else {
        $sequence .= $line;
    }
}

if ($sequence) {
    if (-e $output_filename) {
        print STDERR "ERROR: $output_filename exists\n";
    }
    else {
        open my $fh2, '>', $output_filename or croak 'write kaboom!';
        print $fh2 $sequence;
        my $rv = close $fh2;
    }
}

my $rv = close $fh;
