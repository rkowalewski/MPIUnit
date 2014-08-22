#!/usr/bin/perl

use strict;
use warnings;
use Parse::RecDescent;

#add the lib directory to @INC
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname (dirname abs_path $0) . '/lib';

my $parser = Parser::Processor->new;
while ( <> )
{
  chomp;

  my $result = $parser->eval( $_ );
  #my $actionResult = $result->{actionResult};

  if ($result) {
    #my $evalRes = checkResultNotEmpty($actionResult->{value});

    #if ($actionResult->{type} eq ASSERTION) {
    #   print join (' --> ', $_, $evalRes ? "PASS\n" : "FAILURE\n");
    # } elsif ($actionResult->{type} eq BARRIER) {
    #   print "Log Barrier added for process with id: $processId\n" if $evalRes;
    # }
  } else {
    print "Invalid Syntax\n";
  }
}
