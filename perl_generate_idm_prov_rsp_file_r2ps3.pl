#!/usr/local/bin/perl

use File::Copy;
use File::Basename;
# Change History
# 	Creation? Date forgot. By Lancer.
#
# 	Lancer 2014/03/27 add copy screenshots to AUTO_WORK. sub copy_screenshot_files_to_autowork().
#	Lancer 2014/04/17 change screenshots to WORKDIR/../
#	Lancer 2014/09/11 add support for oam only with existing OID
#	Lancer 2014/10/14 add support for oam only with existing OUD
#	Amy    2014/10/16 add support for OIMXE-OID and OIMXE-OUD
#	Lancer 2014/10/21 add support for OIM XE+Existing OID/OUD
#	Lancer 2014/10/21 add support for OAM+OIM+Existing OID/OUD

# Usage: perl generate_idm_prov_rsp_file.pl  import.txt export.txt runtime.txt
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

# Import Parameters will be put into hashtable %ImportParamTable
%ImportParamTable = ();
# The import parameters are:
# HOSTNAME
# GEN_RSP_INPUT_XML
# RSP_FILE
# GENERATE_RSP_FILE
# TOPO_CONFIGURATION
# FA_REPO
# BASEDIR
# IDM_PROV_AUTOMATION_SOURCE
# OID_HOSTNAME
# OIM_HOSTNAME
# OHS_HOSTNAME
# OID_IDSTORE_DB_HOSTNAME
# OID_PSTORE_DB_HOSTNAME
# OIM_DB_HOSTNAME
# OAM_DB_HOSTNAME
# OID_IDSTORE_RAC_DB1_HOSTNAME
# OID_IDSTORE_RAC_DB2_HOSTNAME
# OID_PSTORE_RAC_DB1_HOSTNAME
# OID_PSTORE_RAC_DB2_HOSTNAME
# OIM_RAC_DB1_HOSTNAME
# OIM_RAC_DB2_HOSTNAME
# OAM_RAC_DB1_HOSTNAME
# OAM_RAC_DB2_HOSTNAME
# ADMIN_LBR_HOSTNAME
# ADMIN_LBR_PORT
# OIM_LBR_HOSTNAME
# OIM_LBR_PORT
# OAM_LBR_HOSTNAME
# OAM_LBR_PORT
# OID_IDSTORE_LBR_HOSTNAME
# OID_IDSTORE_LBR_PORT
# OID_IDSTORE_LBR_SSL_PORT
# OID_PSTORE_LBR_HOSTNAME
# OID_PSTORE_LBR_PORT
# OID_PSTORE_LBR_SSL_PORT
# OVD_LBR_HOSTNAME
# OVD_LBR_PORT
# OVD_LBR_SSL_PORT
# JAVA_HOME
# ANT_HOME

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
# GENERIC_RSP_FILE
# RSP_FILE

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
$ExportParamTable{GENERIC_RSP_FILE} = "";
$ExportParamTable{RSP_FILE} = "";


############### Here is the Operation of the block #########
# To do what the block is supposed to do and generate values for export parameters
operation();


############### Stop vnc if it is not stopped ##############
if ($vnc_stopped ne '')
{
	stop_vnc();
}


############### Set EXIT_STATUS based on exit_value ##############
if ($exit_value == 0)
{
	$ExportParamTable{EXIT_STATUS} = "SUCCESS";
}


############### Populate Export file with export param info ##############
DTE::populate_export_file($exportfile, %ExportParamTable);

copy_screenshot_files_to_autowork();

# End the Main Logic here
exit $exit_value;


sub copy_screenshot_files_to_autowork {
	system("mkdir -p $RuntimeParamTable{AUTO_WORK}${DIRSEP}screenshots");
	system("cp -r $RuntimeParamTable{WORKDIR}${DIRSEP}testng-report${DIRSEP}IdMProvWizGRF${DIRSEP}screenshots${DIRSEP}* $RuntimeParamTable{WORKDIR}${DIRSEP}..${DIRSEP}");
}

################# Program Subroutines For Block Logic ################
sub operation
{
	# Validate import params
	if (!validate_import_params())
	{
		print "\nERROR: Error occurred while validating import params!!!\n";
		return;
	}
	
	
	# If rsp file is not to be generated, invoke the appropriate DTE perl script for picking the rsp file and updating it
	if ($ImportParamTable{GENERATE_RSP_FILE} eq 'false')
	{
		if (!get_generic_rsp_file_using_repo_and_update())
		{
			print "\nERROR: Failed to get generic rsp file and update it!!!\n";
			return;
		}
	}
	else
	{
		if (!generate_rsp_file())
		{
			print "\nERROR: Failed to generate rsp file!!!\n";
			return;
		}
	}
	
	
	# Get absolute path of rsp file and add /net if needed
	print "\nRSP file: '$ExportParamTable{RSP_FILE}'\n";
	
	($rsp_file_dir = $ExportParamTable{RSP_FILE}) =~ s#(.*)/.*#$1#;
	($rsp_file_name = $ExportParamTable{RSP_FILE}) =~ s#.*/(.*)#$1#;
	
	if (!chdir("$rsp_file_dir"))
	{
		print "\nERROR: Couldn't cd to rsp file dir '$rsp_file_dir'!!!\n";
		print "\nError is:\n$!\n";
		return;
	}
	
	$current_dir = getcwd();
	
	if ($current_dir =~ /\/scratch\// and $current_dir !~ /^\/net/)
	{
		($hostname_without_domain = $ImportParamTable{HOSTNAME}) =~ s#^([^\.]+).*#$1#;
		
		$current_dir = "/net/${hostname_without_domain}/${current_dir}";
	}
	
	$ExportParamTable{RSP_FILE} = "${current_dir}/${rsp_file_name}";
	
	print "\nRSP file after adding /net: '$ExportParamTable{RSP_FILE}'\n";
	
	if (! -e "$ExportParamTable{RSP_FILE}")
	{
		print "\nERROR: RSP file path after adding /net '$ExportParamTable{RSP_FILE}' is not accessible!!!\n";
		return;
	}
	
	
	# Get absolute path of generic rsp file and add /net if needed
	print "\nGeneric RSP file: '$ExportParamTable{GENERIC_RSP_FILE}'\n";
	
	($generic_rsp_file_dir = $ExportParamTable{GENERIC_RSP_FILE}) =~ s#(.*)/.*#$1#;
	($generic_rsp_file_name = $ExportParamTable{GENERIC_RSP_FILE}) =~ s#.*/(.*)#$1#;
	
	if (!chdir("$generic_rsp_file_dir"))
	{
		print "\nERROR: Couldn't cd to generic rsp file dir '$generic_rsp_file_dir'!!!\n";
		print "\nError is:\n$!\n";
		return;
	}
	
	$current_dir = getcwd();
	
	if ($current_dir =~ /\/scratch\// and $current_dir !~ /^\/net/)
	{
		($hostname_without_domain = $ImportParamTable{HOSTNAME}) =~ s#^([^\.]+).*#$1#;
		
		$current_dir = "/net/${hostname_without_domain}/${current_dir}";
	}
	
	$ExportParamTable{GENERIC_RSP_FILE} = "${current_dir}/${generic_rsp_file_name}";
	
	print "\nGeneric RSP file after adding /net: '$ExportParamTable{GENERIC_RSP_FILE}'\n";
	
	if (! -e "$ExportParamTable{GENERIC_RSP_FILE}")
	{
		print "\nERROR: Generic RSP file path after adding /net '$ExportParamTable{GENERIC_RSP_FILE}' is not accessible!!!\n";
		return;
	}
	
	$exit_value = 0;
}




sub validate_import_params
{
	# If there are any import params that have default value (%IMPORT_PARAM%), 
	# set those import params' values to empty string
	set_default_valued_import_params_to_empty_string();
	
	
	if ($ImportParamTable{RSP_FILE} ne '' and ! -e "$ImportParamTable{RSP_FILE}")
	{
		print "\nERROR: Couldn't find rsp file passed as RSP_FILE: '$ImportParamTable{RSP_FILE}'!!!\n";
		return 0;
	}
	
	if ($ImportParamTable{GEN_RSP_INPUT_XML} ne '' and ! -e "$ImportParamTable{GEN_RSP_INPUT_XML}")
	{
		print "\nERROR: Input xml '$ImportParamTable{GEN_RSP_INPUT_XML}' doesn't exist!!!\n";
		return 0;
	}
	
	if ($ImportParamTable{GENERATE_RSP_FILE} eq '')
	{
		print "\nGENERATE_RSP_FILE import param is not set. Using default value as 'true'...\n";
		$ImportParamTable{GENERATE_RSP_FILE} = 'true';
	}
	
	$ImportParamTable{GENERATE_RSP_FILE} = lc($ImportParamTable{GENERATE_RSP_FILE});
	
	if (!($ImportParamTable{GENERATE_RSP_FILE} eq 'true' or $ImportParamTable{GENERATE_RSP_FILE} eq 'false'))
	{
		print "\n'$ImportParamTable{GENERATE_RSP_FILE}': Invalid value for GENERATE_RSP_FILE import param. Valid values are 'true' and 'false'. Overriding this with default value as 'true'...\n";
		$ImportParamTable{GENERATE_RSP_FILE} = 'true';
	}
	
	# Make sure that if RSP_FILE is set, it will override any value of GENERATE_RSP_FILE
	if ($ImportParamTable{RSP_FILE} ne '')
	{
		print "\nRSP_FILE is set. Overriding the value of GENERATE_RSP_FILE to 'false'.\n";
		$ImportParamTable{GENERATE_RSP_FILE} = 'false';
	}
	
	if ($ImportParamTable{TOPO_CONFIGURATION} eq '')
	{
		# Only do this if GENERATE_RSP_FILE=true
		if ($ImportParamTable{GENERATE_RSP_FILE} eq 'true')
		{
			print "\nTOPO_CONFIGURATION import param is not set. Using default value as '1node' ...\n";
			$ImportParamTable{TOPO_CONFIGURATION} = '1node';
		}
	}
	
	$ImportParamTable{TOPO_CONFIGURATION} = lc($ImportParamTable{TOPO_CONFIGURATION});
	
	if (!($ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_component' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_component_oid' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_component_oid_rcu' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oim' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_oid'or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_existing_oid' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_existing_oud' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_existing_oud' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_existing_oid' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oid' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oud' or $ImportParamTable{TOPO_CONFIGURATION} eq '3node' or $ImportParamTable{TOPO_CONFIGURATION} eq '3nodeovmracdb' or $ImportParamTable{TOPO_CONFIGURATION} eq '4node' or $ImportParamTable{TOPO_CONFIGURATION} eq '4nodeovmracdb' or $ImportParamTable{TOPO_CONFIGURATION} eq 'simv2' or $ImportParamTable{TOPO_CONFIGURATION} eq 'edg'or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_oid' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_oud')) 
	{
		# Only do this if GENERATE_RSP_FILE=true
		if ($ImportParamTable{GENERATE_RSP_FILE} eq 'true')
		{
			print "\n'$ImportParamTable{TOPO_CONFIGURATION}': Invalid value for TOPO_CONFIGURATION import param. Overriding this with default value as '1node' ...\n";
			$ImportParamTable{TOPO_CONFIGURATION} = '1node';
		}
	}
	
	if ($ImportParamTable{FA_REPO} eq '')
	{
		print "\nERROR: FA_REPO import param is mandatory!!!\n";
		return 0;
	}
	elsif (! -e $ImportParamTable{FA_REPO})
	{
		print "\nERROR: FA repo '$ImportParamTable{FA_REPO}' doesn't exist!!!\n";
		return 0;
	}
	
	if ($ImportParamTable{BASEDIR} eq '')
	{
		print "\nERROR: BASEDIR import param is mandatory!!!\n";
		return 0;
	}
	elsif (! -e $ImportParamTable{BASEDIR})
	{
		print "\nERROR: BASEDIR '$ImportParamTable{BASEDIR}' doesn't exist!!!\n";
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




sub get_generic_rsp_file_using_repo_and_update
{
	print "\nRSP file won't be generated. Attempting to get the generic rsp file from IDMLCM label in order to update it...\n";
	
	# If topo configuration is not 1node or 3node and rsp file is not passed, then there is no way of figuring out the rsp file location
	if (!($ImportParamTable{TOPO_CONFIGURATION} eq '1node' or $ImportParamTable{TOPO_CONFIGURATION} eq '3node' or $ImportParamTable{TOPO_CONFIGURATION} eq '3nodeovmracdb') and ($ImportParamTable{RSP_FILE} eq ''))
	{
		print "\nERROR: This block doesn't handle getting generic rsp file for any topo configuration other than 1node, 3node and 3nodeovmracdb!!!\n";
		return 0;
	}
	
	
	# Create import.txt, runtime.txt and export.txt for the perl script corresponding to the given topo configuration
	if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node' or $ImportParamTable{TOPO_CONFIGURATION} eq 'simv2' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oid' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oud')
	{
		$import_file_contents = "HOSTNAME=$ImportParamTable{HOSTNAME}\n";
		$import_file_contents .= "RSP_FILE=$ImportParamTable{RSP_FILE}\n";
		$import_file_contents .= "FA_REPO=$ImportParamTable{FA_REPO}\n";
		$import_file_contents .= "MW_HOME=$RuntimeParamTable{AUTO_WORK}/IDM\n";
		
		$runtime_file_contents = "AUTO_HOME=$RuntimeParamTable{AUTO_HOME}\n";
		$runtime_file_contents .= "AUTO_WORK=$RuntimeParamTable{AUTO_WORK}\n";
		$runtime_file_contents .= "WORKDIR=$RuntimeParamTable{WORKDIR}\n";
		
		$perl_script = "${scriptDir}/create_rsp_from_generic_rsp_idmlcm_1node.pl"
	}
	elsif ($ImportParamTable{TOPO_CONFIGURATION} eq '3node' or $ImportParamTable{TOPO_CONFIGURATION} eq '3nodeovmracdb')
	{
		$import_file_contents = "HOSTNAME=$ImportParamTable{HOSTNAME}\n";
		$import_file_contents .= "RSP_FILE=$ImportParamTable{RSP_FILE}\n";
		$import_file_contents .= "ADMIN_LBR_LOGICAL_HOSTNAME=$ImportParamTable{ADMIN_LBR_HOSTNAME}\n";
		$import_file_contents .= "ADMIN_LBR_LOGICAL_PORT=$ImportParamTable{ADMIN_LBR_PORT}\n";
		$import_file_contents .= "DB1_OID_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OID_IDSTORE_DB_HOSTNAME}\n";
		$import_file_contents .= "DB1_OIM_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OIM_DB_HOSTNAME}\n";
		$import_file_contents .= "FA_REPO=$ImportParamTable{FA_REPO}\n";
		$import_file_contents .= "INVENTORY_LOC=$RuntimeParamTable{WORKDIR}/../INSTALL_DBMS/oraInventory\n";
		$import_file_contents .= "OAM_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OAM_LBR_HOSTNAME}\n";
		$import_file_contents .= "OAM_LBR_LOGICAL_PORT=$ImportParamTable{OAM_LBR_PORT}\n";
		$import_file_contents .= "OHS_HOST=$ImportParamTable{OHS_HOSTNAME}\n";
		$import_file_contents .= "OID_HOST=$ImportParamTable{OID_HOSTNAME}\n";
		$import_file_contents .= "OID_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OID_IDSTORE_LBR_HOSTNAME}\n";
		$import_file_contents .= "OID_LBR_LOGICAL_PORT=$ImportParamTable{OID_IDSTORE_LBR_PORT}\n";
		$import_file_contents .= "OIM_HOST=$ImportParamTable{OIM_HOSTNAME}\n";
		$import_file_contents .= "OIM_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OIM_LBR_HOSTNAME}\n";
		$import_file_contents .= "OIM_LBR_LOGICAL_PORT=$ImportParamTable{OIM_LBR_PORT}\n";
		$import_file_contents .= "REPOSITORY_DIR=$ImportParamTable{BASEDIR}/repository\n";
		
		$runtime_file_contents = "AUTO_HOME=$RuntimeParamTable{AUTO_HOME}\n";
		$runtime_file_contents .= "AUTO_WORK=$RuntimeParamTable{AUTO_WORK}\n";
		$runtime_file_contents .= "WORKDIR=$RuntimeParamTable{WORKDIR}\n";
		
		$perl_script = "${scriptDir}/create_rsp_from_generic_rsp_3nodedmz_ovm_fa_repo.pl"
	}
	elsif ($ImportParamTable{TOPO_CONFIGURATION} eq 'edg')
	{
		$import_file_contents = "HOSTNAME=$ImportParamTable{HOSTNAME}\n";
		$import_file_contents .= "ADMIN_LBR_LOGICAL_PORT=$ImportParamTable{ADMIN_LBR_PORT}\n";
		$import_file_contents .= "OAM_LBR_LOGICAL_PORT=$ImportParamTable{OAM_LBR_PORT}\n";
		$import_file_contents .= "OID_LBR_LOGICAL_PORT=$ImportParamTable{OID_IDSTORE_LBR_PORT}\n";
		$import_file_contents .= "OIM_LBR_LOGICAL_PORT=$ImportParamTable{OIM_LBR_PORT}\n";
		$import_file_contents .= "RSP_FILE=$ImportParamTable{RSP_FILE}\n";
		$import_file_contents .= "ADMIN_LBR_LOGICAL_HOSTNAME=$ImportParamTable{ADMIN_LBR_HOSTNAME}\n";
		$import_file_contents .= "FA_REPO=$ImportParamTable{FA_REPO}\n";
		$import_file_contents .= "IDM_DB_LOGICAL_HOSTNAME=$ImportParamTable{OAM_DB_HOSTNAME}\n";
		$import_file_contents .= "IDM_DB_LOGICAL_PORT=1521\n";
		$import_file_contents .= "OAM_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OAM_LBR_HOSTNAME}\n";
		$import_file_contents .= "OHS_LOGICAL_HOSTNAME=$ImportParamTable{OHS_HOSTNAME}\n";
		$import_file_contents .= "OID_ID_STORE_DB_LOGICAL_HOSTNAME=$ImportParamTable{OID_IDSTORE_DB_HOSTNAME}\n";
		$import_file_contents .= "OID_ID_STORE_DB_LOGICAL_PORT=1522\n";
		$import_file_contents .= "OID_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OID_IDSTORE_LBR_HOSTNAME}\n";
		$import_file_contents .= "OID_LOGICAL_HOSTNAME=$ImportParamTable{OID_HOSTNAME}\n";
		$import_file_contents .= "OID_POLICY_STORE_DB_LOGICAL_HOSTNAME=$ImportParamTable{OID_PSTORE_DB_HOSTNAME}\n";
		$import_file_contents .= "OID_POLICY_STORE_DB_LOGICAL_PORT=1522\n";
		$import_file_contents .= "OIM_DB_LOGICAL_HOSTNAME=$ImportParamTable{OIM_DB_HOSTNAME}\n";
		$import_file_contents .= "OIM_DB_LOGICAL_PORT=1521\n";
		$import_file_contents .= "OIM_LBR_LOGICAL_HOSTNAME=$ImportParamTable{OIM_LBR_HOSTNAME}\n";
		$import_file_contents .= "OIM_LOGICAL_HOSTNAME=$ImportParamTable{OIM_HOSTNAME}\n";
		$import_file_contents .= "REPOSITORY_DIR=$ImportParamTable{BASEDIR}/repository\n";
		
		$runtime_file_contents = "AUTO_HOME=$RuntimeParamTable{AUTO_HOME}\n";
		$runtime_file_contents .= "AUTO_WORK=$RuntimeParamTable{AUTO_WORK}\n";
		$runtime_file_contents .= "WORKDIR=$RuntimeParamTable{WORKDIR}\n";
		
		$perl_script = "${scriptDir}/create_rsp_from_generic_rsp_3nodedmz_ovm_fa_repo_edg.pl"
	}
	
	$import_file = "$RuntimeParamTable{WORKDIR}/$ImportParamTable{TOPO_CONFIGURATION}_import.txt";
	$runtime_file = "$RuntimeParamTable{WORKDIR}/$ImportParamTable{TOPO_CONFIGURATION}_runtime.txt";
	$export_file = "$RuntimeParamTable{WORKDIR}/$ImportParamTable{TOPO_CONFIGURATION}_export.txt";
	
	if (!open(IMPORT_FILE, ">$import_file"))
	{
		print "\nERROR: Couldn't open file '$import_file' for writing!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	if (!open(RUNTIME_FILE, ">$runtime_file"))
	{
		print "\nERROR: Couldn't open file '$runtime_file' for writing!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	if (!open(EXPORT_FILE, ">$export_file"))
	{
		print "\nERROR: Couldn't open file '$export_file' for writing!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	print IMPORT_FILE "$import_file_contents";
	close(IMPORT_FILE);
	
	print RUNTIME_FILE "$runtime_file_contents";
	close(RUNTIME_FILE);
	
	# Nothing to be written to export file. Just an empty file has to be created.
	close(EXPORT_FILE);
	
	
	
	# Open runBlock.cmd to get the path of perl script
	$runBlock_cmd_file = "$RuntimeParamTable{WORKDIR}${DIRSEP}runBlock.cmd";
	
	if (!open(RUNBLOCK_CMD_FILE, "$runBlock_cmd_file"))
	{
			print "\nERROR: Couldn't open file '$runBlock_cmd_file' for reading!!!\n";
			print "\nError is:\n$!\n";
			return 0;
	}
	
	$line = <RUNBLOCK_CMD_FILE>;
	
	close (RUNBLOCK_CMD_FILE);
	
	chomp ($line);
	
	($perl_executable = $line) =~ s#\s*([^\s]+).*#$1#;
	
	print "\nPerl executable obtained from runBlock.cmd: '$perl_executable'\n";
	
	if (! -x "$perl_executable")
	{
		print "\nERROR: Perl executable '$perl_executable' either doesn't exist, or is not executable!!!\n";
		return 0;
	}	
	
	
	
	# Invoke the perl script corresponding to the given topo configuration
	print "\nInvoking the DTE perl script corresponding to the given topo configuration: '$ImportParamTable{TOPO_CONFIGURATION}'...\n";
	
	$log = "$RuntimeParamTable{WORKDIR}/get_generic_rsp_file_using_repo_and_update.log";
	
	$cmd = "$perl_executable $perl_script $import_file $export_file $runtime_file >& $log";
	
	print "\nExecuting $cmd ...\n";
	
	$perl_exit_code = system("bash -c '$cmd'");
	
	if ($perl_exit_code != 0)
	{
		print "\nERROR: Above command failed. Please check the log file '$log'.\n";
		return 0;
	}
	
	print "\nAbove command succeeded. Attempting to get the updated rsp file created using above perl script...\n";
	
	if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node' or $ImportParamTable{TOPO_CONFIGURATION} eq 'simv2' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oid' or $ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oud')
	{
		$rsp_file_export_param = 'RSP_UPDATED_FILE';
	}
	elsif ($ImportParamTable{TOPO_CONFIGURATION} eq '3node' or $ImportParamTable{TOPO_CONFIGURATION} eq '3nodeovmracdb' or $ImportParamTable{TOPO_CONFIGURATION} eq 'edg')
	{
		$rsp_file_export_param = 'RSP_FILE';
	}
	
	
	if (!open(EXPORT_FILE, $export_file))
	{
		print "\nERROR: Couldn't open export file '$export_file' for reading!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	for (<EXPORT_FILE>)
	{
		chomp($_);
		
		if ($_ =~ /^${rsp_file_export_param}=/)
		{
			($updated_rsp_file = $_) =~ s#${rsp_file_export_param}=##;
		}
		elsif ($_ =~ /^GENERIC_RSP_FILE=/)
		{
			($generic_rsp_file_used = $_) =~ s#GENERIC_RSP_FILE=##;
		}
	}
	
	if ($updated_rsp_file eq '')
	{
		print "\nCouldn't find updated rsp file from export file '$export_file'!!!\n";
		return 0;
	}
	elsif ($generic_rsp_file_used eq '')
	{
		print "\nCouldn't find generic rsp file used from export file '$export_file'!!!\n";
		return 0;
	}
	
	if (! -e "$updated_rsp_file")
	{
		print "\nERROR: Updated rsp file '$updated_rsp_file' doesn't exist!!!\n";
		return 0;
	}
	elsif (! -e "$generic_rsp_file_used")
	{
		print "\nERROR: Generic rsp file '$generic_rsp_file_used' doesn't exist!!!\n";
		return 0;
	}
	
	
	$ExportParamTable{GENERIC_RSP_FILE} = "$generic_rsp_file_used";
	$ExportParamTable{RSP_FILE} = "$updated_rsp_file";
	
	
	print "\nUpdated file obtained as a result of the above command is: '$ExportParamTable{RSP_FILE}'\n";
	print "\nGeneric rsp file obtained as a result of the above command is: '$ExportParamTable{GENERIC_RSP_FILE}'\n";
	
	
	return 1;
}



sub generate_rsp_file
{
	# Start VNC
	if (!start_vnc_and_set_display())
	{
		print "\nStarting VNC failed!!!\n";
		return 0;
	}
	
	
	# Update placeholders in input xml file
	if (!update_input_xml())
	{
		print "\nERROR: Updating input XML failed!!!\n";
		return 0;
	}
	
		
	# Create an invPtrLoc file
	$INV_PTR_LOC_FILE = "$RuntimeParamTable{WORKDIR}/oraInst.loc";
	
	if (!open(INV_PTR_LOC_FILE, ">$INV_PTR_LOC_FILE"))
	{
		print "ERROR: Couldn't create invPtrLoc file '$INV_PTR_LOC_FILE'!!!\n";
		print "Error is:\n$!\n";
		return 0;
	}
	else
	{
		print INV_PTR_LOC_FILE "inventory_loc=$RuntimeParamTable{WORKDIR}/inv_loc\n";

		close(INV_PTR_LOC_FILE);
	}
	
	
	# Set env variables
	$ENV{PROVBUILDFOLDER} = "idm-provisioning-build";
	$ENV{PROVISIONING_FLOW_CUSTOMIZER} = "oracle.idm.provisioning.custom.IDMFlowDesignerCustomizer";
	$ENV{PROVISIONING_TOOLS_CUSTOMIZER} = "oracle.idm.provisioning.custom.IDMToolsCustomizer";
	$ENV{SCRIPTDIR} = "$ImportParamTable{BASEDIR}/idmlcm/provisioning/bin";
	$ENV{PLATFORM} = "$PLATFORM";
	$ENV{INPUT} = "$UPDATED_INPUT_XML";
	$ENV{IdMProvWizardLoc} = "$ENV{SCRIPTDIR}";
	$ENV{invPtrFileLoc} = "$INV_PTR_LOC_FILE";
	$ENV{AUTO_HOME} = "$RuntimeParamTable{AUTO_HOME}";
	$ENV{AUTO_WORK} = "$RuntimeParamTable{AUTO_WORK}";
	$ENV{WORKDIR} = "$RuntimeParamTable{WORKDIR}";
	$ENV{T_WORK} = "$RuntimeParamTable{WORKDIR}";
	$ENV{oraInstLocFile} = "$INV_PTR_LOC_FILE";
	
	print "\nEnv variables set:\n";
	print "PROVBUILDFOLDER = $ENV{PROVBUILDFOLDER}\n";
	print "PROVISIONING_FLOW_CUSTOMIZER = $ENV{PROVISIONING_FLOW_CUSTOMIZER}\n";
	print "PROVISIONING_TOOLS_CUSTOMIZER = $ENV{PROVISIONING_TOOLS_CUSTOMIZER}\n";
	print "SCRIPTDIR = $ENV{SCRIPTDIR}\n";
	print "PLATFORM = $ENV{PLATFORM}\n";
	print "INPUT = $ENV{INPUT}\n";
	print "IdMProvWizardLoc = $ENV{IdMProvWizardLoc}\n";
	print "invPtrFileLoc = $ENV{invPtrFileLoc}\n";
	print "AUTO_HOME = $ENV{AUTO_HOME}\n";
	print "AUTO_WORK = $ENV{AUTO_WORK}\n";
	print "WORKDIR = $ENV{WORKDIR}\n";
	print "T_WORK = $ENV{T_WORK}\n";
	print "oraInstLocFile = ${INV_PTR_LOC_FILE}\n";
	
	if ($ImportParamTable{TOPO_CONFIGURATION} eq '3node' or $ImportParamTable{TOPO_CONFIGURATION} eq '3nodeovmracdb' or $ImportParamTable{TOPO_CONFIGURATION} eq '4node' or $ImportParamTable{TOPO_CONFIGURATION} eq '4nodeovmracdb')
	{
		$ENV{SAAS} = 'true';
	}
	else
	{
		$ENV{SAAS} = 'false';
	}
	
	print "SAAS = $ENV{SAAS}\n";
	
	if ($ImportParamTable{TOPO_CONFIGURATION} eq 'simv2' or $ImportParamTable{TOPO_CONFIGURATION} eq 'edg')
	{
		$ENV{MULTITENANT} = 'true';
	}
	else
	{
		$ENV{MULTITENANT} = 'false';
	}
	
	print "MULTITENANT = $ENV{MULTITENANT}\n";
	
	if (!get_idm_prov_wizard_automation_files_loc_from_label())
	{
		print "\nERROR: Failed to get IDM Prov Wizard Automation files from label!!!\n";
		return 0;
	}
	
	$ENV{TEST_ARTIFACT_SOURCE} = $TEST_ARTIFACT_SOURCE;
	
	print "TEST_ARTIFACT_SOURCE = $ENV{TEST_ARTIFACT_SOURCE}\n";
	
	if ($ImportParamTable{JAVA_HOME} ne '')
	{
		$ENV{JAVA_HOME} = "$ImportParamTable{JAVA_HOME}";
	}
	else
	{
		$ENV{JAVA_HOME} = "$PLATFORM_JAVA_HOME";
	}
	
	print "JAVA_HOME = $ENV{JAVA_HOME}\n";
	
	if ($ImportParamTable{ANT_HOME} ne '')
	{
		$ENV{ANT_HOME} = "$ImportParamTable{ANT_HOME}";
	}
	elsif ($PLATFORM_ANT_HOME ne '')
	{
		$ENV{ANT_HOME} = "$PLATFORM_ANT_HOME";
	}
	else
	{
		print "\nERROR: ANT_HOME is not passed as import param and there is no default ANT_HOME for this platform!!!\n";
		return 0;
	}
	
	print "ANT_HOME = $ENV{ANT_HOME}\n";
	
	
	# Get the target rsp file and summary file from the input xml
	if (!open(UPDATED_INPUT_XML, "$UPDATED_INPUT_XML"))
	{
		print "\nERROR: Couldn't open updated input xml '$UPDATED_INPUT_XML' for reading!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	$updated_input_xml_contents = do {local $/; <UPDATED_INPUT_XML>};
	
	close(UPDATED_INPUT_XML);
	
	$pattern = qr".*<TextField>[\r\n\s]*<InternalName>summary_file_id</InternalName>[\r\n\s]*<NewFieldValue operation=\"Type\">([^<]*)</NewFieldValue>[\r\n\s]*</TextField>[\r\n\s]*<TextField>[\r\n\s]*<InternalName>summary_summfile_id</InternalName>[\r\n\s]*<NewFieldValue operation=\"Type\">([^<]*)</NewFieldValue>[\r\n\s]*</TextField>[\r\n\s]*<TextField>[\r\n\s]*<InternalName>summary_dir_id</InternalName>[\r\n\s]*<NewFieldValue operation=\"Type\">([^<]*)</NewFieldValue>[\r\n\s]*</TextField>.*";
	
	@matched_pattern = $updated_input_xml_contents =~ m#$pattern#g;
	
	if (scalar @matched_pattern != 3)
	{
		print "\nERROR: Couldn't retrieve target rsp file and summary file from the updated input xml '$UPDATED_INPUT_XML'!!!\n";
		return 0;
	}
	
	$target_rsp_file = "${matched_pattern[2]}/$matched_pattern[0]";
	$target_summary_file = "${matched_pattern[2]}/$matched_pattern[1]";
	
	
	# Delete the target rsp file and summary file, in case they exist. 
	# This is to avoid the dialog box that comes up at the end of the wizard, 
	# asking if the files are to be replaced.
	$cmd = "rm -f $target_rsp_file $target_summary_file";
	
	print "\nExecuting $cmd ...\n";
	
	system("bash -c '$cmd'");
	
	
	# Invoke ant script
	print "\nExecuting cd $TEST_ARTIFACT_TARGET ...\n";
	
	$cd_exit_code = chdir ("$TEST_ARTIFACT_TARGET");
	
	if ($cd_exit_code == 0)
	{
		print "\nERROR: Couldn't cd to dir containing IDM Prov Wizard Automation files '$TEST_ARTIFACT_TARGET'!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	$log = "$RuntimeParamTable{WORKDIR}/ant.log";
	
	$cmd = "bash -c '$ENV{ANT_HOME}/bin/ant IdMProvWizGenerateResponseFile > $log 2>&1'";
	
	print "\nExecuting $cmd ...\n";
	
	system("bash -c '$cmd'");
	
	
	# Check if the rsp file and summary files are created
	if (! -e "$target_rsp_file")
	{
		print "\nERROR: Target rsp file '$target_rsp_file' doesn't exist. Some error may have occurred in the provisioning wizard. Please check logs/screenshots.\n";
		return 0;
	}
	elsif (! -e "$target_summary_file")
	{
		print "\nERROR: Target summary file '$target_summary_file' doesn't exist. Some error may have occurred in the provisioning wizard. Please check logs/screenshots.\n";
		return 0;
	}
	
	
	# Stop VNC
	stop_vnc();
	
	
	# GENERIC_RSP_FILE is same as RSP_FILE in this case
	$ExportParamTable{RSP_FILE} = "$target_rsp_file";
	$ExportParamTable{GENERIC_RSP_FILE} = "$ExportParamTable{RSP_FILE}";
	
	
	print "\nRSP file generated is: '$ExportParamTable{RSP_FILE}'\n";
	
	
	return 1;
}



sub update_input_xml
{
	# If input xml has been passed, use it, otherwise select the appropriate input xml
	if ($ImportParamTable{GEN_RSP_INPUT_XML} ne '')
	{
		$INPUT_XML = "$ImportParamTable{GEN_RSP_INPUT_XML}";
	}
	else
	{
print "==================================\n";
print $ImportParamTable{TOPO_CONFIGURATION};
print "==================================\n";
		if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_component')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_full.xml";
		}
		if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_component_oid')
        	{
            		$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_full_oid.xml";
        	}
		if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_component_oid_rcu')
        	{
            		$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_full_oid_rcu.xml";
        	}
		if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oam.xml";
		}
                if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_oid')
                {
                        $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oam_oid.xml";
                }
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oid')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oam_existing_oid.xml";
        }
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oam_existing_oud')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oam_existing_oud.xml";
        }
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_existing_oid')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oimxe_existing_oid.xml";
        }
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_existing_oud')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oimxe_existing_oud.xml";
        }
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_existing_oid')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_full_existing_oid.xml";
        }
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_full_existing_oud')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_full_existing_oud.xml";
        }
		if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oim')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oim.xml";
		}
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_oid')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oimxe_oid.xml";
        }
        if ($ImportParamTable{TOPO_CONFIGURATION} eq '1node_oimxe_oud')
        {
            $INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_1node_r2ps3_oimxe_oud.xml";
        }
		elsif ($ImportParamTable{TOPO_CONFIGURATION} eq '3node')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_3node.xml";
		}
		elsif ($ImportParamTable{TOPO_CONFIGURATION} eq '3nodeovmracdb')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_3node_ovm_racdb.xml";
		}
		elsif ($ImportParamTable{TOPO_CONFIGURATION} eq '4node')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_4node.xml";
		}
		elsif ($ImportParamTable{TOPO_CONFIGURATION} eq '4nodeovmracdb')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_4node_ovm_racdb.xml";
		}
		elsif ($ImportParamTable{TOPO_CONFIGURATION} eq 'simv2')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_simv2.xml";
		}
		elsif ($ImportParamTable{TOPO_CONFIGURATION} eq 'edg')
		{
			$INPUT_XML = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input_edg.xml";
		}
	}
	
	print "\nInput xml selected based on topo configuration is: '$INPUT_XML'\n";
	
	
	# Copy Input.dtd to WORKDIR
	$INPUT_DTD = "$RuntimeParamTable{AUTO_HOME}/scripts/idmqaprov/IdMProvWizardAutomation/input.dtd";
	
	$cmd = "cp $INPUT_DTD $RuntimeParamTable{WORKDIR}";
	
	print "\nExecuting $cmd ...\n";
	
	$cp_exit_code = system("bash -c '$cmd'");
	
	if ($cp_exit_code != 0)
	{
		print "\nERROR: Above command failed!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	
	# Update input xml
	$random = time();
	
	($input_xml_name = $INPUT_XML) =~ s#.*/##;
	
	$UPDATED_INPUT_XML = "$RuntimeParamTable{WORKDIR}/${input_xml_name}";
	
	print "\nCreating '$UPDATED_INPUT_XML' ...\n";
	
	if (!open(INPUT_XML, "$INPUT_XML"))
	{
		print "\nERROR: Couldn't open input xml '$INPUT_XML' for reading!!!\n";
		return 0;
	}
	
	if (!open(UPDATED_INPUT_XML, ">$UPDATED_INPUT_XML"))
	{
		print "\nERROR: Couldn't open updated input xml '$UPDATED_INPUT_XML' for writing!!!\n";
		return 0;
	}
	
	while (<INPUT_XML>)
	{
		$_ =~ s#\$HOSTNAME#$ImportParamTable{HOSTNAME}#g;
		$_ =~ s#\$WORKDIR#$RuntimeParamTable{WORKDIR}#g;
		$_ =~ s#\$FA_REPO#$ImportParamTable{FA_REPO}#g;
		$_ =~ s#\$IDMTOP#$ImportParamTable{BASEDIR}/IDMTOP#g;
		$_ =~ s#\${IDMTOP}#$ImportParamTable{BASEDIR}/IDMTOP#g;
		$_ =~ s#\$FILE_SEPARATOR#$DIRSEP#g;
		$_ =~ s#\${FILE_SEPARATOR}#$DIRSEP#g;
		$_ =~ s#\$OID_HOSTNAME#$ImportParamTable{OID_HOSTNAME}#g;
		$_ =~ s#\$OIM_HOSTNAME#$ImportParamTable{OIM_HOSTNAME}#g;
		$_ =~ s#\$OHS_HOSTNAME#$ImportParamTable{OHS_HOSTNAME}#g;
		$_ =~ s#\$OID_IDSTORE_DB_HOSTNAME#$ImportParamTable{OID_IDSTORE_DB_HOSTNAME}#g;
		$_ =~ s#\$OID_PSTORE_DB_HOSTNAME#$ImportParamTable{OID_PSTORE_DB_HOSTNAME}#g;
		$_ =~ s#\$OIM_DB_HOSTNAME#$ImportParamTable{OIM_DB_HOSTNAME}#g;
		$_ =~ s#\$OAM_DB_HOSTNAME#$ImportParamTable{OAM_DB_HOSTNAME}#g;
		$_ =~ s#\$OID_IDSTORE_RAC_DB1_HOSTNAME#$ImportParamTable{OID_IDSTORE_RAC_DB1_HOSTNAME}#g;
		$_ =~ s#\$OID_IDSTORE_RAC_DB2_HOSTNAME#$ImportParamTable{OID_IDSTORE_RAC_DB2_HOSTNAME}#g;
		$_ =~ s#\$OID_PSTORE_RAC_DB1_HOSTNAME#$ImportParamTable{OID_PSTORE_RAC_DB1_HOSTNAME}#g;
		$_ =~ s#\$OID_PSTORE_RAC_DB2_HOSTNAME#$ImportParamTable{OID_PSTORE_RAC_DB2_HOSTNAME}#g;
		$_ =~ s#\$OIM_RAC_DB1_HOSTNAME#$ImportParamTable{OIM_RAC_DB1_HOSTNAME}#g;
		$_ =~ s#\$OIM_RAC_DB2_HOSTNAME#$ImportParamTable{OIM_RAC_DB2_HOSTNAME}#g;
		$_ =~ s#\$OAM_RAC_DB1_HOSTNAME#$ImportParamTable{OAM_RAC_DB1_HOSTNAME}#g;
		$_ =~ s#\$OAM_RAC_DB1_HOSTNAME#$ImportParamTable{OAM_RAC_DB1_HOSTNAME}#g;
		$_ =~ s#\$OAM_RAC_DB2_HOSTNAME#$ImportParamTable{OAM_RAC_DB2_HOSTNAME}#g;
		$_ =~ s#\$OID_RAC_DB1_HOSTNAME#$ImportParamTable{OID_IDSTORE_RAC_DB1_HOSTNAME}#g;
		$_ =~ s#\$OID_RAC_DB2_HOSTNAME#$ImportParamTable{OID_IDSTORE_RAC_DB2_HOSTNAME}#g;
		$_ =~ s#\$IDM_RAC_DB1_HOSTNAME#$ImportParamTable{OIM_RAC_DB1_HOSTNAME}#g;
		$_ =~ s#\$IDM_RAC_DB2_HOSTNAME#$ImportParamTable{OIM_RAC_DB2_HOSTNAME}#g;
		$_ =~ s#\$ADMIN_LBR_HOSTNAME#$ImportParamTable{ADMIN_LBR_HOSTNAME}#g;
		$_ =~ s#\$ADMIN_LBR_PORT#$ImportParamTable{ADMIN_LBR_PORT}#g;
		$_ =~ s#\$OIM_LBR_HOSTNAME#$ImportParamTable{OIM_LBR_HOSTNAME}#g;
		$_ =~ s#\$OIM_LBR_PORT#$ImportParamTable{OIM_LBR_PORT}#g;
		$_ =~ s#\$OAM_LBR_HOSTNAME#$ImportParamTable{OAM_LBR_HOSTNAME}#g;
		$_ =~ s#\$OAM_LBR_PORT#$ImportParamTable{OAM_LBR_PORT}#g;
		$_ =~ s#\$OID_IDSTORE_LBR_HOSTNAME#$ImportParamTable{OID_IDSTORE_LBR_HOSTNAME}#g;
		$_ =~ s#\$OID_IDSTORE_LBR_PORT#$ImportParamTable{OID_IDSTORE_LBR_PORT}#g;
		$_ =~ s#\$OID_IDSTORE_LBR_SSL_PORT#$ImportParamTable{OID_IDSTORE_LBR_SSL_PORT}#g;
		$_ =~ s#\$OID_PSTORE_LBR_HOSTNAME#$ImportParamTable{OID_PSTORE_LBR_HOSTNAME}#g;
		$_ =~ s#\$OID_PSTORE_LBR_PORT#$ImportParamTable{OID_PSTORE_LBR_PORT}#g;
		$_ =~ s#\$OID_PSTORE_LBR_SSL_PORT#$ImportParamTable{OID_PSTORE_LBR_SSL_PORT}#g;
		$_ =~ s#\$OVD_LBR_HOSTNAME#$ImportParamTable{OVD_LBR_HOSTNAME}#g;
		$_ =~ s#\$OVD_LBR_PORT#$ImportParamTable{OVD_LBR_PORT}#g;
		$_ =~ s#\$OVD_LBR_SSL_PORT#$ImportParamTable{OVD_LBR_SSL_PORT}#g;
		$_ =~ s#_random#_$random#g;
		
		print UPDATED_INPUT_XML "$_";
	}
	
	close (INPUT_XML);
	close (UPDATED_INPUT_XML);
	
	
	return 1;
}



sub get_idm_prov_wizard_automation_files_loc_from_label
{
	if ($ImportParamTable{IDM_PROV_AUTOMATION_SOURCE} ne '')
	{
		print "\nIDM_PROV_AUTOMATION_SOURCE value is set. Using this as source location instead of getting the files from a label...\n";
		
		$TEST_ARTIFACT_SOURCE = "$ImportParamTable{IDM_PROV_AUTOMATION_SOURCE}";
	}
	else
	{
		print "\nAttempting to get the latest FMWTEST_MAIN_GENERIC label...\n";
		
		$LABEL_SERIES = "FMWTEST_MAIN_GENERIC";
		
		print "\nAttempting to determine the latest label in the series '$LABEL_SERIES'...\n";
		
		$cmd = "ade showlabels -series $LABEL_SERIES -latest | grep $LABEL_SERIES";
		print "\nExecuting $cmd ...\n";
		$output = `$cmd`;
		chomp($output);
		print "\nOutput is:\n$output\n";
		
		if ($output =~ /ade WARNING:/ or $output =~ /ade ERROR:/ or $output =~ /^\s*$/)
		{
			print "\nERROR: Couldn't determine latest label in the series '$LABEL_SERIES'!!!\n";
			return 0;
		}
		
		$LATEST_LABEL = $output;
		
		print "\nLatest label found in series '$LABEL_SERIES' is: $LATEST_LABEL\n";
		
		print "\nAttempting to get labelserver path for the label '$LATEST_LABEL'...\n";
		
		$cmd = "ade desc -l $LATEST_LABEL -labelserver | grep $LABEL_SERIES";
		print "\nExecuting $cmd ...\n";
		$output = `$cmd`;
		chomp ($output);
		print "\nOutput is:\n$output\n";
		
		# Get the last line of this output, since, sometimes, some warning messages 
		# might be displayed in the first few lines
		@output_lines = split(/[\r\n]+/, $output);

		if (scalar(@output_lines) == 0)
		{
			print "\nERROR: No. of output lines from above command is 0. Couldn't determine the labelserver path of label '$LATEST_LABEL'!!!\n";
			return 0;
		}

		$output = $output_lines[$#output_lines];

		print "\nLast line of output from above command: $output\n";
		
		if ($output =~ /ade WARNING:/ or $output =~ /ade ERROR:/ or $output =~ /^\s*$/)
		{
			print "\nERROR: Output contains warning or error, or there is no output to the above command. Couldn't determine the labelserver path of label '$LATEST_LABEL'!!!\n";
			return 0;
		}
		
		$LABELSERVER_PATH = $output;
		
		print "\nLabelserver path is: $LABELSERVER_PATH\n";
		
		if (! -e $LABELSERVER_PATH)
		{
			print "\nERROR: Labelserver path '$LABELSERVER_PATH' doesn't exist!!!\n";
			return 0;
		}
		else
		{
			print "\nLabelserver path '$LABELSERVER_PATH' exists\n";
			
			$TEST_ARTIFACT_SOURCE = "${LABELSERVER_PATH}/fmwtest/idmtools/functional/IdMProvWiz";
		}
	}
	
	# Check if the IDM Prov Wizard Automation files dir exists
	if (! -e "$TEST_ARTIFACT_SOURCE")
	{
		print "\nERROR: Couldn't find IDM Prov Wizard Automation files dir '$TEST_ARTIFACT_SOURCE'!!!\n";
		return 0;
	}
	
	# Copy the IDM Prov Wizard Automation files dir to WORKDIR
	($TEST_ARTIFACT_SOURCE_DIR_NAME = $TEST_ARTIFACT_SOURCE) =~ s#.*/##;
	$TEST_ARTIFACT_TARGET = "$RuntimeParamTable{WORKDIR}/${TEST_ARTIFACT_SOURCE_DIR_NAME}";

	if ( -e "$TEST_ARTIFACT_TARGET")
	{
		print "\nTest artifact target dir '$TEST_ARTIFACT_TARGET' exists ...\n";
		
		$cmd = "chmod -R 777 $TEST_ARTIFACT_TARGET";
		
		print "\nExecuting $cmd ...\n";
		
		$chmod_exit_code = system("bash -c '$cmd'");

		if ($chmod_exit_code != 0)
		{
			print "\nERROR: Above command failed!!!\n";
			print "\nError is:\n$!\n";
			return 0;
		}
	}

	print "\nCopying the IDM Prov Wizard Automation files dir to WORKDIR...\n";
	
	$cmd = "cp -rL $TEST_ARTIFACT_SOURCE $RuntimeParamTable{WORKDIR}";
	
	print "\nExecuting $cmd ...\n";
	
	$cp_exit_code = system("bash -c '$cmd'");
	
	if ($cp_exit_code != 0)
	{
		print "\nERROR: Above command failed!!!\n";
		print "\nError is:\n$!\n";
		return 0;
	}
	
	
	if (! -e "$TEST_ARTIFACT_TARGET")
	{
		print "\nERROR: Couldn't find copied IDM Prov Wizard Automation files dir '$TEST_ARTIFACT_TARGET'!!!\n";
		return 0;
	}
	
	
	return 1;
}



sub start_vnc_and_set_display
{
	if ( $PLATFORM ne 'nt' )
	{
		# Fix for porting exceptions.
		# Code added for installing idm provisioning bits for porting platforms
		# This code is valid only for SOLARIS SPARC, SOLARIS X64 and AIX

		$PLATFORM = DTE::getOS();

		if ( $PLATFORM eq 'solaris' || $PLATFORM eq 'solarisx8664' || $PLATFORM eq 'aix')
		{
		  print "\n Platform is :: $PLATFORM !\n";
		  print "\n Skipping the vnc creation for porting platforms !\n";
		  $PLATFORM_PORT = 1
		}
		else
		{
		  $PLATFORM_PORT = 0
		}
		if ( $PLATFORM_PORT ne 1)
		{
			print "\n Platform is :: $PLATFORM !\n";
			print "\n vnc creation for non porting platforms \n";
			# Kill existing VNCs
			system ("bash -c 'kill -9 `ps -ef | grep Xvnc | tr -s \" \" | cut -d\" \" -f2`'");

			# Delete existing /tmp/.X*, if any
			system ("/usr/local/packages/aime/ias/run_as_root 'rm -rf /tmp/.X*'");

			# Delete existing .vnc dir, if any
			system ("bash -c 'rm -rf $ENV{HOME}/.vnc'");
			
			# Create .vnc directory
			mkdir("$ENV{HOME}/.vnc") or die "\n\nCould not create .vnc directory\n\n";

			# Copy custom xstartup to enable GNOME
			$cp_exit_code = system("bash -c 'cp $RuntimeParamTable{AUTO_HOME}/scripts/fusionapps/MT/Simv2SharedIDM/xstartup $RuntimeParamTable{AUTO_HOME}/scripts/fusionapps/MT/Simv2SharedIDM/passwd $ENV{HOME}/.vnc/'");
			
			if ($cp_exit_code != 0)
			{
				print "\nERROR: Failed to copy xstartup and passwd files to VNC dir!!!\n";
				print "\nError is:\n$!\n";
				return 0;
			}

			# Change permission of the files
			$chmod_exit_code = chmod(0777, "$ENV{HOME}/.vnc/xstartup");
			
			if ($chmod_exit_code == 0)
			{
				print "\nERROR: Could not change permission of xstartup file '$ENV{HOME}/.vnc/xstartup'!!!\n";
				print "\nError is:\n$!\n";
				return 0;
			}
			
			$chmod_exit_code = chmod(0600, "$ENV{HOME}/.vnc/passwd");
			
			if ($chmod_exit_code == 0)
			{
				print "\nERROR: Could not change permission of passwd file '$ENV{HOME}/.vnc/passwd'!!!\n";
				print "\nError is:\n$!\n";
				return 0;
			}
			
			# Add xauth dir to PATH
			$ENV{PATH} = $ENV{PATH} . $PATHSEP . "/usr/X11R6/bin";

			print "\nPATH: $ENV{PATH}\n";
			# start the vnc server
			print "\n\nStarting vnc server..\n";
			print "bash -c 'vncserver -geometry 1280x1024 > $RuntimeParamTable{WORKDIR}/vnc.start.out 2>&1'\n";
			system("bash -c 'vncserver -geometry 1280x1024 > $RuntimeParamTable{WORKDIR}/vnc.start.out 2>&1'");

			# Set the DSIPLAY env variable to whatever port on which the vnc session is started
			$DISPLAY = "";

			if ( open(VNC_OUT_FILE, "$RuntimeParamTable{WORKDIR}/vnc.start.out") )
			{
				while(my $line = <VNC_OUT_FILE>)
				{
					chomp $line;
					$line =~ s/^\s+//;
					$line =~ s/\s+$//;

					if ( $line =~ /New.*desktop is .*(:[0-9]+)$/ )
					{
						$DISPLAY = $1;
						print "\nDISPLAY is: $DISPLAY \n";
						last;
					}
				}

				close(VNC_OUT_FILE);
			}
			else
			{
				print "\nERROR: $RuntimeParamTable{WORKDIR}/vnc.start.out doesn't exist!!!\n";
				return 0;
			}
			
			if ($DISPLAY eq "")
			{
				print "\nERROR: Couldn't find DISPLAY parameter in vnc output file '$RuntimeParamTable{WORKDIR}/vnc.start.out'!!!\n";
				return 0;
			}
			
			$ENV{DISPLAY} = $DISPLAY;
		}
		
		$vnc_started = 'true';
	}
	
	return 1;
}




sub stop_vnc
{
	if ($vnc_started eq 'true')
	{
		if ( $PLATFORM ne 'nt' )
		{
			print "\n\nStopping vnc server..\n";
			print "bash -c 'vncserver -kill $ENV{DISPLAY} > $RuntimeParamTable{WORKDIR}/vnc.stop.out 2>&1'\n";
			system "bash -c 'vncserver -kill $ENV{DISPLAY} > $RuntimeParamTable{WORKDIR}/vnc.stop.out 2>&1'";

			# Remove .vnc directory and .Xauthority file
			system ("bash -c 'rm -rf $ENV{HOME}/.vnc'");
			system ("/usr/local/packages/aime/ias/run_as_root '$ENV{HOME}/.Xauthority'");
		}
		
		$vnc_stopped = 'true';
	}
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

