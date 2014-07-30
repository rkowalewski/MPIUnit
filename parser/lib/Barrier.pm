package Barrier;
use strict;
use warnings;
use Carp;

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);
  return $self;
}

sub value {
  my $self = shift;
  unless (ref $self) {
    croak "Should call value() with an object, not a class";
  }

  my ($param, $value) = @_;

  unless (defined $param) {
    croak "There is no param specified whose value should get fetched";
  }

  $self->{$param} = $value if defined $value;

  return $self->{$param};
}

1;
