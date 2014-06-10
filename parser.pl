#!/usr/bin/perl
use strict;
use Parse::RecDescent;

#use vars qw(%VARIABLE);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my $grammar = <<'GRAMMAR';
    start: prefix(s?) assertion
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
    disjunction: conjunction ('||' conjunction)(s?)
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
    booleanExp: number relationalOpNum number
              | string relationalOpStr string
      {
        $return = main::expression({
          _op => $item[2],
          _lhs => $item[1],
          _rhs => $item[3]
        });
      }
    expression: number | string
    string: /['"]\w+['"]/
    number: /[-+]?\d+/
    relationalOpNum: /[<>]\=?/
    relationalOpStr: /[gl][te]/
    prefix: / ^\w   #Leading alpha-numerical char
              \w*   #follow by optional alpha-numerical chars
              :\s*  #follow by colon and optional white spaces
            /ix # case/space/comment insensitive
GRAMMAR

sub expression {
  my $hash = shift(@_);
  my $expression = join(" ", $hash->{_lhs}, $hash->{_op}, $hash->{_rhs});
  my $evaluated = eval $expression;
  return $evaluated ? $evaluated : 0;
}


my $p = new Parse::RecDescent( $grammar ) or die "Compile error\n";
while ( 1 )
{
    chomp( $_ = <STDIN> );
    my $result = $p->start( $_ );

    if (defined($result) && $result ne '') {
      print join(' --> ', $_, "PASS\n");
    } else {
      print join(' --> ', $_, "FAILURE\n");
    }
}
