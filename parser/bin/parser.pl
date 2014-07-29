#!/usr/bin/perl

use strict;
use warnings;
use Parse::RecDescent;
use Scalar::Util qw( reftype );

#add the lib directory to @INC
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

use SimpleValue;
use RemoteValue;
use Expression;

our (@REMOTE_VALS);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my $grammar = <<'GRAMMAR';
  {
    my $processId = -1;
  }

  start: prefix assertion
  assertion: expect_true
  expect_true: /EXPECT_TRUE/i '(' disjunction ')'
    {
      $return = $item[3];
    }
  disjunction: conjunction ('||' conjunction {$item[2]})(s?)
    {
      my @concat = unshift @{$item[2]}, $item[1];
      $return = {
        processId => $processId,
        disjunctions => \@concat
      };
    }
  conjunction: compareExpression ('&&' compareExpression {$item[2]})(s?)
    {
      my @concat = unshift @{$item[2]}, $item[1];
      $return = \@concat;
    }
  compareExpression: expression ((relationalOpStr | relationalOpNum) expression {[@item]})(?)
    {
      #$item[2] is an array of array, where the nested array has 3 entries with rule, operator and expression
      my $compareClause = $item[2];

      # check if there is a compareExpression
      if (scalar @{$compareClause}) {
        $return = Expression->new(
          lhs => $item[1],
          operator => $compareClause->[0]->[1],
          rhs => $compareClause->[0]->[2]
        );
      } else {
        $return = Expression->new(lhs => $item[1]);
      }
    }
  expression: simpleVal | remoteVal
  simpleVal: string | number
  {
    $return = SimpleValue->new(value => $item[1]);
  }
  remoteVal: /GETVAL/i '(' string ',' number ')'
    {
      $return = RemoteValue->new(
        source => $item{number},
        param => $item{string},
        value => 1
      );
    }
  string: /['"]\w+['"]/
  number: /[-+]?\d+/
  relationalOpNum: /[<>]\=?|\={2}|!\=/
  relationalOpStr: /[gl][te]|eq|ne/
  prefix: /^test/i /\d+/ /:\s*/
    {
      $processId = $item[2];
    }
GRAMMAR

sub compareExpression {
  my $expression = shift;

  if (scalar @{$expression->{clauses}} > 1){
    if (containsRemoteExpression($expression->{expressions})) {
    
    }
    
  } else {
    #if ($exp->{expressions}->_isRemote || $exp->{actual}->_isRemote) {
      #Handle this case
      # } else {
      #my $expressionStr = join(" ", $exp->{expected}->{_value}, $exp->{operator}, $exp->{actual}->{_value});
      #my $return = eval $expressionStr || 0;
      #return $return;
      #}
  }
  return 1;
}

sub booleanExpression {
  my $boolExp = shift;
  my @otherExpressions = @{$boolExp->{other}};

  my $expressionStr = "$boolExp->{start}";

  if (scalar @otherExpressions) {
    $expressionStr = $expressionStr . " $boolExp->{operator} " . join(" $boolExp->{operator} ", @otherExpressions);
  }

  return eval $expressionStr || 0;
}

my $p = new Parse::RecDescent( $grammar ) or die "Compile error\n";
while ( <> )
{
  chomp;
  my $result = $p->start( $_ );

  print "The result is: $result" . "\n";
  print "The processId is: " . $result->{processId} . "\n";
  print "Disjunctions Count: " . scalar @{$result->{disjunctions}} . "\n";

  #if (defined($result) && $result ne '' && $result ne '0') {
  # print join(' --> ', $_, "PASS\n");
  #} else {
  # print join(' --> ', $_, "FAILURE\n");
  #}
}
