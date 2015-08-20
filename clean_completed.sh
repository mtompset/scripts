#!/bin/bash

# Copyright (C) 2015  Mark Tompsett
# Copyright (C) 2015  Barton Chittenden (status optimization loop)
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

if [[ ! -d ~/bugs2check ]]; then
    echo "Creating report directory..."
    mkdir ~/bugs2check
fi

git checkout master
BRANCH=`git status | grep "On branch" | cut -f3- -d' '`
if [[ $BRANCH != "master" ]]; then
    echo "Handle your commits first."
    exit
fi

echo > ~/bugs2check/REPORT
BUGS=`git branch | grep "bug_[0-9][0-9]*$" | cut -f2 -d'_' | sort -u`
for i in `echo $BUGS`; do
    wget -O- http://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=$i > ~/bugs2check/$i 2> /dev/null
    STATUS=`grep static_bug ~/bugs2check/$i | cut -f2 -d'>'`
    echo $i - $STATUS | tee -a ~/bugs2check/REPORT
done
for STATUS in 'Pushed to Master' 'Pushed to Stable' 'CLOSED' 'RESOLVED'; do
    BUGS2DEL=`grep "$STATUS" ~/bugs2check/REPORT | cut -f1 -d' '`
    for i in `echo $BUGS2DEL`; do
        BRANCHES=`git branch | grep bug_$i`
        read -p "Delete $BRANCHES? " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for j in `echo $BRANCHES`; do
                git branch -D $j
            done
        fi
    done
done
