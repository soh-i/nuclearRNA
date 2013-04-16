#!/usr/bin/env perl

use strict;
use warnings;

use IO::File;
use Storable qw{nfreeze thaw nstore retrieve};

$| = 0;

my $inBED = shift or die;

my $io = IO::File->new($inBED, 'r') or die;

my $bed_store    = {};
my $storable_out = "$inBED.store";

while (my $entory = $io->getline) {
    chomp $entory;
    my ($chr, $pos, $depth) = (split /\t/, $entory)[0..2];
    my $primary_key = $chr.$pos;
    
    my $command = 'genomeCoverageBed -i ~/nucRNA/data/Drosophila_melanogaster/UCSC/dm3/Annotation/Genes/genes.gtf -ibam ~/nucRNA/data/fq/GeneDev_2012/SRR352499_tophat/accepted_hits.bam -split -d -g ~/nucRNA/data/Drosophila_melanogaster/UCSC/dm3/Sequence/WholeGenomeFasta/genome.fa > SRR352499.genomeCov.bed';
    
    $bed_store->{source}->{processing}  = $command;
    $bed_store->{$primary_key}->{chr}   = $chr;
    $bed_store->{$primary_key}->{pos}   = $pos;
    $bed_store->{$primary_key}->{depth} = $depth;
    
}
$io->close;

# Output the stored file.
nstore $bed_store, $storable_out;


