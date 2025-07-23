#!/usr/bin/env zsh

LOG_FILE="$HOME/docker_dameon.txt"

dangle()
{
    local container_id=$1
    
    tmp=0
    
    connections=$(docker exec "$container_id" netstat -an | grep "ESTABLISHED" | wc -l)
    cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container_id" | sed 's/%//' || echo "0")

    if [[ -z "$cpu_usage" ]] || [[ -z "$connections" ]] || [[ -z "$container_id" ]]; then
        tmp=2
    fi

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

network_container() {
    container_id=$1
    networks=($(docker inspect --format='{{range $net, $conf := .NetworkSettings.Networks}}{{if ne $net "bridge"}}{{$net}} {{end}}{{end}}' "$container_id"))
    if [[ ${#networks[@]} -eq 0 ]]; then
        return
    fi

    related_cont=()
    related_cont+=("$container_id")
    for i in "${networks[@]}"; do
        cont_network=($(docker network inspect "$i" --format='{{range .Containers}}{{.Name}} {{end}}'))
        for j in "${cont_network[@]}"; do
            if [[ "$j" != "$container_id" ]]; then
                related_cont+=("$j")
            fi
        done
    done
    printf '%s\n' "${related_cont[@]}" | sort -u
}

while True; do 
{
    
    today=$(date +%Y-%m-%d)
    timestamp1=$(date -d "$today" +%s)
    
    list_of_containers=$(docker ps --format '{{.Names}}' | wc -l)
    cont_threshold=$((list_of_containers/2))
    stop_cont=()
    
    IFS=$'\n' arr=($(docker ps --format '{{.Names}}')); unset IFS
    for i in "${arr[@]}"; do
        if [[ " ${stop_cont[*]} " =~ " $i " ]]; then
            continue
        fi
        cont_id="$i"
        
        date=$(docker inspect --format='{{.State.StartedAt}}' "$cont_id" | sed 's/T.*//')
        timestamp2=$(date -d "$date" +%s)
        count=1
        difference_seconds=$((timestamp1 - timestamp2))
        #get difference in seconds and check if it is ge 1 month.
            
        if [[ $difference_seconds -ge 2592000 ]]
        then
            dangle "$cont_id" count
        fi
        if [[ $count -eq 0 ]]
        then
            network_array=($(network_container "$cont_id"))
            for key in "${network_array[@]}"; do
                stop_cont+=("$key")
            done
        fi
        
    done
    rem_cont=($(printf '%s\n' "${stop_cont[@]}" | sort -u))
    if [[ ${#rem_cont[@]} -eq 0 ]]; then
        :
    elif [[ ${#rem_cont[@]} -ge $cont_threshold ]]; then
        :
    else
        for key in "${rem_cont[@]}"; do
            stopnlog "$key"
        done
    fi
    sleep 100
    
}
done
