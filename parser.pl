#!/usr/bin/perl
use strict;
use Parse::RecDescent;
use Scalar::Util qw( reftype );
#use vars qw(%VARIABLE);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my %resultTypes = {
  PASS => 1, FAILURE => 2, DEFERRED => 3
};

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
  disjunction: conjunction ('||' conjunction)(s?)
    {
      $return = $item[1];
    }
  conjunction: compareExpression ('&&' compareExpression)(s?)
    {
      # process other expressions
      $return = $item[1];
    }
  compareExpression: expression ((relationalOpStr | relationalOpNum) expression {[@item]})(?)
    {
      my $expHash = {
        expected => $item[1]
      };

      #$item[2] is an array of array, where the nested array has 3 entries with rule, operator and expression
      my @compareExpression = @{$item[2]};

      if (scalar @compareExpression) {
        $expHash->{operator} = $compareExpression[0][1];
        $expHash->{actual} = $compareExpression[0][2];
      }

      $return = main::compareExpression($expHash);
    }
  expression: simpleVal | remoteVal
  simpleVal: string | number
    {
      $return = {
        _isRemote => 0,
        _value => $item[1]
      };
    }
  remoteVal: /GETVAL/i '(' string ',' number ')'
    {
      $return = {
        _isRemote => 1,
        _value => {
          rank => $item{number},
          paramName => $item{string}
        }
      };
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
  my $exp = shift;

  if (!(exists($exp->{operator}) || exists($exp->{actual}))) {
    if ($exp->{expected}->{_isRemote}) {
      #process remoteVal;
    } else {
      return $exp->{expected}->{_value};
    }
  } else {
    if (!($exp->{expected}->{_isRemote} || $exp->{actual}->{_isRemote})) {
      my $expressionStr = join(" ", $exp->{expected}->{_value}, $exp->{operator}, $exp->{actual}->{_value});
      my $return = eval $expressionStr || 0;
      return $return;
    }
  }
}

sub booleanExpression {

}

my $p = new Parse::RecDescent( $grammar ) or die "Compile error\n";
while ( <> )
{
    chomp;
    my $result = $p->start( $_ );

    #print 'the result is: ', "$result\n";
    if (defined($result) && $result ne '' && $result ne '0') {
      print join(' --> ', $_, "PASS\n");
    } else {
      print join(' --> ', $_, "FAILURE\n");
    }
}
