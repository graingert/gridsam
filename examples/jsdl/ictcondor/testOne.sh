#!/bin/sh
# This file tests all JSDLs here and check the result accorrding to the configuration files.
# Yongqiang Zou. 2008.9.25.

gridsamHome=$1
jsdlFile=$2
resultFile=$3

if [ $# != 3 ]; then
	echo Usage ./testAll.sh gridsamHome jsdlFile resultFile
	echo use default value
	
	gridsamHome=/opt/OMIICLIENT/gridsam
	jsdlFile=cat-DeleteOnTermination.jsdl
	resultFile=$jsdlFile-`date '+%Y%m%d-%H%M%S'`.txt
	
	#jsdlFile=~/OMIICLIENT/gridsam/jsdl/fork/cat-fork.jsdl
	#jsdlFile=~/OMIICLIENT/gridsam/jsdl/pbsNoneHead/wrong-executable.jsdl
	#jsdlFile=~/OMIICLIENT/gridsam/jsdl/condor/100MReliableGSIFTP.jsdl
	#jsdlFile=~/OMIICLIENT/gridsam/jsdl/condor/uname-stageinexec.jsdl
	#jsdlFile=~/OMIICLIENT/gridsam/jsdl/reliableFile/100MReliableFTP.jsdl
	#resultFile=~/OMIICLIENT/gridsam/jsdl/result.txt
fi


echo gridsamHome is $gridsamHome
echo jsdlFile is $jsdlFile
echo resultFile is $resultFile

msg="test begin at `date`"
echo $msg > $resultFile	# To start and clean up files.
echo $msg
file=$jsdlFile

	
	#cd $gridsamHome/bin
	#echo `pwd`
	echo submitting $file
	gridsam-submit $file 1>TMPSTDOUT 2>TMPSTDERROR
	if [ $? != 0 ]; then
		echo "" >> $resultFile
		echo "" >> $resultFile
		echo "==============================================" >> $resultFile
		msg="result of test $fileCnt --- $file --- ??? --- submitfailed"
                echo $msg >> $resultFile
                echo $msg
		msg="status string : STDOUT `cat TMPSTDOUT` STDERR `cat TMPSTDERROR`"
		echo $msg >> $resultFile
		echo $msg
		continue;
	fi
	jobid=`cat TMPSTDOUT`
	rm TMPSTDOUT 1>/dev/null 2>/dev/null
	rm TMPSTDERR 1>/dev/null 2>/dev/null
	echo submit $file success and get jobid $jobid

	retryCnt=0
	maxRetryCnt=100
	while [ 1 = 1 ]
	do
		retryCnt=`expr $retryCnt + 1`
		sleep 5;

		#statusRst=`./gridsam-status -j $jobid`
		#if [ $? != 0 ]; then
		#	echo "get status of $jobid failed, skip it and try again." 
		#	continue;
		#fi
		#echo $statusRst | sed G > status_temp_file
		#rm status_temp_file 1>/dev/null 2>/dev/null
		#status=`grep "Job Progress" status_temp_file | sed 's/.*-> //g'`

		status=`gridsam-status -j $jobid | grep "Job Progress" | awk '{print $NF}'`
		#echo get status of job $jobid $status

	        if [ $? != 0 ]; then
                       echo "get status of $jobid failed, skip it and try again."
                       continue;
                fi

		#echo "the job status: $status"

		if [ $status = "done" -o $status = "failed" -o $status = "terminated" ] ; then
			echo "" >> $resultFile
			echo "" >> $resultFile
			echo "==============================================" >> $resultFile
			msg="result of test $fileCnt --- $file --- $jobid --- $status"
			echo $msg >> $resultFile
			echo $msg
			#msg="status string : $statusRst"
                        #msg="status string : `./gridsam-status -j $jobid`"
			#echo $msg >> $resultFile
			#echo $msg
			echo status string : >> $resultFile
			./gridsam-status -j $jobid >> $resultFile
			break;
		fi
		if [ $retryCnt -gt $maxRetryCnt ]; then
			echo "" >> $resultFile
			echo "" >> $resultFile
			echo "==============================================" >> $resultFile
			msg="result of test $fileCnt --- $file --- $jobid --- exceed max retry cnt of check status : $maxRetryCnt"
                        echo $msg >> $resultFile
                        echo $msg
                        #msg="status string : `./gridsam-status -j $jobid`"
                        #echo $msg >> $resultFile
                        #echo $msg
                        echo status string : >> $resultFile
                        ./gridsam-status -j $jobid >> $resultFile
                        break;
		fi
	done

msg="test end at `date`"
echo $msg >> $resultFile
echo $msg


