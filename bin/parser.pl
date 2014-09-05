#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

#add lib directory to @INC
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname (dirname abs_path __FILE__) . '/lib';
use Parser::Processor;

my $parser = Processor->new;
while ( <> )
{
  chomp;

  my $result = $parser->eval( $_ );
  print Dumper($result);

  if ($result) {


  } else {
    print "Invalid Syntax\n";
  }
}
