#!/usr/bin/perl

package Family;
use strict;

use lib::Model;

# Constructor
sub new {
    my $class = shift;
    my $self = {
        _name => lc(shift),
        _models => [],
    };
    bless $self, $class;
    return $self;
}

# Get family's name
sub getName {
    my( $self ) = @_;
    return $self->{_name};
}

# Add a reference to a model of this family
sub addModel {
    my( $self, $model ) = @_;
    push $self->{_models}, $model;
    return $#{ $self->{_models} };
}

# Get a reference to the array of models that are part of this family
sub getModels {
    my( $self ) = @_;
    return $self->{_models};
}

1;
