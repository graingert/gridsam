#make sure that jobname.subpara exist in current direction
#"hello" is a job name, so does "hello_long"
echo "first test a job which can be executed in an extremely short time"

#submit a job
#./condortest.sh -u gos -p hello -b -w `pwd`
./condor_driver_sudo.sh -u gos  -p hello -b -w `pwd` > out.txt
cat out.txt
echo "********do_submit success"
echo

#get jobid from out.txt file
jobid=`cat out.txt | cut -d'>' -f3 | cut -d'<' -f1`

#do_status
#./condortest.sh -u gos -p hello -i $jobid -s -w `pwd`
./condor_driver_sudo.sh -u gos -p hello -i $jobid -s -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********do_status success"
echo

#do_screen_output
#./condortest.sh -u gos -p hello -i $jobid -r -w `pwd`
./condor_driver_sudo.sh -u gos -p hello -i $jobid -r -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********do_screen_output success"
echo

#do_detail
#./condortest.sh -u gos -p hello -i 76.0 -d -w `pwd
./condor_driver_sudo.sh -u gos -p hello -i $jobid -d -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********do_detaiol success"
echo

#get out put file
#./condortest.sh -u gos -p hello -i $jobid -o -w `pwd
./condor_driver_sudo.sh -u gos -p hello -i $jobid -o -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********get output file name success"
echo

#do_cancel
#CONST_OP_Array=("condor_submit" "condor_q" "condor_rm" "condor_history")
#./condortest.sh -u gos -p hello -i $jobid -c -w `pwd`
./condor_driver_sudo.sh -u gos -p hello -i $jobid -c -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********do_cancel success"
echo

echo "test a job which will excute long time e.g. job of hello_long"

#submit a job
#./condortest.sh -u gos -p hello -b -w `pwd`
./condor_driver_sudo.sh -u gos  -p hello_long -b -w `pwd` > out.txt
[ $? -eq "0" ]||exit 0
cat out.txt | grep "Failed"
[ $? -eq "0" ]||echo "job submit fail"
cat out.txt
echo "********do_submit success"
echo

#get jobid from out.txt file
jobid=`cat out.txt | cut -d'>' -f3 | cut -d'<' -f1`

#do_status
#./condortest.sh -u gos -p hello_long -i $jobid -s -w `pwd`
./condor_driver_sudo.sh -u gos -p hello_long -i $jobid -s -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********do_status success"
echo

#do_screen_output
#./condortest.sh -u gos -p hello_long -i $jobid -r -w `pwd`
./condor_driver_sudo.sh -u gos -p hello_long -i $jobid -r -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********do_screen_output success"
echo

#do_detail
#./condortest.sh -u gos -p hello_long -i $jobid -d -w `pwd
./condor_driver_sudo.sh -u gos -p hello_long -i $jobid -d -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********do_detaiol success"
echo

#get out put file
#./condortest.sh -u gos -p hello_long -i $jobid -o -w `pwd
./condor_driver_sudo.sh -u gos -p hello_long -i $jobid -o -w `pwd`
[ $? -eq "0" ]||exit 0
echo "********get output file name success"
echo

#do_cancel
#CONST_OP_Array=("condor_submit" "condor_q" "condor_rm" "condor_history")
#./condortest.sh -u gos -p hello_long -i $jobid -c -w `pwd`
./condor_driver_sudo.sh -u gos -p hello_long -i $jobid -c -w `pwd`
[ $? -eq "0" ]||exit 0
# "********do_cancel success"
