#!/bin/bash
TIME () {
local fun=$1
local method=$2
if [[ $fun == "timestamp" ]]; then
	printf "$(date +%Y-%m-%dT%H:%M:%S)"
elif [[ $fun == "time" ]]; then
	if [[ $method == "start" ]]; then
		start_timestamp=$(date +%s)
		return 0
	elif [[ $method == "stop" ]]; then
		current_timestamp=$(date +%s)
		return 0
	elif [[ $method == "fetch" ]]; then
		printf $(echo "scale=4; ($current_timestamp - $start_timestamp)/120" | bc)
	fi
fi
}


CONTENT () {
#usage 
#CONTENT stage output_file name:time_stamp:hostname:time:errors:failures:shell_output_file
local stag=$1
local output_file=$2
local name=$(echo $3 | awk -F "," '{print $1}')
local time_stamp=$(echo $3 | awk -F "," '{print $2}')
local hostname=$(echo $3 | awk -F "," '{print $3}')
local time=$(echo $3 | awk -F "," '{print $4}')
local errors=$(echo $3 | awk -F "," '{print $5}')
local total_test=$(echo $3 | awk -F "," '{print $6}')
local failures=$(echo $3 | awk -F "," '{print $7}')
local shell_output_file=$(echo $3 | awk -F "," '{print $8}')

if [[ $stag == "start" ]]; then

	if [[ -f $output_file ]]; then
		rm -rf $output_file
	fi 
	touch $output_file
elif [[ $stag == "success" ]]; then
	cat >>$output_file<<-EOF
	<testcase name="${name}" time="${time}" hostname="${hostname:-localhost}" >
	<system-out>
	<![CDATA[
	$(cat ${shell_output_file})
	]]>
	</system-out>
	</testcase>
EOF
elif [[ $stag == "failure" ]]; then
	cat >>$output_file<<-EOF
	<testcase name="${name}" time="${time}" hostname="${hostname:-localhost}" >
	<failure message="Test failure" />
	<system-out>
	<![CDATA[
	$(cat ${shell_output_file})
	]]>
	</system-out>
	</testcase>
EOF
elif [[ $stag == "end" ]]; then
	cat >>$output_file<<-EOF
	</testsuite>
	</testsuites>
EOF

    sed -i -e '1s/^/<?xml version="1.0" encoding="UTF-8" ?> \n /' $output_file
	sed -i -e '2s/^/<testsuites> \n /' $output_file
	sed -i -e '3s/^/<testsuite name="'${name}'" timestamp="'${time_stamp}'" hostname="'${hostname:-localhost}'" time="'${time}'" errors="'${errors}'" tests="'${total_test}'" failures="'${failures}'"> \n /' $output_file
fi
}



MY_JUNIT() {
	local output_file=$1
	local function_des=$2
	local function=( ${@:3} )
	local success_rate=0
	local failure_rate=0
	total_time_taken=0
	tmp_file=$(mktemp)
	term_out=$(printf "%-$(tput cols)s" "/") 
    CONTENT start $output_file
	for my_fun in ${function[@]} ;
	do

		echo "${term_out// //}"
		printf "\nRunning Spec  $my_fun\n"
		echo "${term_out// //}"
		timestamp=$(TIME timestamp)
		TIME time start
		$my_fun | while read line; do echo "[Shell-JUnit]>  $line"; done | tee -a ${tmp_file}
		status=${PIPESTATUS[0]}
		sed -i -r 's/.{15}//' ${tmp_file}
		TIME time stop
		total_time_taken=$(echo "scale=4; $total_time_taken + $(TIME time fetch)" | bc ) 
		if [[ $status == "0" ]]; then
			CONTENT success $output_file $my_fun,$timestamp,,$(TIME time fetch),0,${#function[@]},0,$tmp_file
			let success_rate=success_rate+1

		else
			#if any of the test failed adding 
			final_status=1
			CONTENT failure $output_file $my_fun,$timestamp,,$(TIME time fetch),0,${#function[@]},0,$tmp_file
			let failure_rate=failure_rate+1
        fi
    > ${tmp_file}
    done
    CONTENT end $output_file $function_des,$timestamp,,$total_time_taken,0,${#function[@]},${failure_rate},$tmp_file
    echo "${term_out// //}"
    printf "\n Test Results: \n "

    printf "\n Total_Test: ${#function[@]} \t Sucess:${success_rate} \t Failure:${failure_rate} \n"
    printf "\n Total_Time: $total_time_taken \n \n "

    return ${final_status:-0}
}



