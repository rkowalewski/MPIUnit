#!/usr/bin/perl
use strict;
use Parse::RecDescent;

#use vars qw(%VARIABLE);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my $grammar = <<'GRAMMAR';
    start: prefix assertion
    assertion: expect_gt | expect_eq | expect_true

    # EXPECT_GT Rule
    expect_gt: /EXPECT_GT/i '('  number ',' number ')'
      {
        $return = main::expression({
          _op => '>',
          _lhs => $item[3],
          _rhs => $item[5]
        });
      }

    # EXPECT_EQ Rule
    expect_eq: /EXPECT_EQ/i '(' expression ',' expression ')'
      {
        $return = main::expression({
          _op => 'eq',
          _lhs => $item[3],
          _rhs => $item[5]
        });
      }

    expect_true: /EXPECT_TRUE/i '(' disjunction ')'
      {
        $return = $item[3];
      }
    disjunction: conjunction ('||' conjunction)(s?)
      {
        if (@{$item[2]}) {
          $return = main::expression({
            _op => '||',
            _lhs => $item[1],
            _rhs => @{$item[2]}
          });
        } else {
          $return = $item[1];
        }
      }
    conjunction: booleanExp ('&&' booleanExp)(s?)
      {
        if (@{$item[2]}) {
          $return = main::expression({
            _op => '&&',
            _lhs => $item[1],
            _rhs => @{$item[2]}
          });
        } else {
          $return = $item[1];
        }
      }
    booleanExp: numberComp | stringComp
    expression: number | string
    string: /['"]\w+['"]/
    number: /[-+]?\d+/
    numberComp: number relationalOpNum number
      {
        $return = main::expression({
          _op => $item[2],
          _lhs => $item[1],
          _rhs => $item[3]
        });
      }
    stringComp: string relationalOpStr string
      {
        $return = main::expression({
          _op => $item[2],
          _lhs => $item[1],
          _rhs => $item[3]
        });
      }
    relationalOpNum: /[<>]\=?|\={2}/
    relationalOpStr: /[gl][te]/
    prefix: / ^\w   #Leading alpha-numerical char
              \w*   #follow by optional alpha-numerical chars
              :\s*  #follow by colon and optional white spaces
            /ix # case/space/comment insensitive
GRAMMAR

sub expression {
  my $hash = shift(@_);
  #print 'lhs is: ', "$hash->{_lhs}\n";
  #print 'The operator is: ', "$hash->{_op}\n";
  #print 'rhs is: ', "$hash->{_rhs}\n";
  my $expression = join(" ", $hash->{_lhs}, $hash->{_op}, $hash->{_rhs});
  #print 'my expression is: ', "$expression\n";
  my $return = eval $expression || 0;
  #print 'the evaluated result is: ', "$return \n";
  return $return;
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
