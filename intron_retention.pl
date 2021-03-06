#!/usr/bin/env perl

use warnings;
use strict;

use IO::File;
use Data::Dumper;
use DBI;
use Getopt::Long;

$| = 1;

my %opt = ();
my $help = undef;
GetOptions(
           \%opt,
           'help|h' => \$help,
           'db=s',
          ) or die _help();

if ($help) {
    print _help();
    exit 0;
}

if (!$opt{db}) {
    print "SQLite database is not specified!\n";
    print _help();
    exit 0;
}

my $data_source = "dbi:SQLite:dbname=$opt{db}";
my $dbh = DBI->connect($data_source) or die $DBI::errstr;

# Retrive the SQL table name
my @names  = $dbh->tables();
(my $table) = $names[0] =~ m/\.\"(.+)\"/;

# Parsing refFlat file
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
    $data->{$tx_id}->{exonCount} = $exonCount;
    $data->{$tx_id}->{txLength}  = ($txEnd - $txStart);
    
    my @start = split /,/, $exonStarts;
    my @end   = split /,/, $exonEnds;
    my $chck = 0;
    for my $join (0..$exonCount-1) {
        my $exon_length   = $end[$join] - $start[$join];
        my $intron_length = $data->{$tx_id}->{txLength} - $exon_length;
        $data->{$tx_id}->{exonLength}   += $exon_length;
        $data->{$tx_id}->{intronLength} += $intron_length;
        
        push @{ $data->{$tx_id}->{exonStart} }, $start[$join];
        push @{ $data->{$tx_id}->{exonEnd}   }, $end[$join];
        $chck++;
    }
    die "[Parsing error]:$!" if $chck ne $exonCount;

}
$refflat_io->close;


for my $key ( keys %{$data} ) {
    my $gene_coverage = 0;
    my $exon_coverage = 0;

    # Fetch as gene (Full length of trancsript)
    #die $key unless (defined $data->{$key}->{txStart} || defined $data->{$key}->{txEnd});
    
    my $sth = $dbh->prepare("select * from $table where chr=\'$data->{$key}->{chr}\' and pos between $data->{$key}->{txStart} and $data->{$key}->{txEnd};");
    $sth->execute or die $sth->errstr;
    
    while (my $gene = $sth->fetchrow_arrayref) {
        my ($chr, $pos, $depth) = @{ $gene };
        $gene_coverage += $depth;
    }

    # Fetch as exon 
    next if $data->{$key}->{exonCount} < 0;
    for (my $i = 0; $i<$data->{$key}->{exonCount}; $i++) {
        
        $sth = $dbh->prepare("select * from $table where chr=\'$data->{$key}->{chr}\' and pos between $data->{$key}->{exonStart}[$i] and $data->{$key}->{exonEnd}[$i];");
        $sth->execute or die $sth->errstr;
        
        my $length = 0;
        while (my $BED = $sth->fetchrow_arrayref) {
            my ($chr, $pos, $depth) = @{ $BED };
            $exon_coverage += $depth;
        }
    }
    
    #printf "%s12\t%s20\t%d8\t%d8\t", $data->{$key}->{chr}, $data->{$key}->{tx_id}, $data->{$key}->{txStart}, $data->{$key}->{txEnd}; 
    
    my $score = _calculate_SE(
                              intronCov => $gene_coverage - $exon_coverage,
                              exonCov   => $exon_coverage,
                              geneLen   => $data->{$key}->{txLength},
                              exonLen   => $data->{$key}->{exonLength},
                              intronLen => $data->{$key}->{intronLength}
                             );
    #$score ne 'NA' ? printf "%2.4f\n", $score : printf "%s\n", $score;
    print $score, "\n";
    
}
$dbh->disconnect;

sub _calculate_SE {
    my %args = (
                intronCov  => undef,
                exonCov    => undef,
                geneLen    => undef,
                intronLen  => undef,
                exonLen    => undef,
                @_,
               );
    
    if ( $args{intronCov} > 0 && $args{exonCov} > 0 && $args{geneLen} > 0 && $args{intronLen} > 0 && $args{exonLen}) {
        my $normalized_intron_signal = $args{intronCov} / $args{intronLen};
        my $normalized_exon_signal   = $args{exonCov} / $args{exonLen};
        
        my $score = undef;
        if (!$normalized_intron_signal == 0 && !$normalized_exon_signal == 0) {
            $score = log($normalized_intron_signal / $normalized_exon_signal);
            return $score;
        }
        else {
            $score = 'NA';
            return $score;
        }
    } 
    else {
        return 'NA';
    }
}

sub _help {
    return <<EOF;
Usage:
    perl $0 --db <in.sqlite3>

Options:
    --db   Given a SQLite database.
    --help Show help messages.
    
EOF

}
