#! C:\strawberry\perl\bin -w

#use strict;
use IO::Tee;
sub handle_file {
   my $path = shift;

   my @dirs = grep {-d $_} glob "$path\\*"; 
   foreach (@dirs){
      handle_file($_);
   }
   my @files = glob "$path\\*";
   foreach (@files) {
       my $fail_count = 0;

       #open LOG, "+>>$path\\result.log" or die "open log failuer\n";
       #print LOG "$_\n";
       my $tee = IO::Tee->new(">>$path\\result.log", \STDOUT);
       print $tee "$_";
       open FILE, $_;
       while (<FILE>) {
           ++$fail_count if grep(/FAIL/, $_);
       }
       close FILE;

       if ($fail_count > 0) {
           #print LOG "FAIL, $fail_count times FAIL be found\n\n";
           print $tee "FAIL, $fail_count times FAIL be found\n\n"
       } else {
           #print LOG "PASS, testing pass\n\n" ;
           print $tee "PASS, testing pass\n\n" ;          
       }
       
       #close LOG;
   }


}

handle_file("D:\\Perl_script");

no IO::Tee;

pause();
