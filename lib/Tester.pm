#!/usr/bin/perl

package Tester;
use strict;

# Stat variables
our $total = 0;  #total entries
our $u_mans = 0; #unfound everywhere
our $f_mans = 0; #found only in cache
our $f_mans_title = 0;   #found only in title
our $u_mods = 0;    #no matching model found
our $f_mods = 0;    #successful match found
our $u_mods_error = 0;  #failed match due to a parsing error
our $u_mods_mult = 0;   #failed match due to multiple matched models (of different names)
our $u_mods_mult_fam = 0;   #failed match due to multiple models and multiple families matching
our $u_mods_no_fam = 0; #failed match dueo to failure separating by family (none found)
our $f_mods_mult_filter = 0;    #successful match after finding longest match
our $f_mods_mult_filter_fam = 0;    #successful match after filtering multiple matches by familyi

# Nicely print cached products organized into manufacturers/models
sub printCachedProducts {
    my ( $manufacturers_array_ref ) = @_;
    for my $man (@{ $manufacturers_array_ref }) {
        print "Man: ".$man->getName()."\n";
        my $models_ref = $man->getModels();
        print "\t";
        for my $i (0 .. $#{ $models_ref }) {
            print ${ $models_ref }[$i]->getName().", ";
        }
        print "\n";
    }
}

# Print statistics
sub printStats {
    print "# total entries: ".$total."\n";
    print "# total manufacturers: ".($u_mans+$f_mans+$f_mans_title)."\n";
    print "\t# no matching manufacturers: ".$u_mans."\n";
    print "\t# matching manufacturers: ".($f_mans+$f_mans_title)."\n";
    print "\t\t# match by manufacturer's name: ".$f_mans."\n";
    print "\t\t# match by title: ".$f_mans_title."\n";
    print "# total models: ".($u_mods+$u_mods_error+$u_mods_mult+$u_mods_mult_fam+$u_mods_no_fam+$f_mods+$f_mods_mult_filter+$f_mods_mult_filter_fam)."\n";
    print "\t# no matching models: ".$u_mods."\n";
    print "\t# failed matches: ".($u_mods_error+$u_mods_mult+$u_mods_mult_fam+$u_mods_no_fam)."\n";
    print "\t\t# fail due to parsing error: ".$u_mods_error."\n";
    print "\t\t# fail due to multiple matches with different names: ".$u_mods_mult."\n";
    print "\t\t# fail due to multiple matches for models and families: ".$u_mods_mult_fam."\n";
    print "\t\t# fail due to multiple matches but no families match: ".$u_mods_no_fam."\n";
    print "\t# matched models: ".($f_mods+$f_mods_mult_filter+$f_mods_mult_filter_fam)."\n";
    print "\t\t# one model match: ".($f_mods)."\n";
    print "\t\t# multiple models match, find longest match: ".($f_mods_mult_filter)."\n";
    print "\t\t# multiple models match, separate by family: ".($f_mods_mult_filter_fam)."\n";
}

1;
