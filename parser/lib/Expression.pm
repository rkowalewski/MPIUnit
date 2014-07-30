package Expression;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = {@_};
  bless($self, $class);
  return $self;
}

#sub isRemote {
# my $self = shift;
# return $self->{lhs}->isRemote || ($self->_isComparison && $self->{rhs}->isRemote);
#}

#sub _isComparison {
#  my $self = shift;
#  return defined $self->{rhs} && defined $self->{operator}
#}

sub evaluate {
  my $self = shift;

  unless (defined $self->{lhs}) {
    return -1;
  }

  if (defined $self->{operator} && defined $self->{rhs}) {
    my $expression = join(" $self->{operator} ", $self->{lhs}, $self->{rhs});
    return eval $expression || 0;
  } else {
    return $self->{lhs};
  }
}

1;
