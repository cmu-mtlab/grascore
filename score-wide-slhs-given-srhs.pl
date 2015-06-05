use strict;


# Check usage:
if($#ARGV != 0)
{
    print STDERR "Usage:\n";
    print STDERR "    cat <wide-rules> | perl $0 <score-names>\n";
    print STDERR "where <wide-rules> is in the wider seven-column grammar format and\n";
    print STDERR "where <score-names> is a space-delimited file of score names already\n";
    print STDERR "appearing in <wide-rules>\n\n";
    print STDERR "Output goes to standard out and <score-names>.new\n";
	exit(1);
}


# Global constants and parameters:
my $COUNT_SNAME = "count";
my $PSLHS_SNAME = "slhsGsrhs";
my $SN_FILE = $ARGV[0];

# Read in list of score names already in rules:
open(my $FILE, $SN_FILE) or die "Can't open input file $SN_FILE: $!";
my $line = <$FILE>;
close($FILE);
chomp $line;
my @ScoreNames = split(/\s+/, $line);

# Make sure the rule count is one of the existing score names:
my $countIndex = -1;
for my $i (0..$#ScoreNames)
{
    if($ScoreNames[$i] eq $COUNT_SNAME)
    {
	$countIndex = $i;
	last;
    }
}
if($countIndex == -1)
{
    print STDERR "ERROR:  Input rules don't have count field, or score names file incorrect.\n";
    exit(1);
}

# Accumulator for multiple rules with the same source right-hand side:
my %RuleSrcLhss = ();
my %SrcLhsCounts = ();
my $currSrcRhs = "";
my $totalCount = 0;

# Read wide-format rule instances from standard in, one per line:
# NOTE: This assumes rules are sorted by wide field 4!
while(my $line = <STDIN>)
{
    # Break rule line into fields:
    chomp $line;
    my ($type, $srcLhs, $tgtLhs, $srcRhs, $tgtRhs, $aligns, $scores) =
	split(/\t/, $line);
    my @Scores = split(/\s+/, $scores);

    # If different source RHS than previously, write out and score old rules:
    if($srcRhs ne $currSrcRhs)
    {
	# Write out and score old rules:
	if($totalCount > 0)
	{
	    foreach my $r (keys %RuleSrcLhss)
	    {
		my $pslhs = $SrcLhsCounts{$RuleSrcLhss{$r}} / $totalCount;
		print "$r $pslhs\n";
	    }
	}

	# Reset accumulator:
	%RuleSrcLhss = ();
	%SrcLhsCounts = ();
	$currSrcRhs = $srcRhs;
	$totalCount = 0;
    }

    # Add this rule and its count to the appropriate source-LHS accumulator:
    $RuleSrcLhss{"$type\t$srcLhs\t$tgtLhs\t$srcRhs\t$tgtRhs\t$aligns\t$scores"} = $srcLhs;
    $SrcLhsCounts{$srcLhs} += $Scores[$countIndex];
    $totalCount += $Scores[$countIndex];
}

# At end, write out final rule still in accumulator:
if($totalCount > 0)
{
    foreach my $r (keys %RuleSrcLhss)
    {
	my $pslhs = $SrcLhsCounts{$RuleSrcLhss{$r}} / $totalCount;
	print "$r $pslhs\n";
    }
}

# Write out new list of score names:
open($FILE, "> $SN_FILE.new") or die "Can't open output file $SN_FILE.new: $!";
print $FILE "@ScoreNames $PSLHS_SNAME\n";
close($FILE);
