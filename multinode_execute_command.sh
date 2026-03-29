#!/usr/bin/bash

IFS=$IFS,
declare -A mydict

function usage()
{
    echo "Usage: $0 [<command> <VM IP List file>|help]"
}

while getopts i:f:v:p:c:r:h OPTION
do
    case $OPTION in
        i)  IP="$OPTARG"
            if [ -n "$IP" ]; then
                if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                    vm_ip_list+=($IP) #Add command line arguments IP to list
                fi
            fi
        ;;
        f) InvFile="$OPTARG"
            if [ -n "$InvFile" ]; then 
                for i in $(cat "$InvFile")
                do
                            if  [[ "$i" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                                    vm_ip_list+=($i) #Add contents of file to list
                            elif
                                [[ "$i" =~ ^VSDL(DA|EL|NV)([0-9][0-9]|LK)[0-9][0-9][a-zA-Z]{2}[0-9]{3}$ ]]; then
                                vmList+=($i) #Add command line arguments vm to list
                            fi
                done
            fi
        ;;
        p) root_password="$OPTARG" ;;
        c) command_to_execute="$OPTARG" ;;
        v) VM="$OPTARG" 
            if [ -n "$VM" ]; then
                VM=$(echo $VM | tr -s [a-z] [A-Z])
                if [[ "$VM" =~ ^VSDL(DA|EL|NV)([0-9][0-9]|LK)[0-9][0-9][a-zA-Z]{2}[0-9]{3}$ ]]; then
                    vmList+=($VM) #Add command line arguments IP to list
                #elif [[ "$VM" =~ ^VSDL(DA|EL|NV)([0-9][0-9]|LK)[0-9][0-9][a-zA-Z]{2}[0-9]{0,2}$ ]]; then
                #    vmList+=($(grep $VM SG_Inventory.txt| awk '{print $1}'))
                #else
                #    echo "No VM matched"
                fi
            fi
        ;;
        r) vm_range="$OPTARG"
            if [ -n "$vm_range" ]; then
                vm_range=$(echo $vm_range | tr -s [a-z] [A-Z])
                if [[ "$vm_range" =~ ^VSDL(DA|EL|NV)([0-9][0-9]|LK)[0-9][0-9][a-zA-Z]{2}[0-9]{0,2}$ ]]; then
                    vmList+=($(grep $vm_range SG_Inventory.txt| awk '{print $1}'))
                else
                    echo "No VM matched"
                fi
            fi
        ;;
        h) echo "$USAGE"
            exit 0 ;;
        \?) echo "$USAGE"
            echo "Your input is incorrect, see usage !"
            exit 1 ;;
    esac
done

TheList=("${vm_ip_list[@]}" "${vmList[@]}")

vm_ip=()

for vm in "${TheList[@]}"
do
    while IFS= read -r line
    do
        vm_ip+=("$line")
    done < <(grep -w "$vm" /home/adm_cfagan/SG_Inventory.txt)
done


for line in "${vm_ip[@]}"
do
    read -r vm ip <<< "$line"
    mydict["$ip"]="$vm"
done

function main() {
    vm_count=${#vm_ip[@]}

    for vm_ip in "${!mydict[@]}";
    do
        if [ ! -z "${vm_ip}" ]; then
            echo "Executing command: '$command_to_execute' in [${mydict[$vm_ip]}] [$vm_ip]"
            print_name_and_execute "$vm_ip" "$command_to_execute" &
        fi
    done

    wait   
}

function print_name_and_execute()
{
        command_to_execute=$2
        vm_ip=$1
        OUT=`sshpass -p $root_password ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$vm_ip "$command_to_execute"`
        echo "[$vm_ip] [${mydict[$vm_ip]}] $OUT"

}

main
#for key in "${mydict[@]}"; do
#    echo "$key"
#done

