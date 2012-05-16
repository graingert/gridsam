echo ********************restart gridsam on job is execution*********\n
jsdlfile=cat-longexec-ictcondor.jsdl
state=active
resultfile=./testfile/restart-gridsam-execution-result.txt


[ -e $resultfile ] && rm $resultfile -f
gridsam-submit $jsdlfile >jobid.txt 2>>err.txt
[ $? -eq "0" ]|| exit 1

jobid=`cat jobid.txt`
[ $? -eq "0" ]|| exit 1

while [ 1=1 ]
do
        status=`gridsam-status -j  $jobid 2>>err.txt | grep "Job Progress" | awk '{print $NF}'`
        [ $? -eq "0" ]|| continue
        if [ $status == $state ]; then
                sleep 20s
		/opt/OMII/jakarta-tomcat-5.0.25/bin/catalina.sh stop
		sleep 1m
		/opt/OMII/jakarta-tomcat-5.0.25/bin/catalina.sh start
		
		[ $? -eq "0" ]|| echo "terminate job failed, try again"
                #echo get job status is $status
                break
        fi
        if [ $status == "done" -o $status == "failed" -o $status == "terminated" ]; then
                gridsam-status -j  $jobid 2>>err.txt
		break
        fi
done

echo restart gridsam on job is execution, the job id is $jobid >> terminate-test-jobid.txt
