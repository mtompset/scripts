#!/usr/bin/perl -w

# This file is not part of Koha.
#
# Copyright (C) 2016 Tulong Aklatan
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# It is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this; if not, see <http://www.gnu.org/licenses>.

BEGIN {
    # find Koha's Perl modules
    # test carefully before changing this
    use FindBin;
    eval { require "$FindBin::Bin/kohalib.pl" };
}

use Modern::Perl;
use C4::Context;
use Data::Dumper;
use Carp;

my $dbh = C4::Context->dbh;

# Fix Issues.
my $sth = $dbh->prepare('SELECT MAX(issue_id) FROM koha_library.old_issues');
$sth->execute();
my $max_old_issue_id = $sth->fetchrow() // 0;
carp "OLD ISSUES: $max_old_issue_id";
$sth = $dbh->prepare(
q{SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name='issues' AND table_schema = 'koha_library';}
);
$sth->execute();
my $max_issue_id = $sth->fetchrow() // 0;
carp "ISSUES: $max_issue_id";

while ( $max_issue_id <= $max_old_issue_id ) {
    $dbh->do('INSERT INTO koha_library.issues (borrowernumber) VALUES (1);');
    $sth = $dbh->prepare(
q{SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name='issues' AND table_schema = 'koha_library';}
    );
    $sth->execute();
    $max_issue_id = $sth->fetchrow() // 0;
    carp "ISSUES: $max_issue_id";
}
$dbh->do('DELETE FROM koha_library.issues WHERE borrowernumber=1');

# Fix Reserves.
$sth = $dbh->prepare('SELECT MIN(branchcode) FROM branches');
$sth->execute();
my $branchcode = $sth->fetchrow();

$sth = $dbh->prepare('SELECT MAX(reserve_id) FROM koha_library.old_reserves');
$sth->execute();
my $max_old_reserve_id = $sth->fetchrow() // 0;
carp "OLD RESERVES: $max_old_reserve_id";
$sth = $dbh->prepare(
q{SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name='reserves' AND table_schema = 'koha_library';}
);
$sth->execute();
my $max_reserve_id = $sth->fetchrow() // 0;
carp "RESERVES: $max_reserve_id";

while ( $max_reserve_id <= $max_old_reserve_id ) {
    $sth = $dbh->prepare(
q{ INSERT INTO koha_library.reserves (borrowernumber,branchcode,biblionumber) VALUES (1,?,1); }
    );
    $sth->execute($branchcode);
    $sth = $dbh->prepare(
q{SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name='reserves' AND table_schema = 'koha_library';}
    );
    $sth->execute();
    $max_reserve_id = $sth->fetchrow() // 0;
    carp "RESERVES: $max_reserve_id";
}
$dbh->do('DELETE FROM koha_library.reserves WHERE borrowernumber=1');
