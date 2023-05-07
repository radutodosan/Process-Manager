#!/bin/bash


# Table header
echo "     PID              USER   %CPU   %MEM   I/O   BOUND   NAME"

for pid in $(ls /proc | grep -E "^[0-9]+$")
do
	# Get the process stat file
    	stat_file="/proc/$pid/stat"
    	
    	# Get the process status file
    	status_file="/proc/$pid/status"
    	
    	if [ -f "$stat_file" ] && [ -f "$status_file" ]
    	then
    		# Read the process username from the "status" file
        	user=$(grep "Uid:" $status_file | awk '{print $2}')
        	user=$(id -un $user)
        	
        	# Get process name
        	name=$(awk '{print $2}' $stat_file)
        
        	# Get the process stat information
        	stat_info=$(cat $stat_file)
        
		# Read the process uptime from the "stat" file
		uptime=$(awk '{print $1}' /proc/uptime)
        
        	# Get the process start time value
		starttime=$(awk '{print $22}' $stat_file)
		
		# Get the clock tick value
		hertz=$(getconf CLK_TCK)
		
		# Calculate the total time
		total_time=$(awk "BEGIN{print int($uptime - $starttime / $hertz)}")
		
		# Calculate the process CPU usage
		utime=$(echo $stat_info | awk '{print $14}')
		stime=$(echo $stat_info | awk '{print $15}')
		cpu_usage=$(awk "BEGIN{printf \"%.2f\", 100*($utime+$stime)/($total_time*$hertz)}")
		
		# Calculate the process MEM usage
		VmRSS=$(awk '/VmRSS/ {print $2}' /proc/$pid/status)
		if [ -z "$VmRSS" ]
		then
			mem_usage='0,00'
			
		else
			mem_usage=$(awk "BEGIN{printf \"%.2f\", $VmRSS/100000}")
		fi
			
		# Get the I/O statistics of the process
		read_bytes=$(awk '/read_bytes/ {print $2}' /proc/$pid/io)
		write_bytes1=$(awk '/write_bytes/ {print $2}' /proc/$pid/io)
		write_bytes1=(${write_bytes1[@]})
		write_bytes=${write_bytes1[0]}
			
		# sum read and write
		if [[ -z "$read_bytes" || -z "$write_bytes" ]]
		then
			total=0
		else
			total=$(expr $read_bytes + $write_bytes)
		fi

		# Get the total I/O capacity of the system
		total_io_capacity=$(awk '{print $4+$8}' /proc/diskstats | awk '{s+=$1} END {print s}')

		if [[ -z "$total" || -z "$total_io_capacity" ]]
		then
			io_utilization=0
		else
			io_utilization=$(awk "BEGIN{printf \"%.2f\", $total / $total_io_capacity / 100000}")
		fi
		
		bound=''
		# Check if the process is I/O bound
		if [[ -z "$read_bytes" || -z "$write_bytes" ]]
		then
		    	bound=""
		else
			bound="I/O"
		fi

		# Check if the process is CPU bound
		if [[ $cpu_usage > $io_utilization ]]
		then
		    	bound="CPU"
		fi
		
		if [[ -z "bound" ]]
		then
			bound=""
		fi
		
		# print out the information
		printf "%8d  %16s  %5.2f  %5s  %5s  %4s    %s\n" "$pid" "$user" "$cpu_usage" "$mem_usage" "$io_utilization" "$bound" "$name"

	fi
done

