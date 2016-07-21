#!/bin/sh

ul=`tput smul`
noul=`tput rmul`
b=`tput bold`
nob=`tput sgr0`

FORCE=0
TIMEOUT=30

NEWSET=""
OLDSET=""

FWTOOL=""

abort(){
    screen -S fwloader -X kill
    echo Aborted by user.
    exit 0
}

verify (){
    # Check if new rulset exists
    if [ "$NEWSET" = "" ]
    then
        echo You need to specify new ruleset to apply
        usage
        exit 1
    fi

    # Check if new rulset is executable
    if ! [ -x "$(command -v $NEWSET)" ]
    then
        echo New ruleset is not executable file: $NEWSET
        exit 1
    fi

    # Check if backup ruleset exists
    if [ "$OLDSET" = "" ]
    then
        # If not specified, check if we have fallback fw tool specified and available
        case $FWTOOL in
            iptables)
                if ! [ "$(command -v iptables)" ]
                then
                    echo "You chose iptables as fallback tool but it doesn't seem to be available on your system."
                    exit 1
                else
                    OLDSET="iptables -F"
                fi
                break
                ;;
            ipfw)
                if ! [ "$(command -v ipfw)" ]
                then
                    echo "You chose ipfw as fallback tool but it doesn't seem to be available on your system."
                    exit 1
                else
                    OLDSET="ipfw -q -f flush;ipfw -q add allow all from any to any"
                fi
                break
                ;;
            pf)
                if ! [ "$(command -v pfctl)" ]
                then
                    echo "You chose pf as fallback tool but it doesn't seem to be available on your system."
                    exit 1
                else
                    OLDSET="pfctl -F all"
                fi
                break
                ;;
            ipfilter)
                if ! [ "$(command -v ipf)" ]
                then
                    echo "You chose ipfilter as fallback tool but it doesn't seem to be available on your system."
                    exit 1
                else
                    OLDSET="ipf -Fa"
                fi
                break
                ;;
            *)
                echo "You didn't specified niether script with backup rules, nor supported firewall tool (using -m argument). For more info please see usage."
                usage
                exit 1;
        esac
        # We warn user that as a backup plan we will open firewall wide open
        echo "${b}Warning:${nob} you did not specify backup ruleset which means that we will use $FWTOOL to open you firewall wide open in case something goes wrong. This will leave you potentialy exposed until you manually apply new firewall rules"
        echo -n "Are you OK with it?[Y/n]: "
        read -r CONFIRM
        case $CONFIRM in
            Y | y)
                break
                ;;
            N | n)
                exit 1
                ;;
            *)
                exit 1
                ;;
        esac
    else
        # Check if backup rulset is executable
        if ! [ -x "$(command -v $OLDSET)" ]
        then
            echo "Backup ruleset is not executable file: $OLDSET"
            exit 1
        fi
    fi
    
    # Check if NEWSET and OLDSET are different files
    if [ "$NEWSET" = "$OLDSET" ]
    then
        echo "${b}Warning:${nob} You selected same script for both main and backup rules. This successfuly defeats purpose of this script."
        echo -n "Do you want to continue anyway?[Y/n]: "
        read -r CONFIRM
        case $CONFIRM in
            Y | y)
                break
                ;;
            N | n)
                exit 1
                ;;
            *)
                exit 1
                ;;
        esac
    fi
}

run (){
    echo "Fwloader starting...\nGoing to apply new rules from \"$NEWSET\"\nIf you are didnt lock yourself out (i.e. You see countdown steadily ticking dow), send SIGINT signal (usually ^C) to interupt this program."
    screen -d -m -S fwloader bash -c "sleep $TIMEOUT;$OLDSET"
    $NEWSET
    for i in $(seq $TIMEOUT -1 0); do sleep 1;printf "Countdown:  $i seconds\033[K\r"; done
    echo "Backup rules applied"
}

usage (){
    echo "fwloader is script designed to safely test new firewall ruleset that could potentialy 
lock you out of remote access. It applies ${b}NEW_RULES${nob} and waits (by default) 30 seconds,
if it's not canceled by user within this period it will reload ${b}OLD_RULES${nob}. You can cancel
this script by issuing SIGINT (usualy ^C).

Usage: fwloader [OPTIONS] -i NEW_RULES [-o OLD_RULES]

ARGUMENTS:
    -i ${ul}FILE${noul}     Executable script file that contains new firewall ruleset
    -o ${ul}FILE${noul}     Executable script file that contains backup ruleset that will be aplied
                if this program is not interupted within specified timeout. If this argument is not
                specified, program will try to set default permissive rule. ${b}WARNING:${nob} This 
                will leave your system exposed.

OPTIONS:
    -f      Dont't ask stupid questions and run
    -t ${ul}t${noul}    Wait ${ul}t${noul} seconds before running ${b}OLD_RULES${nob}
    -m ${ul}fw${noul}   If no ${b}OLD_RULES${nob} is specified, this option needs to be set to tell program which
            firewal tool ${ul}fw${noul} it should ue to set default permissive rule. Supoprted firewall tools
            are: iptables, ipfw, pf, ipfilter
    -h      Print this help

"
}

while getopts "hfm:t:i:o:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        f)
            FORCE=1
            ;;
        t)
            TIMEOUT=$OPTARG
            ;;
        i)
            NEWSET=$OPTARG
            ;;
        o)
            OLDSET=$OPTARG
            ;;
        m)
            FWTOOL=$OPTARG
            ;;
        '?')
            usage
            exit 1
            ;;
    esac
done

trap abort 2
verify
run
