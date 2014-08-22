#!/usr/bin/perl

use strict;
use warnings;

#package Animal;

#use Class::Interface;
#&interface;

#sub sayHello;


package Dog;

#use Class::Interface;
#&implements('Animal');

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);
  return $self;
}

sub sayhello {
  print "I am  a dog\n";
  return 1;
}

package Cat;
#use Class::Interface;
#&implements('Animal');

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);
  return $self;
}

sub sayHello {
  print "I am a Cat\n";
  return 1;
}

package main;

sub checkResultNotEmpty {
  my $value = shift;
  return defined $value && $value ne '' && $value ne '0';
}

my $dog = Dog->new;
my $five = 5;
my $string1 = "test";
my $string2 = 'test2';

print 'The type is: ' . ref($dog) . "\n";
print "The type of $five is empty\n" unless checkResultNotEmpty(ref($five));
print "type of $string1 is empty\n" unless checkResultNotEmpty(ref($string1));
print "type of $string2 is empty\n" unless checkResultNotEmpty(ref($string2));

