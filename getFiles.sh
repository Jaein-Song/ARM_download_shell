#!/bin/sh
# ARM Live Data Webservice file retrieval helper script.
# Version: 2.0
# Contact: Ranjeet Devarakonda zzr@ornl.gov, Michael Crow crowmc@ornl.gov

#Modified by Jae In Song jaein_song@yonsei.ac.kr
# Usage:
# ./getFiles.sh USER DS START [END]
US=Jsong1:3f90e5a0f25400e
case $# in
    3) US=$1
       DS=$2
       START=$3
       END=""
       start_second=`date -d ${START} +%s`
       end_second=`date -u +%s`
       end_second_origin=$end_second
       ;;
    4) US=$1
       DS=$2
       START=$3
       start_second=`date -d ${START} +%s`
       END="&end=$4"
       END_date=$4
       end_second=`date -d ${END_date} +%s`
       end_second_origin=$end_second
       ;;
    0|1|2|*) echo -e "Usage:\n$0 USER:TOKEN DS START [END]"
       exit
       ;;
esac
time_diff=`expr $end_second - $start_second`
if [ $time_diff -gt 172800000 ]; then
    END_date="`date -d "2000days ${START}" +%F`"
    END_origin=$END
    END="&end=$END_date"
    end_second="`date -d ${END_date} +%s`"
    if [ $end_second -gt $end_second_origin ]; then
        end_second=$end_second_origin
    fi
fi

while [ $end_second -le $end_second_origin ]; do
    OUT=$(curl -ks "https://adc.arm.gov/armlive/livedata/query?user=${US}&ds=${DS}&start=${START}${END}&wt=json")
    if echo ${OUT} | grep success >/dev/null
		then
		# Remove any special characters
		DS_dir=$(echo ${DS} | tr -cd "[:alnum:]")
		
		# Make directory to organize downloads
		if [ ! -d ${DS_dir} ]; then mkdir ${DS_dir}
        fi
		
		# Parse JSON to iterable items
		OUT=$(echo ${OUT} | cut -d '[' -f 2 | cut -d ']' -f 1 | sed 's/,/ /g')
		for i in ${OUT}
		do
		    # Trim away all but the file name
		    i=$(echo $i | tr -d '"' | tr -d " ")
		    if [ -s ${DS_dir}/$i ]; then
		        echo "File exists"
		    else
		        echo "Start downloading" ${i}
		    # Download the file via web service
		       curl -k -s "https://adc.arm.gov/armlive/livedata/saveData?user=${US}&file=$i" > ${DS_dir}/$i
		        echo "END downloading" ${i}
		    fi  
		done
        START=${END_date}
        END_date="`date -d "2000days ${START}" +%F`"
        end_second="`date -d ${END_date} +%s`"
        if [ $end_second -gt $end_second_origin ]; then
            end_second=`expr $end_second_origin + 1`
            END=$END_origin
        else
            END="&end=$END_date"
        fi
		else
		echo "No files for datastream '${DS}' between ${START} and ${END_date}"
    fi
done
