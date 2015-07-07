#!/usr/bin/perl

package Model;
use strict;

# Constructor
sub new {
    my $class = shift;
    my $name = lc(shift);
    
    # Make a regex out of the model's name to accept either a '-' or a ' ' within the name
    my @tokens = split(/[-\s]+/, $name);
    my $regex = '';
    for my $i (0 .. $#tokens) {
        $regex .= $tokens[$i];
        if ($i < $#tokens) {
            $regex .= '[-\s]';
        }
    }

    my $self = {
        _name => $name,
        _regex => $regex,
        _family_name => lc(shift),
        _product_name => shift,
        _listings => [],
    };
    bless $self, $class;
    return $self;
}

# Get the model's name
sub getName {
    my( $self ) = @_;
    return $self->{_name};
}

# Get the product's name
sub getProductName {
    my( $self ) = @_;
    return $self->{_product_name};
}

# Get the family name
sub getFamilyName {
    my( $self ) = @_;
    return $self->{_family_name};
}

# Get the regex for the model's name
sub getRegex {
    my( $self ) = @_;
    return $self->{_regex};
}

# Get the title matching regex
sub getTitleRegex {
    my( $self ) = @_;
    return '(^|\s)'.$self->{_regex}.'(?![0-9])';
}

# Add a listing matching this model
sub addListing {
    my( $self, $listing ) = @_;
    chomp($listing);
    push $self->{_listings}, $listing;
    return $#{ $self->{_listings} };
}

# Get a reference to the array of listings matching this product
sub getListings {
    my( $self ) = @_;
    return $self->{_listings};
}

1;
