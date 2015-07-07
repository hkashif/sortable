#!/usr/bin/perl

package Manufacturer;
use strict;

#use lib::Family;
use lib::Model;

# Constructor
sub new {
    my $class = shift;
    my $self = {
        _name => lc(shift),
#        _families => [],
        _models => [],    # Models with no families
    };
    bless $self, $class;
    return $self;
}

# Get manufacturer's name
sub getName {
    my( $self ) = @_;
    return $self->{_name};
}

# Add a family to this manufacturer
#sub addFamily {
#    my( $self, $family ) = @_;
#    push $self->{_families}, $family;
#    return $#{ $self->{_families} };
#}

# Get a reference to the array of families for this manufacturer
#sub getFamilies {
#    my( $self ) = @_;
#    return $self->{_families};
#}

# Add a reference to a model from this manufacturer but has no family specified
sub addModel {
    my( $self, $model ) = @_;
    push $self->{_models}, $model;
    return $#{ $self->{_models} };
}

# Get a reference to the array of models, that have no families, from this manufacturer
sub getModels {
    my( $self ) = @_;
    return $self->{_models};
}

1;
