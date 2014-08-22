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

  $self->{barriers}[$writeIdx] = {} unless ($self->{barriers}[$writeIdx]);

  $self->{barriers}[$writeIdx]->{$param} = $value;

  return 1;
}

sub fetchBarrierValue {
  my $self = shift;
  my $param = shift;

  croak 'must specify a parameter name in putBarrierValue() at least!...' unless $param;

  my $readIdx = $self->{writeIdx} - 1;
  return ($readIdx > -1) ? $self->{barriers}[$readIdx]->{$param} || 0 : undef;
}

sub nextBarrier {
  my $self = shift;
  $self->{writeIdx} = $self->{writeIdx} + 1;
  return 1;
}

1;
