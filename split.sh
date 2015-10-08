#!/bin/sh

str="SHIPHOME_RDBMS_11.2.0.X.0=/ade_autofs/shiphomes/rdbms/linux.x64/11.2.0/11.2.0.3.0/PRODUCTION/database |||| DB_PORT=1521 |||| JAVA_HOME=/net/adcnas418/export/farm_fmwqa/java/linux64/jdk6 |||| SHIPHOME_AS11_SOA_11.1.1.7.0=%ADE_VIEW_ROOT%/soa/shiphome/soa*.zip |||| SHIPHOME_AS11_IM_11.1.1.7.0=/ade_autofs/gr04_fmw/PLTSEC_11.1.1_LINUX.X64.rdd/RELEASE_11.1.1.7.0/pltsec/shiphome/idm.zip |||| -noview=true |||| SHIPHOME_WG11G=%ADE_VIEW_ROOT%/idm/shiphome/webgate.zip |||| SHIPHOME_WLS_10.3.6.0=/ade_autofs/gr04_fmw/WLS10_11.1.1_GENERIC.rdd/RELEASE_11.1.1.6.0/wls10/wls_generic.jar |||| JRE_LOC=/net/adcnas418/export/farm_fmwqa/java/linux64/jdk6 |||| SHIPHOME_AS11_IDM_11.1.2.2.0=%ADE_VIEW_ROOT%/idm/shiphome/iamsuite*.zip |||| -noshutdown=true |||| SHIPHOME_AS11_WEBTIERCD_11.1.1.7.0=/ade_autofs/gr04_fmw/ASCORE_11.1.1_LINUX.X64.rdd/RELEASE_11.1.1.7.0/ascore/shiphome/webtier.zip |||| USE_MY_WLS=true |||| -parallel=true ||||"
arr=(${str//||||/ })
for i in ${arr[@]}
do
	echo $i
done
echo ==========================
echo abc=$abc 
echo ==========================
