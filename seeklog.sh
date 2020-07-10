#!/bin/bash

#
# dependencies: podman, zip
# todo: docker

help()
{
   echo "podman log extracting tool"
   echo "Usage: $0 -c [CONTAINER] -d [YYYY-MM-DD]" # $0 is program name
   echo -e "\t-c <container_name/conatiner_id>"
   echo -e "\t-d <date in format YYYY-MM-DD>"
   echo -e "\t-f regex style filters"
   exit 1 # close
}


debug=True

# zipping every file into single archive
zipping_per_single="True"

# zipping all files to machine archive
zipping_all="False"

# both of above
double_zipping="False"


##
## hostname
##

# gets logs from one specific container at one specific date
get_log() {
   podman logs $container_id | grep $date | grep -e $filters;
}


# gets logs from all found containers at one specific date
all_on_date() {
   for container_name in `podman ps -a | tail -n +2 | rev | cut -d ' ' -f1 | rev | grep -v infra`;
      do
         podman logs $container_name | grep $date | grep -e $filters;
      done
}


# gets logs from all the containers from the start
all_from_start() {
   for container_name in `podman ps -a | tail -n +2 | rev | cut -d ' ' -f1 | rev | grep -v infra`;
      do
         podman logs $container_name > "$container_name.log" &&

         # zips each file into it's own archive
         if [ $zipping_per_single == "True" ];
         then
            zip -rm "$container_name.zip $container_name.log";
         fi
      done

   # zips all files into one archive
   if [ $zipping_all == "True" ];
   then
      zip -rm "MACHINE.zip *.log"
   fi

   # both options of zipping
   if [ $double_zipping == "True" ];
   then
      for log in `ls | grep ".log" `;
      do
         zip -rm "$log.zip $log";
      done
      zip -rm "MACHINE.zip *.zip"
   fi
}




while getopts "c:d:f:" opt
do
   case "$opt" in
      c ) container_id="$OPTARG" ;; #  <-
      d ) date="$OPTARG" ;;         #  <- Set options
      f ) filters="$OPTARG" ;;      #  <-
      ? ) help ;;                   # while no parameter specified -> help()
   esac
done





# get logs from all found containers from the start if no parameters are specified
if [ -z "$container_id" ] || [ -z "$date" ]
then
   echo "Getting logs from all found containers from the start";
   all_from_start

   #echo "Nor date or container name/id were specified.";
   #help
elif [ -z "$container_id" ] || [ $date == "today" ]
then
   echo "Getting logs from all containers from today";
   date=01239123
   all_on_date
fi





if [ $debug == "True" ];
then
   # print out parameters
   echo -e "container:\t$container_id"
   echo -e "date:\t\t$date"
   echo -e "filters:\t$filters"
fi

if [ $container_id == "all" ];
then
   echo "All containers";
fi
