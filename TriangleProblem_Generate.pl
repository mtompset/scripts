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

# This was written to when Matthew Tompsett told me about a triangle
# sequence where the two adjacent values in a row subtracted and
# absolute value generated the value below it with the criteria of
# using all the numbers from 1 to X, where X represents the number of
# slots in the triangle.

# Simplest solution:
#
#  (3) (2)
#
#    (1)
#
# This triangle has a base size of 2, the parameter passed to this
# script. There are 3 slots, and it uniquely uses all the numbers
# from 1 to 3. There are other solutions for a base 2 triangle.
# This script blows up when there is insufficient memory.
# This script runs quickly for 2, 3, 4, and 5. There is no solution
# for 6. This is proved by the parity checking script. Attempts to
# run for a base 7 triangle (1 through 28) ran out of memory on a
# 32GB machine.

use Modern::Perl;

use Data::Dumper;
use English qw ( -no_match_vars );
use Time::HiRes qw (time);
use Algorithm::Combinatorics qw(variations);
use List::MoreUtils qw(uniq);
use Carp;

use Readonly;
Readonly my $INDENTATION_SPACING => 3;

$OUTPUT_AUTOFLUSH = 1;

my $ignore;
$ignore = print "Input: Triangle with base size of $ARGV[0]\n";
if ( $ARGV[0] <= 0 ) {
    croak 'A triangle must have a base size of 1 or more.';
}

my $start = time;

my @list;
my $number = $ARGV[0];
my $slots  = 0;
for my $count ( 1 .. $number ) {
    $slots = $slots + $count;
}

for my $count ( 1 .. $slots ) {
    push @list, $count;
}

$ignore = print "Slots: There are $slots slots in this triangle.\n";

my @combinations = variations( \@list, $number );

my @permutations;
foreach my $combination (@combinations) {
    my @data         = @{$combination};
    my $current_slot = 0;
    my $row_width    = $number;
    my $row_max      = $number - 1;
    while ( $row_width > 1 ) {
        push @data, abs $data[$current_slot] - $data[ $current_slot + 1 ];
        $current_slot += 1;
        if ( $current_slot == $row_max ) {
            $current_slot += 1;
            $row_width -= 1;
            $row_max += $row_width;
        }
    }
    my $permutation = join q{,}, @data;
    push @permutations, $permutation;
}

$ignore =
  print 'There were ' . scalar @permutations . ' permutations to evaluate.';
$ignore = print "\n";
my $end      = time;
my $duration = $end - $start;
$ignore = print "Duration: $duration\n";

$ignore = print "SCANNING PERMUTATIONS FOR SOLUTIONS...\n\n";

my $solutions_exist = 0;
foreach my $permutation (@permutations) {
    my @permutation_array = split /,/xsm, $permutation;
    my @unique_permutation = uniq @permutation_array;
    if ( scalar @permutation_array == scalar @unique_permutation ) {
        display_solution( $permutation, $number );
        $solutions_exist = 1;
    }
}

if ( $solutions_exist == 0 ) {
    carp "There are no known solutions.\n";
}

sub display_solution {
    my ( $solution, $size ) = @_;

    my $line_length = $size;
    my $line        = 1;
    my @data        = split /,/xsm, $solution;

    for my $count (@data) {
        my $element = sprintf '%02d', $count;
        $ignore = print "($element)  ";
        $line_length -= 1;
        if ( $line_length == 0 ) {
            $ignore      = print "\n";
            $line_length = $size - $line;
            $ignore      = print q{ } x ( $line * $INDENTATION_SPACING );
            $line += 1;
        }
    }
    $ignore = print "\n\n";
    return;
}
