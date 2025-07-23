#!/usr/bin/env zsh

INTERVAL=300
today=$(date +%Y-%m-%d)
timestamp1=$(date -d "$today" +%s)
LOG_FILE="$HOME/docker_dameon.txt"
touch "$LOG_FILE"


list_of_containers=$(docker ps --format '{{.Names}}' | wc -l)
declare -A dangling
red_count=0
docker ps --format '{{.Names}}'
IFS=$'\n' arr=($(docker ps --format '{{.Names}}')); unset IFS
for i in "${arr[@]}"; do
    cont_id=${arr[i]}
    date=$(docker inspect --format='{{.State.StartedAt}}' "$cont_id" | sed 's/T.*//')
    timestamp2=$(date -d "$date" +%s)
    count=1
    difference_seconds=$((timestamp2 - timestamp1))
    
    #get difference in seconds and check if it is ge 1 month.
    
    if [[ $difference_seconds -ge 2592000 ]]
    then
        dangle "$cont_id" "$count"
    fi
    if [[ $count -eq 0 ]]
    then
        stopnlog "$cont_id"
        ((red_count++))
    fi
    
    
    

dangle()
{
    local container_id=$1
    
    tmp=0
    
    connections=$(docker exec "$container_id" netstat -an | grep -c "ESTABLISHED" || echo "0")
    cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container_id" | sed 's/%//' || echo "0")
    # mem_usage=$(docker stats --no-stream --format "{{.MemPerc}}" "$container_id"| sed 's/%//' || echo "0")

    if [[ "$connections" -eq 0 ]] && [[ "${cpu_usage%.*}" -lt 1 ]] ; then
        tmp=0
    else
        tmp=1
    fi
    eval "$2=$tmp"
}
stopnlog() {
    container_id=$1
    start_date=$(docker inspect --format='{{.State.StartedAt}}' "$container_id" | sed 's/T.*//')
    create_date=$(docker inspect --format='{{.Created}}' "$container_id" | sed 's/T.*//')
    working_dir=$(docker inspect --format='{{.Config.WorkingDir}}' "$container_id")
    base_image=$(docker inspect --format='{{.Config.Image}}' "$container_id")
    
    echo -e "\n\n$container_id" >> $LOG_FILE
    echo -e "\t Start Date : $start_date" >> $LOG_FILE
    echo -e "\t Create Date : $create_date" >> $LOG_FILE
    echo -e "\t Working Directory : $working_dir" >> $LOG_FILE
    echo -e "\t Base Image : $base_image" >> $LOG_FILE
    
    docker kill "$container_id"
        
    
}