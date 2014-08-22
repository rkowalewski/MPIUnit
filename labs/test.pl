#!/usr/bin/perl
use strict;
use warnings;
use Scalar::Util qw(reftype);

my $test = "Hello";
print "true\n" if $test=~/Hello/i;
my $test2="EXPECT_TRUE(1<6 && 5<7)";
print "true\n" if $test2=~/EXPECT_TRUE\([-+]?\d+[<>]\=?[-+]?\d+\s*(\&|\|){2}\s*[-+]?\d+/;

my $obj  = bless {}, "Foo";

my $hash = {
  scalar => "5",
  array => [1,2,3],
  object => $obj
};

foreach (keys %{$hash}) {
  print "The key $_ has value $hash->{$_}\n";
  print "The type of entry $_ is " . ref($hash->{$_}) . "\n" if (defined ref($hash->{$_}) && ref($hash->{$_}) ne '');

  last if ref($hash->{$_}) eq 'ARRAY';
}




