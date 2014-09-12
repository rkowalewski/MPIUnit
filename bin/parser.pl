#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Carp;

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
  if ($result) {
    my $resultVal = $result->{resultValue};
    if ($result->{type} eq 'ASSERTION') {
      if ($result->{resultType} eq 'PROCESSED') {
        my $resultStr =  $resultVal ? 'OK' : 'ERROR';
        print join('-->', $_, "$resultStr\n");
      } elsif ($result->{resultType} eq 'DEFERRED') {
        print $_ . ' --> Deferred: Waiting for processes [' . join(',', @{$resultVal->{waitingForProcesses}}) . "] to flush barrier #${\($resultVal->{barrierIdx})}\n";
      }
    } elsif ($result->{type} eq 'PUTVAL') {
      if ($result->{resultType} eq 'PROCESSED') {
        print $_ . " --> added value tuple (${\($resultVal->{param})}, ${\($resultVal->{value})}) to barrier #${\($resultVal->{barrierIdx})}\n";
      }
    } elsif ($result->{type} eq 'BARRIER') {
      print $_ . " --> flushed Barrier #$resultVal. Could also resolve ${\($result->{resolvedDeferredCount})} deferred Assertions.\n";
    }

  } else {
    print "Invalid Syntax\n";
  }
}

if ($parser->hasUnresolvedAssertions) {
  carp "\nThere are still some deferred assertions --> check the log\n";
} else {
  print "\nRelax and drink some beer!!\n";
}
