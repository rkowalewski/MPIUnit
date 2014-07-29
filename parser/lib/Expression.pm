package Expression;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = {@_};
  bless($self, $class);
  return $self;
}

sub isRemote {
  my $self = shift;
  return $self->{lhs}->isRemote || ($self->_isComparison && $self->{rhs}->isRemote);
}

sub _isComparison {
  my $self = shift;
  return defined $self->{rhs} && defined $self->{operator}
}

1;
