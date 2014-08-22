package RemoteValue;

use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = {@_};
  bless($self, $class);
  return $self;
}

sub param {
  my $self = shift;
  return $self->{param};
}

sub source {
  my $self = shift;
  return $self->{source};
}

sub value {
  my $self = shift;
  return $self->{value};
}

sub isRemote {
  return 1;
}

1;
