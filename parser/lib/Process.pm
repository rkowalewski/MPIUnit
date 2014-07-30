package Process;
use warnings;
use strict;

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname abs_path $0;

use Barrier;

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


  unless (defined $self->{barriers}[$writeIdx]) {
    $self->{barriers}[$writeIdx] = Barrier->new;
  }

  $self->{barriers}[$writeIdx]->value($param, $value);

  return 1;
}

sub fetchBarrierValue {
  my $self = shift;
  my $param = shift;
  my $readIdx = $self->{writeIdx} - 1;

  if ($readIdx == -1) {
    return 0;
  } else {
    return $self->{barriers}[$readIdx]->value($param) || 0;
  }
}

sub newBarrier {
  my $self = shift;
  $self->{writeIdx} = $self->{writeIdx} + 1;
  return 1;
}

1;
