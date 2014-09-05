package Processor;

use Parse::RecDescent;
use Data::Dumper;

#add Parser dir to @INC
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname abs_path __FILE__;

#import all models
use Model::Assertion;
use Model::RemoteValue;
use Model::Process;

use constant {
        ASSERTION  => 'ASSERTION',
        PUTVAL  => 'PUTVAL',
        BARRIER => 'BARRIER',
};

use constant {
  PROCESSED => 'PROCESSED',
  DEFERRED => 'DEFERRED'
};

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my $Grammar = <<'GRAMMAR';
  start: prefix (assertion | barrier | putval)
    {
      $return = $item[2];
      $return->{processId} = $item{prefix};
    }
  putval: /PUTVAL/i '(' string ',' simpleVal ')'
    {
      $return = {
        type => uc $item[0],
        valueTuple => {
          param => $item{string},
          value => $item{simpleVal}
        }
      };
    }
  barrier: /BARRIER/i
    {
      $return = {
        type => uc $item[0]
      };
    }
  assertion: expect_true
    {
      $return = {
        type => uc $item[0],
        parsedExpression => $item[1]
      };
    }
  expect_true: /EXPECT_TRUE/i '(' disjunction ')'
    {
      $return = $item{disjunction};
    }
  disjunction: conjunction ('||' conjunction {$item[2]})(s?)
    {
      my @items = @{$item[2]};
      unshift @items, $item[1];
      $return = Assertion->new(operator => '||', items => \@items);
    }
  conjunction: relationalComparison ('&&' relationalComparison {$item[2]})(s?)
    {
      my @items = @{$item[2]};
      unshift @items, $item[1];
      $return = Assertion->new(operator => '&&', items => \@items);
    }
  relationalComparison: expression ((relationalOpStr | relationalOpNum) expression {[@item]})(?)
    {
      #$item[2] is an array of array, where the nested array has 3 entries with rule, operator and expression
      my $compareClause = $item[2];

      $return = Assertion->new(
        items => [ $item[1] ]
      );

      # check if there is a relationalComparison
      if (scalar @{$compareClause}) {
        $return->addItem($compareClause->[0][2]);
        $return->operator($compareClause->[0][1]);
      }
    }
  expression: simpleVal | remoteVal
  simpleVal: string | number
  remoteVal: /GETVAL/i '(' string ',' number ')'
    {
      $return = RemoteValue->new(source=>$item{number}, param=>$item{string});
   }
  string: /['"]\w+['"]/
  number: /[-+]?\d+/
  relationalOpNum: /[<>]\=?|\={2}|!\=/
  relationalOpStr: /[gl][te]|eq|ne/
  prefix: /^test/i /\d+/ /:\s*/
    {
      $return= $item[2];
    }
GRAMMAR


sub new {
  my $class = shift;
  my $self = {
    processes => [ ],
    deferredAssertions => [ ]
  };
  $self->{parser} = new Parse::RecDescent( $Grammar) or die "Compile error\n";
  bless $self, $class;
  return $self;
}

sub eval {
  my $self = shift;
  my $line = shift;

  chomp $line;
  my $parsedExpression = $self->{parser}->start( $line );
  return $self->_evalInternal($parsedExpression);
}

sub _evalInternal {
  my $self = shift;
  my $expression = shift;

  return unless defined $expression;

  my $currentProcess = $self->_getProcessById($expression->{processId});

  my $ret = {
    type => $expression->{type},
    processId => $expression->{processId},
  };

  my $type = $expression->{type};

  if ($type eq ASSERTION) {
    my $assertion = $expression->{parsedExpression};
    if ($assertion->isRemote) {
      my $barrierReadIdx = $currentProcess->getBarrierReadIdx;
      my @requiredBarrierFlushes = grep {
        !($self->_getProcessById($_)->isBarrierFlushed($barrierReadIdx))
      } @{$assertion->collectRemoteIds};

      if (@requiredBarrierFlushes) {
        my $deferredAssertion = {
          barrierIdx => $barrierReadIdx,
          assertion => $assertion,
          waitingForProcesses => [ @requiredBarrierFlushes ]
        };

        push (@{$self->{deferredAssertions}}, $deferredAssertion);
        $ret->{resultType} = DEFERRED;
        $ret->{resultValue} = $deferredAssertion;
      } else {
        $ret->{resultValue} = $self->_evalAssertion($assertion, $barrierReadIdx);
      }
    } else {
      $ret->{resultValue} = $self->_evalAssertion($assertion);
    }
  } elsif ($type eq PUTVAL) {
    my $valueTuple = $expression->{valueTuple};
    $ret->{resultValue} = $currentProcess->putBarrierValue($valueTuple->{param}, $valueTuple->{value});
  } elsif ($type eq BARRIER) {
    $ret->{resultValue} = $currentProcess->nextBarrier;
    # evaluate assertions wating for this barrier to be flushed
    my @resolvedDeferred = $self->_evalDeferredAssertions($currentProcess->getBarrierReadIdx, $expression->{processId});
    $ret->{resolvedDeferredCount} = scalar @resolvedDeferred;
  }

  $ret->{resultType} = PROCESSED unless ($ret->{resultType});

  return $ret;
}

sub _evalAssertion {
  my ($self, $assertion, $remoteBarrierIdx) = @_;

  my $items = $assertion->items;

  # filter all nested assertions and evaluate recursive
  my @nestedAssertionsIdx = _filterIdxByReftype($items, 'Assertion');

  foreach(@nestedAssertionsIdx) {
    $items->[$_] = $self->_evalAssertion($items->[$_], $remoteBarrierIdx);
  }

  # resolve remote values
  my @remoteValuesIdx = _filterIdxByReftype($items, 'RemoteValue');
  foreach(@remoteValuesIdx) {
    my $remoteValue = $items->[$_];
    my $remoteProcess = $self->_getProcessById($remoteValue->source);
    $items->[$_] = $remoteProcess->fetchBarrierValue($remoteValue->param, $remoteBarrierIdx);
  }

  # build expression string and return result
  my $expression = join (" ${\($assertion->operator)} ", @{$items});
  return eval $expression || 0;
}

sub _evalDeferredAssertions {
  my ($self, $barrierIdx, $processId) = @_;
  my $deferredAssertions = $self->{deferredAssertions};

  my @candidatesIdx = grep { $deferredAssertions->[$_]->{barrierIdx} == $barrierIdx} 0..$#{$deferredAssertions };
  my @resolved = ();

  foreach(@candidatesIdx) {
    my $deferredAssertion = $deferredAssertions->[$_];
    my $waitingFor = $deferredAssertion->{waitingForProcesses};

    my @removeIdx = grep ($waitingFor->[$_] == $processId, 0..$#{$waitingFor});
    while (my ($idx, $waitingForProcessId) = each (@removeIdx)) {
      splice(@$waitingFor, $waitingForProcessId - $idx, 1);
    }

    unless (@$waitingFor) {
      $self->_evalAssertion($deferredAssertion->{assertion}, $barrierIdx);
      push @resolved, $_;
    }
  }

  return @resolved;
}

sub _filterIdxByReftype {
  my $items = shift;
  my $type = shift;
  my $regex = qr/^${\($type)}$/;

  return grep { ref ($items->[$_]) =~ m{$regex} } 0..$#{$items} || ();
}

sub _getProcessById {
  my $self = shift;
  my $processId = shift;
  $self->{processes}->[$processId] = Process->new unless $self->{processes}->[$processId];
  return $self->{processes}->[$processId];
}

1;
