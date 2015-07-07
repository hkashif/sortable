#!/usr/bin/perl

package Util;
use strict;

# Get index, from the referenced array, for the object whose name matches the name in the second argument
sub getNameIndex {
    my( $array_ref, $name ) = @_;
    for my $i (0 .. $#{ $array_ref }) {
        if (${ $array_ref }[$i]->getName() eq lc($name)) {
            return $i;
        }
    }
    return -1;
}

# Similar to getNameIndex, but returns a match if the name is part of bigger string
sub getContainedNameIndex {
    my( $array_ref, $string ) = @_;
    for my $i (0 .. $#{ $array_ref }) {
        if (index( lc($string), ${ $array_ref }[$i]->getName()) != -1) {
            return $i;
        }
    }
    return -1;
}

# Returns true if the argument name is part of the array's element name
sub namePartiallyExists {
    my( $array_ref, $index, $name ) = @_;
    if ( index(${ $array_ref }[$index]->getName(),lc($name)) != -1 ) {
        return 1;
    }
    return 0;
}

# Returns true if string contains regex
sub regexExists {
    my( $string, $regex ) = @_;
    if (lc($string) =~ /$regex/) {
        return 1;
    }
    return 0;
} 

1;
