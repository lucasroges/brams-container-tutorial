#!/bin/bash
#
# Script to run the test cases
#
# Example
# ./run-brams -np 4 -testcase meteo-chem
# ./run-brams -np 8 -hosts machine1:4,machine2:4
#


# Default parameters

nprocs=1
test_case=meteo-only
hosts=auto


# Read command line options

while (( $# > 1 ))
do
	opt="$1"
	case $opt in
		"-np")
			nprocs="$2"
			shift
			;;

		"-testcase")
			test_case="$2"
			shift
			;;

		"-hosts")  
        	hosts="$2"
        	shift
        	;;
	esac
	shift
done


# Generate MPI hostfile

rm -f $HOME/hosts
if [ $hosts != "auto" ]
then
	IFS=,
	ary=($hosts)
	for key in "${!ary[@]}"; do echo "${ary[$key]}" >> $HOME/hosts; done
else
	iplists=`dig +short tasks.master A`
	for i in $iplists; do
		np=`ssh $i "nproc --all"`
		echo "$i:$np" >> $HOME/hosts
	done
	iplists=`dig +short tasks.workers A`
	for i in $iplists; do
		np=`ssh $i "nproc --all"`
		echo "$i:$np" >> $HOME/hosts
	done
fi


# Print selected options

echo "test case = " $test_case
echo "nprocs = " $nprocs
echo "MPI hostfile:"
cat $HOME/hosts


# Execute test case assigned in the parameters

cd $HOME/bin && rm -rf tmp/ && \
	mkdir ./tmp && export TMPDIR=./tmp && ulimit -s 65536 && export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH && \
	/opt/mpich3/bin/mpirun -hostfile $HOME/hosts -np $nprocs ./brams-5.3 -f RAMSIN_${test_case}


# Check exit status

exit_code=$?

if [ $exit_code -eq 0 ]; then

	echo "Execution finished successfully!"
	echo "Output available at " $HOME/bin/dataout
else

	echo "Execution finished with error!"
	echo "Application exited with code $exit_code"
fi
