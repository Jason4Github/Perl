#!/usr/bin/perl

use strict;
use warnings;


my $sl="null";
$sl = $ARGV[0];

sub getLatestLabelByAde {
    my $series = shift;

    my @labels = `/usr/dev_infra/platform/bin/ade showlabels -series $series`;
    my $latest = $labels[-1];
    chomp $latest;

    return $latest;
}

my $digital = "";
#my $series = "IDMLCM_MAIN_GENERIC";
my $series = "IDMLCM_11.1.2.3.0BP_GENERIC";
my $label = "";
if ( defined $sl && $sl =~ m/GENERIC_\d{6}\.\d{4}$/ ) {
	$label = $sl;
	chomp $label;
} else {
	$label = getLatestLabelByAde("$series");
}

###debug, manual set label
#$label = "IDMLCM_MAIN_GENERIC_150627.1701";

if ( $label =~ m/\w+?(\d{6}\.\d{4})/g ) {
    $digital = $1;
}

my $output_file = "./$label.result.log";
open(my $OUT, ">", $output_file) or die "Can't open $output_file: $!";
print $OUT "start to analyze label: $label\n\n";
print "see result in $label.result.log\n\n";

#my $label_res_url = "http://dstintg.us.oracle.com/products/IDMLCM/MAIN/GENERIC/$digital/html/";
my $label_res_url = "http://dstintg.us.oracle.com/products/IDMLCM/11.1.2.3.0BP/GENERIC/$digital/html/";
my $label_res_page = `curl -silent $label_res_url | grep -ri linux.x64_r2ps3`;
if ( $label_res_page !~ /linux.x64_r2ps3/i) {
    print $OUT "no jobs runing till now. date: ".`date`." \n";
    close $OUT;
    exit 1;
}

my $difNumbers = 0;
my $sucNumbers = 0;
my $total = 0;

my @label_res_page_content = split("\n", $label_res_page);
$total = @label_res_page_content;
foreach my $each_job (@label_res_page_content) {
    $each_job =~ /href="(linux\.x64_r2ps3*.*html)">/;
    my $job_url = $label_res_url.$1;
    print $OUT substr(uc($1),0,-5)."\n";

    my $job_res_page = `curl -silent $job_url`;
    my @job_res_page_content = split("\n", $job_res_page);
    my $difnum = grep(/\w+\.dif/i, @job_res_page_content);
    if ( $difnum == 0 ) {
	print $OUT "success[0 dif]: $1\n\n";
        $sucNumbers++;
    } else {
	$difNumbers++;
	foreach my $r (@job_res_page_content) {
		if ($r =~ /<a href="(.*)">Browse the regression results area/) {
                    my $dte_job_report = $1."/DTEJobReport.log";
                    my $job_report_page = `curl $dte_job_report`;
                    $job_report_page =~ /(JobReqID=[0-9]*)/;
                    print $OUT $1."\n";
                }
                if ($r =~ /(Difs: [0-9]*)/) {
                    print $OUT $1."\n";
                }
                if ($r =~ /">(.*\.dif)</) {
                    print $OUT $1."\n";
                }
        }
        print $OUT "\n";

    }
}

print $OUT "\n\n=======================================\n";
print $OUT "=========total topos: $total===============\n";
print $OUT "=========success topos: $sucNumbers==============\n";
print $OUT "=========diffs topos: $difNumbers================\n";
print $OUT "=======================================\n";

close $OUT;

if ( $total == $sucNumbers ) {
	print "no dif occurred\n";
} else {
	print "got $difNumbers difs\n";
}
