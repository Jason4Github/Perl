#!/scratch/Jason/applib/perl5.20.1/bin/perl -w
use warnings;

my @arr = (72, 6, 57, 88, 60, 42, 83, 73, 48, 85);

foreach my $i (@arr) {
    print $i." ";
}
print "\n";

my $size = scalar @arr;
quicksort(0, $size-1);

foreach my $i (@arr) {
    print $i." ";
}
print "\n";

sub quicksort {
    my ($left, $right) = @_;
    if ( $left < $right ) {
        my $i = $left, $j = $right, $x = $arr[$left];
        while ($i < $j) {
            while (($i < $j) && ($arr[$j] >= $x)) {
                $j--;
            }
            if ( $i < $j ) {
                $arr[$i] = $arr[$j];
                $i++;
            }
            while (($i < $j) && ($arr[$i] < $x)) {
                $i++;
            }
            if ( $i < $j ) {
                $arr[$j] = $arr[$i];
                $j--;
            }
        }
        $arr[$i] = $x;
        quicksort($left, $i-1);
        quicksort($i+1, $right);
    }
}