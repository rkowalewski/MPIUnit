#!/usr/bin/perl

use strict;
use warnings;

package FooObj;

sub new
{
        my $this  = shift;
        my $class = ref($this) || $this;
        my $self  = {};
        bless $self, $class;
        $self->initialize();
        return $self;
}

sub initialize { }
sub add_data   { }

package BarObj;

#use FooObj; <-- not needed.

sub new
{
        my $this  = shift;
        my $class = ref($this) || $this;
        my $self  = { myFoo => FooObj->new() };
        bless $self, $class;
        $self->initialize();
        return $self;
}
sub initialize  { }
sub some_method { }
sub myFoo       { return $_[0]->{myFoo} }

package main;
use Test::More;
my $bar = BarObj->new();
isa_ok( $bar,        'BarObj', "bar is a BarObj" );
isa_ok( $bar->myFoo, 'FooObj', "bar->myFoo is a FooObj" );
done_testing();
