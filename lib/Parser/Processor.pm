package Processor;

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname abs_path $0;

use Parse::RecDescent;
use Data::Dumper;

use constant {
        ASSERTION  => 'ASSERTION',
        PUTVAL  => 'PUTVAL',
        BARRIER => 'BARRIER',
};

use constant {
  RESOLVED => 'RESOLVED',
  DEFERRED => 'DEFERRED'
};

our (@REMOTE_VALUES);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my $grammar = <<'GRAMMAR';
  start: prefix (assertion | barrier | putval)
    {
      $return = $item[2];
      $return->{processId} = $item{prefix};
    }
  putval: /PUTVAL/i '(' string ',' simpleVal ')'
    {
      $return = {
        type => uc $item[0],
        parsedExpression => Model::BarrierItem->new($item{string}, $item{simpleVal}),
      };
    }
  barrier: /BARRIER/i
    {
      $return = {
        type => uc $item[0],
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
      my $items = $item[2];
      push @{$items}, $item[1];
      $return = Model::Assertion->new(operator => '||', items => $items);
    }
  conjunction: relationalComparison ('&&' relationalComparison {$item[2]}(s?)
    {
      my $items = $item[2];
      push @{$items}, $item[1];
      $return = Model::Assertion->new(operator => '&&', items => $items);
    }
  relationalComparison: expression ((relationalOpStr | relationalOpNum) expression {[@item]})(?)

      #$item[2] is an array of array, where the nested array has 3 entries with rule, operator and expression
      my $compareClause = $item[2];

      $return = Model::Assertion->new(
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
      $return = Model::RemoteValue->new(source=>$item{number}, param=>$item{string});
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
    processes => [ ]
  };
  $self->{parser} = new Parse::RecDescent( $grammar ) or die "Compile error\n";
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

  my $ret = {
    type => $expression->{type},
    processId => $expression->{processId}
  };

  if ($expression->{type} eq ASSERTION) {
    my $assertion = $expression->{parsedExpression};
    if ($assertion->isRemote) {
      my @affectedIds = @{$assertion->collectRemoteIds};

      foreach (@affectedIds) {

      }

    } else {
      $ret->{resultType} = RESOLVED;
      $ret->{resultValue} = $self->_evalSimpleAssertion($assertion);
    }
  }

  return $ret;

}

sub _evalSimpleAssertion {
  my ($self, $assertion) = @_;

  my $items = $assertion->items;

  my @nestedAssertionsIdx = grep { ref $items[$_] == 'Assertion'} 0..$#{$items};

  foreach(@nestedAssertionsIdx) {
    $items[$_] = $self->_evalSimpleAssertion($items[$_]);
  }

  my $expression = join (" $assertion->operator ", $items);
  return eval $expression || 0;
}

sub _getProcessId {
 my $self = shift;
}

1;
