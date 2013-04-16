#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Getopt::Long;
use Data::Dumper;
use IO::File;

#my $gtf = '/home/soh.i/nucRNA/data/Drosophila_melanogaster/UCSC/dm3/Annotation/Genes/genes.gtf';
#my $refGene = '/home/soh.i/nucRNA/data/Drosophila_melanogaster/UCSC/dm3/Annotation/Genes/refGene.txt';
my $refFlat = '/home/soh.i/nucRNA/data/Drosophila_melanogaster/UCSC/dm3/Annotation/Genes/refFlat.txt';

my $data = {};
my $refflat_io = IO::File->new($refFlat, 'r') or die $!;
while (my $line = $refflat_io->getline) {
    my ($gene_id,
        $tx_id,
        $chr,
        $strand,
        $txStart,
        $txEnd,
        $cdsStart,
        $cdsEnd,
        $exonCount,
        $exonStarts,
        $exonEnds,
       ) = (split /\t/, $line)[0..10];
    
    $data->{source}->{desc}      = "Parsing from refFlat.txt, Archive-2013-03-06-11-04-22 (iGenomes)";
    $data->{source}->{url}       = 'ftp://igenome:G3nom3s4u@ussd-ftp.illumina.com/Drosophila_melanogaster/UCSC/dm3/Drosophila_melanogaster_UCSC_dm3.tar.gz';
    $data->{$tx_id}->{gene_id}   = $gene_id;
    $data->{$tx_id}->{tx_id}     = $tx_id;
    $data->{$tx_id}->{chr}       = $chr;
    $data->{$tx_id}->{txStart}   = $txStart;
    $data->{$tx_id}->{txEnd}     = $txEnd;
    $data->{$tx_id}->{ExonCount} = $exonCount;
    
    my @start = split /,/, $exonStarts;
    my @end   = split /,/, $exonEnds;
    my $chck = 0;
    for my $join (0..$exonCount-1) {
        push @{ $data->{$tx_id}->{join} }, $start[$join] . '..' . $end[$join];
        $chck++;
    }
    die "[Parsing error]:$!" if $chck ne $exonCount;
    
    
}
$refflat_io->close;
print Dumper $data;


my $bed;
my $bed_io = IO::File->new($bed, 'r') or die $!;
while (my $line = $bed_io->getline) {
    my ($chr, $pos, $depth) = (split /\t/, $line)[0..2];
    
}
$bed_io->close;
