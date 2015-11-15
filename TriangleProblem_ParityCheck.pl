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

# When running the TriangleProblem_Generate script for 6, it seemed
# crazy long for no solutions. I found a nice discussion at
# http://mathforum.org/library/drmath/view/62496.html
# which pointed out that parity could be used to determine if there
# was even the possibility of solution.

use Modern::Perl;
use Data::Dumper;
use English qw ( -no_match_vars );
use Time::HiRes qw (time);
use Algorithm::Combinatorics qw(variations);
use List::MoreUtils qw(uniq);
use Carp;

$OUTPUT_AUTOFLUSH = 1;

my $ignore;
if ( $ARGV[0] <= 0 ) {
    croak 'A triangle must have a base size of 1 or more.';
}

my $parity_start = time;
$ignore = print "Input: triangle base size of $ARGV[0].\n";

my @list;
my $number = $ARGV[0];
my $slots  = 0;
for my $count ( 1 .. $number ) {
    $slots = $slots + $count;
}

$ignore = print "Slots: a total of $slots slots exist.\n";

for my $count ( 1 .. $slots ) {
    push @list, $count;
}

my @parities;
for my $count ( 0 .. ( ( 2**$number ) - 1 ) ) {
    my $packed_number = pack 'N', $count;
    my $unpacked_binary = unpack 'B32', $packed_number;
    my $encoded_number = substr $unpacked_binary, -$number;
    push @parities, [ split //xsm, $encoded_number ];
}

my @parity_triangles;
foreach my $combination (@parities) {
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

    #    print Dumper($combination);
    #    print Dumper(\@data);
    my $parity_triangle = join q{,}, @data;
    push @parity_triangles, $parity_triangle;
}

$ignore = print 'There are ' . scalar @parity_triangles;
$ignore = print " parities in the base row.\n";
my $parity_end = time;
$ignore = print 'Duration: ' . ( $parity_end - $parity_start ) . "\n";

$ignore = print "PARITY TRIANGLES CALCULATED...\n";

my @parity_matches;
my $possible = 0;
foreach my $permutation (@parity_triangles) {
    my $check_odd = $permutation;
    $check_odd =~ s/1//gxsm;
    my $expected = $slots >> 1;
    $expected += ( $slots % 2 );
    if ( ( ( length $permutation ) - ( length $check_odd ) ) == $expected ) {
        push @parity_matches, $permutation;
        $possible = 1;
    }
}

if ( $possible == 1 ) {
    $ignore = print "POSSIBLE!\n";
}
else {
    croak 'IMPOSSIBLE!';
}

my @valid_parities;
foreach my $parity (@parity_matches) {
    my @parity_array = split /,/xsm, $parity;
    while ( ( scalar @parity_array ) > $number ) {
        my $ignored = pop @parity_array;
    }
    my $parity_base = join q{,}, @parity_array;
    push @valid_parities, $parity_base;
}

$ignore = print Dumper( \@valid_parities );
