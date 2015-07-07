#!/usr/bin/perl

use strict;
use warnings;

use JSON;

use lib::Manufacturer;
use lib::Model;
use lib::Util;
use lib::Tester;

# Constants to turn testing ON/OFF
use constant DEBUG_CACHE => (0);
use constant DEBUG_OUTPUT => (0);
use constant DEBUG_MATCHING => (0);
use constant DEBUG_STATS => (0);
# Constant names for JSON pairs
use constant JSON_MANUFACTURER => "manufacturer";
use constant JSON_MODEL => 'model';
use constant JSON_PRODUCT => 'product_name';
use constant JSON_FAMILY => "family";
use constant JSON_TITLE => "title";

# Global variables
my $products_file;
my $listings_file;
my $results_file;
my $testing_file;
my @manufacturers;  # An array of manufacturers

# Main code
openFiles();
cacheProducts();
Tester::printCachedProducts(\@manufacturers) if DEBUG_CACHE;
matchListings();
generateOutput();
Tester::printStats() if DEBUG_STATS;
closeFiles();
exit 0;

# Generate output
sub generateOutput {
    for my $i (0 .. $#manufacturers) {
        my $models_ref = $manufacturers[$i]->getModels();
        for my $k (0 .. $#{ $models_ref }) {
            my $listings_ref = ${ $models_ref }[$k]->getListings();
            if ( @{ $listings_ref } > 0 ) {
                my $product_name = ${ $models_ref }[$k]->getProductName();
                print $results_file "{\"product_name\":\"".$product_name."\",\"listings\":[";
                print $testing_file $product_name."\n" if DEBUG_OUTPUT;
                print $results_file ${ $listings_ref }[0];
                print $testing_file "\t".${ $listings_ref }[0]."\n" if DEBUG_OUTPUT;
                for my $l (0 .. $#{ $listings_ref }) {
                    print $results_file ",";
                    print $results_file ${ $listings_ref }[$l];                        
                    print $testing_file "\t".${ $listings_ref }[$l]."\n" if DEBUG_OUTPUT;
                }
                print $results_file "]}\n";
            }
        }
    }
}

# Match listings to the products
sub matchListings {
    while(<$listings_file>) {
        # Decode JSON pairs and extract relevant info
        my $decoded = decode_json($_);
        my $title = $decoded->{${\ JSON_TITLE }};
        my @tokens = split(/\s(for|pour)\s/,$title);
        $title = $tokens[0];
        my $man_name = $decoded->{${\ JSON_MANUFACTURER }};
        
        # Find matching manufacturer
        my $man_index = findMatchingManufacturerIndex($man_name, $title);

        if ( $man_index != -1 ) {
            my @match_models;    # List of indices of matching models
            my $models_ref = $manufacturers[$man_index]->getModels();
            findAllMatchingModels(\@match_models, $models_ref, $title);
            # Now look at the models that we have collected
            handleMatchedModels(\@match_models, $title, $_);
        }
        $Tester::total++;
    }
}

# Find all matching models in a listing title for a specific manufacturer
sub findAllMatchingModels {
    my( $match_models_ref, $models_ref, $title ) = @_;
    for my $i (0 .. $#{ $models_ref }) {       
        if ( Util::regexExists($title,${ $models_ref }[$i]->getTitleRegex()) ) {
            # We have a match
            push @{ $match_models_ref }, ${ $models_ref }[$i];
        }
    }
}

# Handle all collected models from a manufacturer
sub handleMatchedModels {
    my( $match_models_ref, $title, $listing ) = @_;
    if ( @{ $match_models_ref } == 0 ) {
        # No matches, nothing to do here
        $Tester::u_mods++ if DEBUG_STATS;
    } 
    elsif ( @{ $match_models_ref } == 1 ) {
        # Just add the listing
        $Tester::f_mods++ if DEBUG_STATS;
        ${ $match_models_ref }[0]->addListing($listing);
    }
    else {
        # We have more than one matching model
        # First, filter the models, is one model's name subset of another? (e.g., T3, T3i)
        # Find the model with the longest name
        my $model1 = ${ $match_models_ref }[0];
        my $longest_name_index = 0;
        my $longest_name_length = length($model1->getName());
        for my $i (1 .. $#{ $match_models_ref }) {
            my $model2 = ${ $match_models_ref }[$i];
            if (length($model2->getName()) > $longest_name_length) {
                $longest_name_index = $i;
                $longest_name_length = length($model2->getName());
            }
        }
        # Now filter models
        my @filtered_match_models;
        $model1 = ${ $match_models_ref }[$longest_name_index];
        for my $i (0 .. $#{ $match_models_ref }) {
            # The names to filter should match the longest name
            my $model2 = ${ $match_models_ref }[$i];
            my $name1_subset_2 = Util::regexExists($model2->getName(),$model1->getRegex());
            my $name2_subset_1 = Util::regexExists($model1->getName(),$model2->getRegex());
            if ( $name1_subset_2 ) {
                if ( $name2_subset_1 ) {
                    # Model's name matches another, add to filtered matches
                    push @filtered_match_models, $model2;
                }
                else {
                    # Model1's name is a subset of Model2's name
                    # Should not happen since Model1's name is the longest
                    $Tester::u_mods_error++ if DEBUG_STATS;
                    return;
                }
            }
            else {
                if ( $name2_subset_1 ) {
                    # Model2's name is a subset of Model1's name
                    # Do not add to filtered matches
                }
                else {
                    # Model2 has a different name than Model1 (neither is subset of the other)
                    # Can't decide which model the listing refers to
                    $Tester::u_mods_mult++ if DEBUG_STATS;
                    print $testing_file $title."\n" if DEBUG_MATCHING;
                    return;
                }
            }
        }
        # Now check the filtered models
        if ( @filtered_match_models == 1 ) {
            $filtered_match_models[0]->addListing($listing);
            $Tester::f_mods_mult_filter++ if DEBUG_STATS;
        }
        elsif ( @filtered_match_models > 1 ) {
            # Separate matches by family
            my $match_family_index = -1;
            for my $i (0 .. $#filtered_match_models) {
                if ( $filtered_match_models[$i]->getFamilyName ne "-1" ) {
                    if ( index(lc($title),$filtered_match_models[$i]->getFamilyName) != -1 ) {
                        if ( $match_family_index != -1 ) {
                            # More than one family match, can't decide which model matches
                            $Tester::u_mods_mult_fam++ if DEBUG_STATS;
                            print $testing_file $title."\n" if DEBUG_MATCHING;
                            return;
                        }
                        else {
                            $match_family_index = $i;
                        }
                    }
                }
                else {
                    # No family name
                    if ( $match_family_index != -1 ) {
                        # More than one family match, can't decide which model matches
                        $Tester::u_mods_mult_fam++ if DEBUG_STATS;
                        print $testing_file $title."\n" if DEBUG_MATCHING;
                        return;
                    }
                    else {
                        $match_family_index = $i;
                    }
                }
            }
            if ( $match_family_index != -1 ) {
                $Tester::f_mods_mult_filter_fam++ if DEBUG_STATS;
                $filtered_match_models[$match_family_index]->addListing($listing);
            }
            else {
                $Tester::u_mods_no_fam++ if DEBUG_STATS;
            }
        }
    }
}

# Return true if models name match
sub modelsNamesMatch {
    my( $model1, $model2) = @_;
    if ( Util::regexExists($model1->getName(),$model2->getRegex()) &&
        Util::regexExists($model2->getName(),$model1->getRegex())) {
        return 1;
    }
    return 0;
}

# Find a matching product manufacturer for a listing
sub findMatchingManufacturerIndex {
    my( $man_name, $title ) = @_;
    my $man_index = Util::getContainedNameIndex(\@manufacturers,$man_name);
    # If no match, search for the manufacturer in the title instead
    if ( $man_index == -1 ) {
        my $index = Util::getContainedNameIndex(\@manufacturers,$title);
        # If found in the title, we still need to check for at least a partial match for the manufacturer's name
        if ( $index != -1 && Util::namePartiallyExists(\@manufacturers,$index,$man_name) ) {
            $Tester::f_mans_title++ if DEBUG_STATS;
            $man_index = $index;
        }
        else {
            $Tester::u_mans++ if DEBUG_STATS;
        }
    }
    else {
        $Tester::f_mans++ if DEBUG_STATS;
    }
    return $man_index;
}

# Cache the products and create a nice hierarchy of objects
sub cacheProducts {
    while(<$products_file>) {
        # Decode JSON pairs and extract relevant info
        my $decoded = decode_json($_);
        my $product_name = $decoded->{${\ JSON_PRODUCT }};
        my $man_name = $decoded->{${\ JSON_MANUFACTURER }};
        my $family_name = $decoded->{${\ JSON_FAMILY }};
        my $model_name = $decoded->{${\ JSON_MODEL }};

        # Create a manufacturer object if one does not already exist
        my $man_index = Util::getNameIndex(\@manufacturers, $man_name);
        if ( $man_index == -1 ) {        
            $man_index = @manufacturers;
            push @manufacturers, new Manufacturer($man_name);
        }
        
        # Add model
        if ( !defined($family_name) ) {
            $family_name = "-1";
        }
        if ( !productAlreadyExists($manufacturers[$man_index]->getModels(), $family_name, $model_name) ) {
            $manufacturers[$man_index]->addModel(new Model($model_name, $family_name, $product_name));
        }
    }
}

# Return true if a similar product already exists
sub productAlreadyExists {
    my( $models_ref, $family_name, $model_name ) = @_;
    for my $i (0 .. $#{ $models_ref }) {
        if ( ${ $models_ref }[$i]->getFamilyName() eq lc($family_name) &&
            ${ $models_ref }[$i]->getName() eq lc($model_name) ) {
            return 1;
        }
    }
    return 0;
}

# Open files
sub openFiles {
    # Opening products input file
    open $products_file, "<", $ARGV[0]
        or die "open products input file failed";
    # Opening listings input file
    open $listings_file, "<", $ARGV[1]
        or die "open listings input file failed";
    # Opening results output file
    open $results_file, ">", "output/results.txt"
        or die "open testing output file failed";
    # Opening testing output file
    open $testing_file, ">", "output/testing.txt"
        or die "open testing output file failed" if DEBUG_OUTPUT || DEBUG_MATCHING;
}

# Close files
sub closeFiles {
    close $products_file
        or die "close prodults input file failed";
    close $listings_file
        or die "close listings input file failed";
    close $results_file
        or die "close results output file failed";
    close $testing_file
        or die "close testing output file failed" if DEBUG_OUTPUT || DEBUG_MATCHING;
}

