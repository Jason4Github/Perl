#!/usr/local/bin/perl
#		NAME
#			INSTALL_IDMLCM_CDC.pl
#
#		DESCRIPTION
#			Install idmlcm.zip
#			If IDMLCM_LOC is imported, use that instead of from FA_REPO
#
#		Changelog
#
#		MODIFIED   (MM/DD/YY)
#		Lancer Guo	12/21/13	v0.1 	Creation
use File::Copy;
use File::Basename;

BEGIN
{
	use File::Basename;
	use Cwd;
	$orignalDir = getcwd();
	$scriptDir = dirname($0);
	chdir($scriptDir);
	$scriptDir =  getcwd();
	$plibDir = "$scriptDir/../../../plib";
	chdir($plibDir);
	$plibDir = getcwd();
	unshift  (@INC,"$plibDir");
	unshift  (@INC,"$scriptDir/../../idm/tools/perl_lib");
	chdir($orignalDir);
}

require DTE;

if ( $#ARGV < 2)
{
	print ("Usage: perl $0 import.txt export.txt runtime.txt\n");
	exit 1;
}

$importfile  = $ARGV[0];
$exportfile  = $ARGV[1];
$runtimefile = $ARGV[2];

%ImportParamTable = ();
# HOSTNAME
# SWITCH
# EMAIL_LIST
# DIF_CHECK_INTERVAL
%RuntimeParamTable = ();
%ExportParamTable = ();
$exit_value = 1;

print "\n\nParsing runtime.txt ...\n\n";
%RuntimeParamTable=DTE::parse_runtime_file($runtimefile);
print "\n\nParsing import.txt ...\n\n";
%ImportParamTable = DTE::parse_import_file($importfile, %RuntimeParamTable);

$ExportParamTable{HOSTNAME} = $ImportParamTable{HOSTNAME};
$ExportParamTable{EXIT_STATUS} = "FAILURE";

operation();

if ($exit_value == 0){
	$ExportParamTable{EXIT_STATUS} = "SUCCESS";
}

print "\n\Populating export.txt ...\n\n";
DTE::populate_export_file($exportfile, %ExportParamTable);

exit $exit_value;

sub check_dif {
    my $log = shift;
    my $child_pid = fork();
    if ( $child_pid == 0 ) {
        open (STDOUT, ">$log") or die "Dif checker could not open $log for STDOUT.\n";
        open (STDERR, ">&STDOUT") or die "Dif checker could not open /dev/null as STDERR.\n";

        while(1) {
            sleep $ImportParamTable{DIF_CHECK_INTERVAL};
			my $dif = `ls $RuntimeParamTable{WORKDIR}/../*.dif`;
			if ( $dif=~m/.*\.dif/ ) {
    			print STDOUT "There is a dif generated!\n";
    			print STDOUT "HOSTNAME: $RuntimeParamTable{MachinesAssignedToJob}\n";
    			print STDOUT "DTEJobID: $RuntimeParamTable{DTEJobID}\n";
    			print STDOUT "Dif file: $dif\n";
				`mail -s "Dif generated in job $RuntimeParamTable{DTEJobID}" "$ImportParamTable{EMAIL_LIST}" < $log`;	
				exit 1;
			}
        }

        exit 1;
    } else {
        return $child_pid;
    }
}

sub operation {
	if ( lc($ImportParamTable{SWITCH}) eq "on" ) {
		check_dif("$RuntimeParamTable{WORKDIR}/difchecker.log");
	}
	$exit_value = 0;
}
