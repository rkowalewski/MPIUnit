package Assertion;

use warnings;
use strict;
use Carp;

use constant SUPPORTED_TYPES => join('|', qw (Assertion RemoteValue));
use constant SUPPORTED_TYPES_REGEX => qr/^${\(SUPPORTED_TYPES)}$|^$/;

# The items of an Assertion could either be Assertions or RemoteValues
sub new {
  my $class = shift;
  my $self = {@_};
  bless $self, $class;
  $self->_init;
  return $self;
}

sub _init {
  my $self = shift;
  $self->{items} = [ ] unless (ref ($self->{items}) eq 'ARRAY');

  if (grep {(ref $_) !~ SUPPORTED_TYPES_REGEX} @{$self->{items}}){
    croak 'an Assertion may contain either simple scalars, RemoteValues, or other Assertions';
  }
}

sub isRemote {
  my $self = shift;

  return $self->{isRemote} if defined $self->{isRemote};

  foreach (@{$self->{items}}) {
    $self->{isRemote} = $_->isRemote if ref($_) ne '';
    last if $self->{isRemote};
  }

  $self->{isRemote} = 0 unless defined $self->{isRemote};

  return $self->{isRemote};
}

sub addItem {
  my $self = shift;
  my $item = shift;
  return unless defined $item;
  unless ((ref $item) =~ SUPPORTED_TYPES_REGEX) {
    croak 'an Assertion may contain either simple scalars, RemoteValues, or other Assertions';
  }
  push @{$self->{items}}, $item;
  undef $self->{isRemote};
  return $self->{items};
}

sub collectRemoteIds {
  my $self = shift;
  my @remoteIds = ();

  foreach (@{$self->{items}}) {
    my $type = ref $_;
    if ($type eq 'Assertion') {
      @remoteIds = (@remoteIds, @{$_->collectRemoteIds});
    } elsif ($type eq 'RemoteValue') {
      push @remoteIds, $_->source if defined $_->source;
    }
  }

  return \@remoteIds;
}

sub operator {
  my $self = shift;
  my $operator = shift;
  $self->{operator} = $operator if defined $operator;
  return $self->{operator};
}

sub items {
  my $self = shift;
  return $self->{items};
}

1;
