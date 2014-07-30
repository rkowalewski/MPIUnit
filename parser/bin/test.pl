#!/usr/bin/perl

use strict;
use warnings;

#add the lib directory to @INC
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(dirname abs_path $0) . '/lib';

use RemoteValue;
use Expression;
use SimpleValue;
use Process;

sub testExpression {
  my $expression = Expression->new(lhs=>10);
  print "the result is: " . $expression->evaluate . "\n";
  $expression = Expression->new(lhs=>10, operator=> "<=", rhs => 20);
  print "the result is: " . $expression->evaluate . "\n";
  $expression = Expression->new(lhs=>10, operator=> "<=", rhs => 5);
  print "the result is: " . $expression->evaluate . "\n";
}

sub testProcess {
  my $process = Process->new;
  $process->putBarrierValue("rank", 1);
  $process->putBarrierValue("nprocs", 2);
  $process->newBarrier;
  $process->putBarrierValue("other", "10");
  my $rank = $process->fetchBarrierValue("rank");

  print "The read rank is: $rank\n" if defined $rank;
}

testExpression;
testProcess;
