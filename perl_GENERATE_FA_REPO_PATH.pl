#!/usr/local/bin/perl
#		NAME
#			get_fa_repo_path.pl
#
#		DESCRIPTION
#			Generate paths of FA_REPO and DB_SHIPHOME from view and label.
#
#		Changelog
#
#		MODIFIED   (MM/DD/YY)
#		Lancer Guo	11/12/13	v0.1 	Creation
#		Lancer Guo	11/13/13	v0.2 	Add DB_PATH
#		Lancer Guo	11/13/13	v0.3		Add param USE_MY_REPO; fetch repo from the latest label
#		Lancer Guo	11/14/13	v0.31 	Print more information. check if commands are successfully executed
#		Lancer Guo	11/14/13	v0.32	Change SERIES to an import parameter, not hard code any more
#		Lancer Guo	11/14/13	v0.4		Add function: get yesterday's label
#		Lancer Guo	11/18/13	v0.41	Minor tweaks about logging; change about yesterday's label: if the last label of yesterday doesn't exist check the second last one
#		Lancer Guo	11/28/13	v0.5		Add SHIPHOME. if not default, set it to fa_repo_loc
#		Lancer Guo	12/10/13	v0.6		Don't copy shiphome to local unless need to replace idmlcm.zip
#		Lancer Guo	12/10/13	v0.61	If shiphome=%ADE_VIEW_ROOT%/idm/shiphome/iamsuite*.zip get repo from view's label. Add notes for logical procedure
#		Lancer Guo	12/10/13	v0.62	Change get_label_from_pwv
#		Lancer Guo	12/16/13	v0.63	Add logs for debugging. Minor change is_idm/idmlcm_label
#		Lancer Guo	12/19/13	v0.7		Add REPLACE_IDMLCM_WITH_LOCAL and IDMLCM_LOC.
#												If the former is true, copy FA_REPO_LOC to local host and replace idmlcm.zip with IDMLCM_LOC
#		Lancer Guo	12/20/13	v0.71	Do not copy FA_REPO_LOC to local host if REPLACE_IDMLCM_WITH_LOCAL is true
#										 	 	Replace IDMLCM_LOC directly to FA_REPO_LOC
#										 	 	Change loggings and notes
#		Lancer Guo	12/31/13	v0.72	Support dir and zip for IDMLCM_LOC
#		Lancer Guo	01/06/14	v0.73	Change unzip to unzip -u in case the dest dir already exists
#		Lancer Guo	01/06/14	v0.74   Change the default val of $SERIES to %SERIES%. If the val is by default, use IDM_11.1.2.2.0_GENERIC
#		Lancer Guo	03/26/14	v0.75   if idmlcm.zip is used, copy it to local and unzip to avoid no write permission issue.
#		Lancer Guo	07/15/14	v0.8    Change SHIPHOME mode. If SHIPHOME is given, use it as iamsuite*.zip, copy repo from label, then replace iamsuite*.zip
#		Norman Wang 09/26/14	v0.9    Update to support preflight run.
#		Norman Wang 02/05/15	v0.91   Change preflight repo prefix

use File::Copy;
use File::Basename;
BEGIN
{
	use File::Basename;
	use Cwd;
	$orignalDir = getcwd();
	$scriptDir = dirname($0);
	chdir($scriptDir);
	$scriptDir =	getcwd();
	$plibDir = "$scriptDir/../../../plib";
	chdir($plibDir);
	$plibDir = getcwd();
	unshift	(@INC,"$plibDir");
	chdir($orignalDir);
}

require DTE;

if ( $#ARGV < 2)
{
	print ("Usage: perl $0 import.txt export.txt runtime.txt\n");
	$exit_value = -1;
	exit 1;
}

$importfile	= $ARGV[0];
$exportfile	= $ARGV[1];
$runtimefile = $ARGV[2];

# import params
$HOSTNAME="%HOSTNAME%";
$USE_MY_REPO="%USE_MY_REPO%";
$FA_REPO_LOC="%FA_REPO_LOC%";
$SHIPHOME="%SHIPHOME_AS11_IDM_11.1.2.2.0%";
$REPLACE_IDMLCM_WITH_LOCAL="%REPLACE_IDMLCM_WITH_LOCAL%";
$IDMLCM_LOC="%IDMLCM_LOC%";
$SERIES="%SERIES%";
$SERIES_DEFAULT="IDM_11.1.2.2.0_GENERIC";
# runtime params
$WORKDIR=""; 
$AUTO_HOME="";
$AUTO_WORK="";
$ENVFILE="";

# export params
$EXIT_STATUS="FAILURE"; 
$FA_REPO_PATH="";
$DB_PATH="";
$exit_value=0;

# my variables
$FA_REPO_PREFIX="/net/slcnas458/export/fmw_idm/farm_idm_repos/";
$PREFLIGHT_REPO_PREFIX="/net/slcnas538/export/idm_repos/";
$FA_REPO_POSTFIX="/Linux64";
$DB_POSTFIX="/installers/database/Disk1";
$ADE_VIEW_ROOT="";

# main procedure start here
parse_import_file();
parse_runtime_file();
parse_env_file();
set_platform_info();
operation();
populate_export_file();
exit $exit_value;

# functions

sub LOG_NOTICE {
	my $msg = shift;
	print "========== $msg ==========\n";
}

sub LOG_ERROR {
	my $msg = shift;
	print "========== ERROR! $msg ==========\n";
}
	
# get ADE_VIEW_ROOT from env file
sub parse_env_file {
	LOG_NOTICE("env file is ${ENVFILE}");
	if ( open(IN, "${ENVFILE}") )
	{
		while(my $my_line = <IN>)
		{
			chomp $my_line;
			# remove spaces
			$my_line =~ s/^\s+//;
			$my_line =~ s/\s+$//;
			my @tmp_token = split("=",$my_line);
			# get ADE_VIEW_ROOT from env file
			if ($tmp_token[0] eq "ADE_VIEW_ROOT" ) {
					 $ADE_VIEW_ROOT = $tmp_token[1];
			}
			else {
				; # ignored
			}
		}
		close (IN);
	}
	else
	{
		print "ERROR: failed to open $ENVFILE\n";
		$exit_value = 1;
	}
	LOG_NOTICE("ADE_VIEW_ROOT: $ADE_VIEW_ROOT");
}

sub get_repo_from_yesterdays_label {
    my $command = "ade showlabels -series $SERIES"; 
	LOG_NOTICE("Getting yesterday's label. The command is: $command");
    my @labels = `$command`;
    $labels[-1] =~ m/.*_([0-9]*)\.[0-9]*$/;
    my $today = $1;
    my $yesterday_label = "";
    my $i = @labels;
	my $repo = "";
    while($i--){
        if ($labels[$i] =~ m/.*GENERIC.*/) {
            $labels[$i] =~ m/.*_([0-9]*)\.[0-9]*$/;
            my $date = $1;
            if ($date eq $today) {
                next;
            } else {
                $yesterday_label = $labels[$i];
				LOG_NOTICE("Found yesterday's label: $yesterday_label");
				chomp $yesterday_label;
				$repo = $FA_REPO_PREFIX.$yesterday_label.$FA_REPO_POSTFIX;
				if ( -d $repo ) {
					LOG_NOTICE("Repo path is: $repo");
					last;	
				} else {
					LOG_NOTICE("But repo path from that label doesn't exist. Countinue to find the next label ...");
					$repo = "";
					next;
				}
            }
        }
    }
	if ( $repo eq "" ) {
		LOG_NOTICE("Didn't find any existing repo path from yesterday's label. Exit.");
		$exit_value = -1;
        exit $exit_value;
	}
    return $repo;
}

sub parse_import_file
{
	if ( open(IN, "$importfile") )
	{
		while(my $my_line = <IN>) 
		{
			chomp $my_line;
			$my_line =~ s/^\s+//;
			$my_line =~ s/\s+$//;
			my @tmp_token = split("=",$my_line);
			# need to handle if the value contains '=' itself
			my $token = $tmp_token[0] ;
			my $value = $my_line ;
			$value =~ s/$token\s*=\s*//g ;
			print "value=$value\n";
			if($token eq "HOSTNAME" ) {
				$HOSTNAME = $value;
			}
			elsif($token eq "USE_MY_REPO" ) {
				$USE_MY_REPO = $value;
				if( $USE_MY_REPO eq "%USE_MY_REPO%" ){
					$USE_MY_REPO = "false";
				}
			}
			elsif($token eq "FA_REPO_LOC") {
				$FA_REPO_LOC = $value;
			}
			elsif($token eq "SHIPHOME") {
				$SHIPHOME = $value;
			}
			elsif($token eq "SERIES") {
				$SERIES = $value;
				if($SERIES eq "%SERIES%"){
					$SERIES = $SERIES_DEFAULT;
				}
			}
			elsif($token eq "IDMLCM_LOC") {
				$IDMLCM_LOC = $value;
			}
			elsif($token eq "REPLACE_IDMLCM_WITH_LOCAL") {
				$REPLACE_IDMLCM_WITH_LOCAL = $value;
                if( $REPLACE_IDMLCM_WITH_LOCAL eq "%REPLACE_IDMLCM_WITH_LOCAL%" ){
                    $REPLACE_IDMLCM_WITH_LOCAL = "false";
                }
			}
			else {
				# any param in the import file, create a variable & assign the value
				print "New variable is defined: \$$token = $value\n";
				${$token} = $value;
			}
		}
		close (IN);
	}
	else
	{
		print "ERROR: failed to open $importfile\n";
		$exit_value = 1;
	}
}

sub parse_runtime_file
{
	if ( open(IN, "$runtimefile") )
	{
		while(my $my_line = <IN>) 
		{
			chomp $my_line;
			$my_line =~ s/^\s+//;
			$my_line =~ s/\s+$//;

			my @tmp_token = split("=",$my_line);
			if($tmp_token[0] eq "WORKDIR" ) {
				$WORKDIR = $tmp_token[1];
			}
			elsif ($tmp_token[0] eq "AUTO_HOME" ) {
				$AUTO_HOME = $tmp_token[1];
			} 
			elsif ($tmp_token[0] eq "AUTO_WORK" ) {
				$AUTO_WORK = $tmp_token[1];
			}
			elsif ($tmp_token[0] eq "TASK_ID" ) {
				$TASK_ID = $tmp_token[1];
			}
			elsif ($tmp_token[0] eq "ENVFILE" ) {
				$ENVFILE = $tmp_token[1];
			}
			else {
	; # ignored
			}
		}
		close (IN);
	}
	else
	{
		print "ERROR: failed to open $runtimefile\n";
		$exit_value = 1;
	}
}

sub set_platform_info
{
	$PLATFORM = DTE::getOS();
	if ( $PLATFORM eq 'nt' ) {
		$DIRSEP = '\\';
		$PATHSEP =';';
		$UNZIP = "\"C:\\Program Files\\WinZip\\wzunzip.exe\" -yb -o";
	}
	else {
		$DIRSEP = '/' ;
		$PATHSEP = ':';
		$UNZIP = 'unzip -o';
	}
	if ( $PLATFORM eq 'linux' ) {
		$UNZIP = '/usr/bin/unzip -o';
	}
	if ( $PLATFORM eq 'aix' ) {
		$UNZIP = '/usr/local/bin/unzip -o';
	}
}

sub populate_export_file
{
	if ( ! open (EXPFILE, ">$exportfile") ) 
	{
		print "ERROR: failed to write to $exportfile\n"; 
		$exit_value = -1;
	}
	else 
	{
		print EXPFILE "HOSTNAME=$HOSTNAME\n";
		print EXPFILE "EXIT_STATUS=$EXIT_STATUS\n";
		print EXPFILE "BLOCK_ID=$TASK_ID\n";
		print EXPFILE "FA_REPO_PATH=$FA_REPO_PATH\n";
		print EXPFILE "DB_PATH=$DB_PATH\n";
		print EXPFILE "IDMLCM_LOC=$IDMLCM_LOC\n";
		close (EXPFILE);
	}
}

sub copy_repo {
	if (!-d $FA_REPO_PATH){
		LOG_NOTICE("FA_REPO_PATH directory doesn't exist");
		LOG_NOTICE("Block failed. Exist now.");
		$EXIT_STATUS="FAILURE";
		$exit_value = -1;
		exit $exit_value;
	}
	LOG_NOTICE("Starting to copy FA_REPO to local dir.");
	if (-d "$AUTO_WORK${DIRSEP}fa_repo") {
		LOG_NOTICE("Local FA_REPO directory already exists. Delete it first...");
		my $r = system("rm -rf $AUTO_WORK${DIRSEP}fa_repo");	
		if ( $r != 0 ) {
			LOG_ERROR("Delete existing FA_REPO directory failed.");	
		}	
	}
	LOG_NOTICE("mkdir fa_rpo");	
	my $r = system("mkdir $AUTO_WORK${DIRSEP}fa_repo");
	if ( $r != 0) {
		LOG_ERROR("mkdir fa_rpo failed.");	
	}
	LOG_NOTICE("chmod fa_repo to 777");	
	my $r = system("chmod -R 777 $AUTO_WORK${DIRSEP}fa_repo");
	if ( $r != 0) {
		LOG_ERROR("chmod failed.");	
	}
	LOG_NOTICE("Copying fa_repo to local dir...");	
	my $r = system("cp -r $FA_REPO_PATH${DIRSEP}* $AUTO_WORK${DIRSEP}fa_repo${DIRSEP}");
	if ( $r != 0) {
		LOG_ERROR("Copy failed.");	
	}
	LOG_NOTICE("chmod fa_repo to 777");	
	my $r = system("chmod -R 777 $AUTO_WORK${DIRSEP}fa_repo");
	if ( $r != 0) {
		LOG_ERROR("chmod failed.");	
	}
	LOG_NOTICE("FA_REPO copy done sucessfully.");
	return 0;
}

sub replace_idmlcm {
	# decide if argument is given
	# if no argument is given, use idmlcm from view.
	# else use the parameter as idmlcm.zip
    my $idmlcm = "null";
	my $DEST_DIR = "";
    my $numParameters = @_ ;
    if ($numParameters == 1) {
        $idmlcm = shift;
        LOG_NOTICE("Use user provided idmlcm.zip: $idmlcm");
		$DEST_DIR = $FA_REPO_LOC."${DIRSEP}installers${DIRSEP}";
    } else {
        LOG_NOTICE("Use idmlcm.zip from view");
		$idmlcm = "$ADE_VIEW_ROOT${DIRSEP}idmlcm${DIRSEP}shiphome${DIRSEP}idmlcm.zip"; 
		$DEST_DIR = "$AUTO_WORK${DIRSEP}fa_repo${DIRSEP}installers${DIRSEP}";
	}
	LOG_NOTICE("Start to replace idmlcm.zip");
	LOG_NOTICE("Deleting old idmlcm directory...");
	my $r = system("rm -rf ${DEST_DIR}idmlcm");
	if ( $r != 0) {
		LOG_ERROR("Deleting old idmlcm failed.");	
	}
	LOG_NOTICE("Copying new idmlcm.zip...");
	LOG_NOTICE("New idmlcm.zip is: $idmlcm");
	my $r = system("cp -f $idmlcm ${DEST_DIR}idmlcm.zip");
	if ( $r != 0) {
		LOG_ERROR("Copy failed.");	
		$exit_value = -1;
		$EXIT_STATUS = "FAILURE";
	}
	LOG_NOTICE("Unziping new idmlcm.zip");
	my $r = system("unzip ${DEST_DIR}idmlcm.zip -d ${DEST_DIR}");
	if ( $r != 0) {
		LOG_ERROR("Unzip failed.");	
		$EXIT_STATUS="FAILURE";
		$exit_value = -1;
	}
	LOG_NOTICE("Remove idmlcm.zip");
	my $r = system("rm -f ${DEST_DIR}idmlcm.zip");
	if ( $r != 0) {
		LOG_ERROR("Remove idmlcm.zip failed.");	
	}
	return 0;
}

sub replace_iamsuite {
    my $iamsuite = $SHIPHOME;
    my $DEST_DIR = "$AUTO_WORK${DIRSEP}fa_repo${DIRSEP}installers${DIRSEP}";
    LOG_NOTICE("Start to replace iamsuite*.zip ...");
    LOG_NOTICE("Deleting old iamsuite directory ...");
    my $r = system("rm -rf ${DEST_DIR}iamsuite");
    if ( $r != 0) {
        LOG_ERROR("Deleting old iamsuite failed.");
    }
    LOG_NOTICE("Copying new iamsuite*.zip ...");
    LOG_NOTICE("New iamsuite*.zip is: $iamsuite");
    my $r = system("cp -f $iamsuite ${DEST_DIR}");
    if ( $r != 0) {
        LOG_ERROR("Copy failed.");
        $exit_value = -1;
        $EXIT_STATUS = "FAILURE";
    }
    LOG_NOTICE("Unziping new iamsuite*.zip ...");
    my $r = system("for i in ${DEST_DIR}iamsuite*.zip;do unzip \$i -d ${DEST_DIR};done");
    if ( $r != 0) {
        LOG_ERROR("Unzip failed.");
        $EXIT_STATUS="FAILURE";
        $exit_value = -1;
    }
    LOG_NOTICE("Remove iamsuite*.zip");
    my $r = system("rm -f ${DEST_DIR}iamsuite*.zip");
    if ( $r != 0) {
        LOG_ERROR("Remove iamsuite*.zip failed.");
    }
    return 0;
}

sub unzip_idmlcm {
    my $idmlcm = shift;
	if ( -d $idmlcm ) {
		return "${idmlcm}${DIRSEP}Disk1";
	} else {
		LOG_NOTICE("idmlcm.zip is used");
		LOG_NOTICE("Copy idmlcm.zipto AUTO_WORK and unzip.");
    	my $DEST_DIR = "$AUTO_WORK${DIRSEP}fa_repo${DIRSEP}installers${DIRSEP}";
		LOG_NOTICE("1. mkdir DEST_DIR");
		LOG_NOTICE("1. DEST_DIR is: ${DEST_DIR} ");
    	my $r = system("mkdir -p ${DEST_DIR}");
    	if ( $r != 0) {
        	LOG_ERROR("mkdir DEST_DIR failed");
    	}
		LOG_NOTICE("2. Copy idmlcm.zip to DEST_DIR");
    	my $r = system("cp -f $idmlcm ${DEST_DIR}idmlcm.zip");
    	if ( $r != 0) {
        	LOG_ERROR("Copy failed.");
        	$exit_value = -1;
        	$EXIT_STATUS = "FAILURE";
    	}
    	LOG_NOTICE("3. Unzip idmlcm.zip");
    	my $r = system("unzip ${DEST_DIR}idmlcm.zip -d ${DEST_DIR}");
    	if ( $r != 0) {
        	LOG_ERROR("Unzip failed.");
        	$EXIT_STATUS="FAILURE";
        	$exit_value = -1;
    	}
    	LOG_NOTICE("4. Remove idmlcm.zip, leaving only idmlcm dir");
    	my $r = system("rm -f ${DEST_DIR}idmlcm.zip");
    	if ( $r != 0) {
        	LOG_ERROR("Remove idmlcm.zip failed.");
    	}
		return "${DEST_DIR}${DIRSEP}idmlcm${DIRSEP}Disk1";
    }
}

sub get_label_from_pwv {
        my $command = "ade pwv";
        LOG_NOTICE("Getting label from ade pwv. The command is: $command");
        my @res = `$command`;
	my $label = "";
	foreach my $r (@res) {
		chomp $r;
		if($r =~ m/VIEW_LABEL/) {
			my @tmp = split(":", $r, 2);
                    	$label = $tmp[1];
						$label =~ s/^\s+|\s+$//g;
			return $label;
		}
	}
}

sub get_preflight_name_from_shiphome{
	my $shiphome=shift;
    LOG_NOTICE("Shiphome is: $shiphome");
	my $temp_str=substr($shiphome,index($shiphome,'IDM_MAIN_GENERIC'));
	return substr($temp_str,0,index($temp_str,'/'));
}

sub is_idm_label {
	my $label = shift;
	if($label =~ m/IDM_/){
		return 1;
	} else {
		return 0;	
	}
}

sub is_idmlcm_label {
    my $label = shift;
    if($label =~ m/IDMLCM/){
    	return 1;
	} else {
		return 0;	
	}
}

sub operation
{
	LOG_NOTICE("Operation begins.");
	# 1. If USE_MY_REPO is set, use user specified FA_REPO_LOC value as FA_REPO_PATH	
	# 2. Shiphome default values are: %SHIPHOME_AS11_IDM_11.1.2.2.0%, /tmp, or %ADE_VIEW_ROOT%/idm/shiphome/iamsuite*.zip
	#	 If shiphome is not default, then use shiphome as FA_REPO_PATH
	# 3. If REPLACE_IDMLCM_WITH_LOCAL is true, use FA_REPO_LOC(Don't copy to local), and replace IDMLCM_LOC to FA_REPO_LOC
	# 4. Get label.
	#	 If is IDM label, use $FA_REPO_PREFIX.$label.$FA_REPO_POSTFIX as FA_REPO_PATH 
	#	 If is IDMLCM label, get repo from yesterday's IDM_11.1.2.2.0_GENERIC label, and replace idmlcm.zip from IDMLCM label against which this job is running
	#	 If none of the above is met, exit with error, no repo found.
	if ($USE_MY_REPO eq "true"){
		LOG_NOTICE("Use user defined FA_REPO");
		$FA_REPO_PATH=$FA_REPO_LOC;
	} elsif(($SHIPHOME ne "%SHIPHOME_AS11_IDM_11.1.2.2.0%") && ($SHIPHOME ne "/tmp") && ($SHIPHOME ne "\%ADE_VIEW_ROOT\%/idm/shiphome/iamsuite*.zip")) {
		LOG_NOTICE("Param SHIPHOME is not default value. Perhaps the value is changed by preflight or mats run.");
		LOG_NOTICE("Use SHIPHOME as iamsuite*.zip. SHIPHOME value is: $SHIPHOME.");
		my $prefligh_name = get_preflight_name_from_shiphome($SHIPHOME);
		LOG_NOTICE("prefligh_name is : $prefligh_name");
		$FA_REPO_PATH = $PREFLIGHT_REPO_PREFIX.$prefligh_name.$FA_REPO_POSTFIX;	
		LOG_NOTICE("Repo path is: $FA_REPO_PATH");
	} elsif ($REPLACE_IDMLCM_WITH_LOCAL eq "true") {
		LOG_NOTICE("Use user defined FA_REPO, and replace user provided idmlcm.zip");
		$FA_REPO_PATH=$FA_REPO_LOC;			
		$IDMLCM_LOC = unzip_idmlcm($IDMLCM_LOC);
	} else {
		my $label = get_label_from_pwv();
		LOG_NOTICE("Got label from ade pwv: $label");
		if ( is_idm_label($label) ) {
			LOG_NOTICE("Using IDM label. Generate repo from label. Will not replace idmlcm.");
			$FA_REPO_PATH = $FA_REPO_PREFIX.$label.$FA_REPO_POSTFIX;	
		} elsif ( is_idmlcm_label($label) ) {
			LOG_NOTICE("Use FA_REPO from yesterday's label.");
			$FA_REPO_PATH = get_repo_from_yesterdays_label();
			LOG_NOTICE("Need to copy repo to local and replace idmlcm.zip");
			# copy repo to local dir
			copy_repo();
			# and replace idmlcm.zip
			replace_idmlcm();
			$FA_REPO_PATH=$AUTO_WORK."/fa_repo";
		} else {
			LOG_NOTICE("No REPO found. Exit with error.");
			$EXIT_STATUS="FAILURE";
			$exit_value = -1;
			exit $exit_value;
		}
	}
	$DB_PATH=$FA_REPO_PATH.$DB_POSTFIX;
	LOG_NOTICE("FA_REPO_PATH is: $FA_REPO_PATH");
	LOG_NOTICE("DB_SHIPHOME: $DB_PATH");
	LOG_NOTICE("Succees.");
	$EXIT_STATUS="SUCCESS";
} 
