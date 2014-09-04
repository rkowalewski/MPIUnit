package Process;
use warnings;
use strict;

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname dirname dirname abs_path $0;

use Carp;

sub new {
  my $class = shift;
  my $self = {
    barriers => [ ],
    writeIdx => 0
  };
  bless($self, $class);
  return $self;
}

sub putBarrierValue {
  my $self = shift;
  my ($param, $value) = @_;
  my $writeIdx = $self->{writeIdx};

  croak 'must specify a parameter name in putBarrierValue() at least!...' unless $param;

  $self->{barriers}->[$writeIdx] = { } unless ($self->{barriers}[$writeIdx]);

  $self->{barriers}->[$writeIdx]->{$param} = $value;

  return {
    barrierIdx => $writeIdx,
    param => $param,
    value => $value
  };
}

sub isBarrierFlushed {
  my $self = shift;
  my $barrierIdx = shift;

  return $self->{writeIdx} > $barrierIdx;
}

sub fetchBarrierValue {
  my ($self, $param, $barrierIdx) = @_;

  croak "must specify both a 'parameter name' and a 'barrier index' in fetchBarrierValue()!" unless ($param || $barrierIdx);

  return undef unless ($self->isBarrierFlushed($barrierIdx));

  return $self->{barriers}->[$barrierIdx]->{$param};
}

sub getBarrierReadIdx{
  my $self = shift;
  my $readIdx = $self->{writeIdx} - 1;
  return ($readIdx > -1) ? $readIdx : 0;
}

sub nextBarrier {
  my $self = shift;
  $self->{writeIdx} = $self->{writeIdx} + 1;
  return $self->{writeIdx};
}

1;
