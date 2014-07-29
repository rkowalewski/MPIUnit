package SimpleValue;
use warnings;
use strict;

sub new {
  my ($class, %args) = @_;
  my $self = {
    value => $args{value}
  };
  bless($self, $class);
  $self->_init;
  return $self;
}

sub _init {
  my $self = shift;
  $self->{isRemote} = 0;
}

sub isRemote {
  my $self = shift;
  return $self->{isRemote};
}

sub value {
  my $self = shift;
  return $self->{value};
}

1;
