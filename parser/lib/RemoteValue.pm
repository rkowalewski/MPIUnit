package RemoteValue;
use strict;
use warnings;

#add lib directory to @INC
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname abs_path $0;

use parent qw(SimpleValue);

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);
  $self->{param} = $args{param};
  $self->{source} = $args{source};
  bless($self, $class);
  return $self;
}

sub _init {
  my $self = shift;

  $self->{isRemote} = 1;
}

sub param {
  my $self = shift;
  return $self->{param};
}

sub source {
  my $self = shift;
  return $self->{source};
}

1;
