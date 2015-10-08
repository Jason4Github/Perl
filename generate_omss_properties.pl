#!/usr/local/bin/perl

use File::Copy;
use File::Basename;
# Change History
# 	Creation? 2015/05/05 By Jason.
#
#	Jason 2015/05/05 add support for PROV FULL + OID/OUD

# Usage: perl generate_omss_properties.pl  import.txt export.txt runtime.txt
# BEGIN SUPPORTING FILES
## 
# END SUPPORTING FILES 

# use BEGIN block to add DTE.pm into @INC
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

	# add $plibDir into INC
	unshift  (@INC,"$plibDir");

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

######## Initialize Global Variables #################
$prop_file_name = "omssqaenv.properties";

# Import Parameters will be put into hashtable %ImportParamTable
%ImportParamTable = ();
# The import parameters are:
# HOSTNAME
# MW_HOME
# BASE_DIR
# BROWSER_PATH


# Runtime Parameters will be put into hashtable %RuntimeParamTable
%RuntimeParamTable = ();
# The runtime parameters are:
# WORKDIR   - the workdir of the current task(block)
# AUTO_HOME - the AUTO_HOME dir
# AUTO_WORK - the AUTO_WORK dir
# ENVFILE   - the property file which has all the ENV variables dump 
# TASK_ID   - the Task ID for the current task(block) in topology definition 
# JAVA_HOME - the JAVA_HOME from where the DTE runtime java interpretor comes

# Export Parameters should be put into hashtable %ExportParamTable
%ExportParamTable = ();
# The export parameters are:
# HOSTNAME
# EXIT_STATUS
# GENERIC_OMSS_PROP_FILE


# the exit_value for this program
$exit_value = 1;


#################### Program Main Logic ###################

############ Set platform info  #######
set_platform_info();


############ Parse Runtime File runtime.txt  #######
%RuntimeParamTable = DTE::parse_runtime_file($runtimefile);

############ Parse Import File import.txt ##########
## All import parameters are in hashtable %ImportParamTable
%ImportParamTable = DTE::parse_import_file($importfile, %RuntimeParamTable);


############ Set Initial/Default Values for Mandatory Export Params ####
$ExportParamTable{HOSTNAME} = $ImportParamTable{HOSTNAME};
$ExportParamTable{EXIT_STATUS} = "FAILURE";
$ExportParamTable{GENERIC_OMSS_PROP_FILE} = "";


############### Here is the Operation of the block #########
# To do what the block is supposed to do and generate values for export parameters
operation();


############### Set EXIT_STATUS based on exit_value ##############
if ($exit_value == 0)
{
	$ExportParamTable{EXIT_STATUS} = "SUCCESS";
}


############### Populate Export file with export param info ##############
DTE::populate_export_file($exportfile, %ExportParamTable);


# End the Main Logic here
exit $exit_value;


################# Program Subroutines For Block Logic ################
sub operation
{
	# Validate import params
	if (!validate_import_params())
	{
		print "\nERROR: Error occurred while validating import params!!!\n";
		return;
	}
		
	create_omss_property_file();
	
	if (! -e "$ExportParamTable{GENERIC_OMSS_PROP_FILE}")
	{
		print "\nERROR: OMSS property file path after adding /net '$ExportParamTable{GENERIC_OMSS_PROP_FILE}' is not accessible!!!\n";
		return;
	}
	
	$exit_value = 0;
}




sub validate_import_params
{
	# If there are any import params that have default value (%IMPORT_PARAM%), 
	# set those import params' values to empty string
	set_default_valued_import_params_to_empty_string();
	
	if ($ImportParamTable{MW_HOME} eq '')
	{
		print "\nERROR: MW_HOME import param is mandatory!!!\n";
		return 0;
	}
	elsif (! -e $ImportParamTable{MW_HOME})
	{
		print "\nERROR: MW_HOME '$ImportParamTable{MW_HOME}' doesn't exist!!!\n";
		return 0;
	}
	
	if ($ImportParamTable{BASE_DIR} eq '')
	{
		print "\nERROR: BASE_DIR import param is mandatory!!!\n";
		return 0;
	}
	elsif (! -e $ImportParamTable{BASE_DIR})
	{
		print "\nERROR: BASE_DIR '$ImportParamTable{BASE_DIR}' doesn't exist!!!\n";
		return 0;
	}
	
	if ($ImportParamTable{BROWSER_PATH} eq '')
	{
		print "\nERROR: BROWSER_PATH import param is mandatory!!!\n";
		return 0;
	}
	elsif (! -e $ImportParamTable{BROWSER_PATH})
	{
		print "\nERROR: BROWSER_PATH '$ImportParamTable{BROWSER_PATH}' doesn't exist!!!\n";
		return 0;
	}
	
	if ($ImportParamTable{HOSTNAME} eq '')
	{
		print "\nERROR: HOSTNAME import param is mandatory!!!\n";
		return 0;
	}
	

#####################################################################
# TODO: Need to add checks for the remaining import params
#####################################################################
	
	
	return 1;
}




sub set_default_valued_import_params_to_empty_string
{
	foreach $key (keys %ImportParamTable)
	{
		$pattern = qr"$key";
		
		if ($ImportParamTable{$key} =~ /^%$pattern%$/i)
		{
			$ImportParamTable{$key} = '';
		}
	}
}



#create $prop_file_name in $T_WORK
sub create_omss_property_file
{
	print "\nprepare omss properties...\n";
	
	print "\nEnv variables set:\n";
	print "AUTO_HOME = $RuntimeParamTable{AUTO_HOME}\n";
	print "AUTO_WORK = $RuntimeParamTable{AUTO_WORK}\n";
	print "WORKDIR = $RuntimeParamTable{WORKDIR}\n";
	print "T_WORK = $RuntimeParamTable{T_WORK}\n";
	
	$omss_property_file = "$RuntimeParamTable{T_WORK}/$prop_file_name";

	
	($hostname_without_domain = $ImportParamTable{HOSTNAME}) =~ s#^([^\.]+).*#$1#;	
	$ExportParamTable{GENERIC_OMSS_PROP_FILE} = "/net/${hostname_without_domain}/${omss_property_file}";
	
	
	if (!open(PROP_FILE, ">$omss_property_file"))
	{
		print "\nERROR: Couldn't open file '$omss_property_file' for writing!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	print PROP_FILE "ORACLE_COMMON_HOME=$ImportParamTable{BASE_DIR}/IDMTOP/products/access/oracle_common\n";
	print PROP_FILE "WL_HOME=$ImportParamTable{BASE_DIR}/IDMTOP/products/access/wlserver_10.3\n";
	print PROP_FILE "APPLICATION_TYPE=oam\n";
	print PROP_FILE "HOSTNAME=$ImportParamTable{HOSTNAME}\n";
	print PROP_FILE "APPLICATION_PROTOCOL=http\n";
	print PROP_FILE "APPLICATION_HOST=$ImportParamTable{HOSTNAME}\n";
	print PROP_FILE "APPLICATION_PORT=7001\n";
	print PROP_FILE "POLICY_MANAGER_PORT=14150\n";
	print PROP_FILE "OIM_PORT=14000\n";
	print PROP_FILE "MSM_PORT=14180\n";
	print PROP_FILE "BROWSER=firefox\n";
	print PROP_FILE "BROWSER_PATH=$ImportParamTable{BROWSER_PATH}\n";
	print PROP_FILE "ROLE_ADMIN=Administrators\n";
	print PROP_FILE "ROLE_HELPDESK=MSMHelpDeskUsers\n";
	print PROP_FILE "ROLE_ENDUSER=WorkspaceUsers\n";
	print PROP_FILE "ROLE1=MSMSysAdminUsers\n";
	print PROP_FILE "ROLE2=MSMHelpDeskUsers\n";
	print PROP_FILE "END_USER1=msmtestuser1\n";
	print PROP_FILE "END_USER1_PASSWORD=Fusionapps1\n";
	print PROP_FILE "ADMIN_USER=msmadmin\n";
	print PROP_FILE "ADMIN_USER_PASSWORD=Fusionapps1\n";
	print PROP_FILE "HELPDESK_ADMIN_USER=msmhelpdesk\n";
	print PROP_FILE "HELPDESK_ADMIN_PASSWORD=Fusionapps1\n";
	print PROP_FILE "TEST_RESULT_DIR=$RuntimeParamTable{T_WORK}/testout\n";
	print PROP_FILE "TEST_OUT=$RuntimeParamTable{T_WORK}/testout\n";
	print PROP_FILE "T_WORK=$RuntimeParamTable{T_WORK}\n";
	print PROP_FILE "TESTTOOL_DIR=$RuntimeParamTable{T_WORK}/../../testtool\n";
	print PROP_FILE "oracle.omsm.rest.truststore=$RuntimeParamTable{T_WORK}/../../omsstest/common/wlstrust.jks\n";
	print PROP_FILE "MSM_TRUSTSTORE=$ImportParamTable{BASE_DIR}/IDMTOP/config/domains/IAMAccessDomain/config/fmwconfig/wlstrust.jks\n";
	print PROP_FILE "MSM_TRUSTSTORE_PASSWORD=Fusionapps123\n";
	print PROP_FILE "BUILDOUT=$RuntimeParamTable{T_WORK}/buildout\n";
	print PROP_FILE "IDM_ORACLE_HOME=$ImportParamTable{BASE_DIR}/IDMTOP/products/access/iam\n";
	
	close(PROP_FILE);

	return 1;
}


sub set_platform_info
{
	$PLATFORM = DTE::getOS();

	print "\nPLATFORM: $PLATFORM\n";
	
	if ( $PLATFORM eq "nt" )
	{
		$DIRSEP = "\\";
		$PATHSEP =";";
		$PLATFORM_JAVA_HOME = "C:\\jdk160";
	}
	else
	{
		$DIRSEP = "/" ;
		$PATHSEP = ":";
		$PLATFORM_JAVA_HOME = "/usr/local/packages/jdk_remote/jdk1.6.0_13";
		$PLATFORM_ANT_HOME = "/usr/local/packages/ant_remote/1.7.1";
	}
}

