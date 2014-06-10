#!/usr/bin/perl

my $test = "Hello";
print "true" if $test=~/Hello/i;
my $test2="EXPECT_TRUE(1<6 && 5<7)";
print "true" if $test2=~/EXPECT_TRUE\([-+]?\d+[<>]\=?[-+]?\d+\s*(\&|\|){2}\s*[-+]?\d+/;
