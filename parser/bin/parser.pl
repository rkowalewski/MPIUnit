#!/usr/bin/perl

use strict;
use warnings;
use Parse::RecDescent;
use Scalar::Util qw( reftype );

#add the lib directory to @INC
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';
use Expression;
use Process;

our (@REMOTE_VALS);

use constant {
        ASSERTION  => 'ASSERTION',
        PUTVAL  => 'PUT',
        BARRIER => 'BARRIER',
};

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my $grammar = <<'GRAMMAR';
  start: prefix (assertion | barrier | putval)[$item[1]]
    {
      $return = {
        processId => $item[1],
        actionResult => $item[2]
      };
    }
  putval: /PUTVAL/i '(' string ',' simpleVal ')'
    {
      my $ret = main::putBarrierValue($arg[0], $item{string}, $item{simpleVal});

      $return = {
        type => uc $item[0],
        value => $ret
      };
    }
  barrier: /BARRIER/i
    {
      $return = {
        type => uc $item[0],
        value => main::newBarrier($arg[0])
      };
    }
  assertion: expect_true
    {
      $return = {
        type => uc $item[0],
        value => $item[1]
      };
    }
  expect_true: /EXPECT_TRUE/i '(' disjunction ')'
    {
      $return = $item{disjunction};
    }
  disjunction: conjunction ('||' conjunction {$item[2]})(s?)
    {
      my @conjunctions = @{$item[2]};
      unshift @conjunctions, $item[1];
      $return = main::evaluateExpressionChain('||', \@conjunctions);
    }
  conjunction: compareExpression ('&&' compareExpression {$item[2]})(s?)
    {
      my @compareResults = @{$item[2]};
      unshift @compareResults, $item[1];
      $return = main::evaluateExpressionChain('&&', \@compareResults);
    }
  compareExpression: expression ((relationalOpStr | relationalOpNum) expression {[@item]})(?)
    {
      #$item[2] is an array of array, where the nested array has 3 entries with rule, operator and expression
      my $expression;
      my $compareClause = $item[2];

      # check if there is a compareExpression
      if (scalar @{$compareClause}) {
        $expression = Expression->new(
          lhs => $item[1],
          operator => $compareClause->[0]->[1],
          rhs => $compareClause->[0]->[2]
        );
      } else {
        $expression = Expression->new(lhs => $item[1]);
      }

      $return = $expression->evaluate;
    }
  expression: simpleVal | remoteVal
  simpleVal: string | number
  remoteVal: /GETVAL/i '(' string ',' number ')'
    {
      $return = main::fetchBarrierValue($item{number}, $item{string});
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

sub evaluateExpressionChain {
  my ($operator, $expressions) = @_;
  my $expression = join(" $operator ", @{$expressions});
  return eval $expression || 0;
}

sub putBarrierValue {
  my ($processId, $param, $value) = @_;
  my $process = getProcessById($processId);
  return $process->putBarrierValue($param, $value);
}

sub fetchBarrierValue {
  my ($processId, $param) = @_;
  my $process = $REMOTE_VALS[$processId];
  return $process->fetchBarrierValue($param) || 0;
}

sub newBarrier {
  my $processId = shift;
  my $process = getProcessById($processId);
  return $process->newBarrier;
}

sub getProcessById {
  my $processId = shift;
  my $process = $REMOTE_VALS[$processId];

  unless (defined $process) {
    $process = Process->new;
    $REMOTE_VALS[$processId] = $process;
  }

  return $process;
}

sub checkResultNotEmpty {
  my $value = shift;
  return defined $value && $value ne '' && $value ne '0';
}

my $p = new Parse::RecDescent( $grammar ) or die "Compile error\n";
while ( <> )
{
  chomp;
  ##print "parsing: $_\n";
  my $result = $p->start( $_ );
  my $processId = $result->{processId};
  my $actionResult = $result->{actionResult};

  if (defined($actionResult)) {
      my $evalRes = checkResultNotEmpty($actionResult->{value});

      if ($actionResult->{type} eq ASSERTION) {
        print join (' --> ', $_, $evalRes ? "PASS\n" : "FAILURE\n");
      } elsif ($actionResult->{type} eq BARRIER) {
        print "Log Barrier added for process with id: $processId\n" if $evalRes;
      }
  } else {
    print "Invalid Syntax\n";
  }
}
