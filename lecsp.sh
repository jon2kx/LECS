#!/bin/bash
# "Linux (RPM based) Environment Compliance Script" by J.Windham (Can be customized for your distro of choice in SSH_Action()
#Debugging option (Uncomment to enable)
#set -x
# We depend on root access to a number of places on the filesystem.
if [[ $EUID != 0 ]]
    then
        printf "%s\n" "Please run as root"
        exit 1
fi
# Determine if tools are available
DependentItem1=`which printf`
DependentItem2=`which ssh`
DependentItem3=`which dialog`
if [[ -z DependentItem1 || -z DependentItem2 || -z DependentItem3 ]]
        then
        printf "%s\n" "Ensure that you have installed $DependentItem1 $DependentItem2 $DependentItem3 using the appropriate package manager for your distribution."
fi
# Let's set our static variables up according to Type:
# Dynamic Variables and User Modifiable Variables are: MadeLikeThis
# Static Variables are: MADELIKETHIS Don't touch these unless you know what you are doing.
ProfileDirectory="/var/environment/profile/"
STDOUTDirectory="/root/Documents/Patching/"
# Let's make sure these exist before we go forward. Other variables will depend on the existance of these key directories'
if [[ -d $ProfileDirectory ]]
    then
        printf "%s\n" "Profile Directory found..."
    else
        printf "%s\n" "Profile Directory not found...Attempting to create directory...(Note you will need to populate the directory with profiles if they do not exist. The same applies to profiles you wish to add."
        MAKEDIR="1"
        if [[ $MAKEDIR -eq 1 ]]
            then
                ExitStatus=$?
                mkdir $ProfileDirectory
                if [[ $ExitStatus -gt 0 ]]
                    then
                        printf "Failed  to Create $ProfileDirectory"
                        exit 1
                else        
                    printf "%s\n" "Created Directory, remember to populate"
                fi
        fi      
fi
# Now the same for the standard output directory.
if [[ -d $STDOUTDirectory ]]
    then
        printf "%s\n" "STDOUT Directory found..."
    else
        printf "%s\n" "STDOUT Directory not found...Attempting to create directory..."
        STDOUTDIR="1"
        if [[ $STDOUTDIR -eq 1 ]]
            then
                ExitStatus=$?
                mkdir $STDOUTDirectory
                if [[ $ExitStatus -gt 0 ]]
                    then
                        printf "Failed  to Create $ProfileDirectory"
                        exit 1
                else        
                    printf "%s\n" "Created Directory."
                fi
        fi       

fi
# We continue from this point, to load variables, this has to be procedural, since I am dynamically generation options and case based on present files in a directory. 
PubKeyDir="/root/.ssh/"
PubKey="mykey"
SSHUID="centos"
HEIGHT=15
WIDTH=80
CHOICE_HEIGHT=20
BACKTITLE="Customer Check Update"
TITLE="Choose a Client environment and Stack"
MENU="Choose one of the following options:"
CUSTENVPatchEvalFile="/var/run/CUSTENVpatcheval"
CUSTENVPatchEvalFileOpt="/var/run/CUSTENVpatchopt"
OptStartCount=1
OptEndCount=`ls -l $ProfileDirectory | sed '1d' | wc -l`
OptValues=`ls -l $ProfileDirectory | awk {'print $9'}`
#Let's construct an unholy for loop to load in all the stuff in the profile directory as options to be passed along to dialog, dynamically. Beware, we are using C Syntax for some of the loops, as well as printf from C. 
if [[ -r $CUSTENVPatchEvalFile ]]
    then
        >$CUSTENVPatchEvalFile
        printf "OPTIONS=(" > $CUSTENVPatchEvalFile
    else
        touch $CUSTENVPatchEvalFile
        printf "OPTIONS=(" >> $CUSTENVPatchEvalFile
fi

for (( c=$OptStartCount; c<=$OptEndCount; c++ ))
    do
        LineByValue=`printf "%s\n" "$OptValues" | sed 1d | sed 's/^/'"$c"' "/' `
        CurrentLine=`printf "%s\n" "$LineByValue" | sed -n $c\p`
        printf "%s\n" "$CurrentLine\"" >> $CUSTENVPatchEvalFile
done

printf "%s\n" ")" >> $CUSTENVPatchEvalFile
source $CUSTENVPatchEvalFile

#Let's construct another unholy for loop to add options for case, dynamically, to be selected by CHOICE and to set up for the profile to be read. Again C Syntax here, folks.
if [[ -r $CUSTENVPatchEvalFileOpt ]]
    then
    >$CUSTENVPatchEvalFileOpt
                touch $CUSTENVPatchEvalFileOpt
                printf "%s\n" "case \$CHOICE in" "" > $CUSTENVPatchEvalFileOpt         
    else
    touch $CUSTENVPatchEvalFileOpt
    printf "%s\n" "case \$CHOICE in" "" > $CUSTENVPatchEvalFileOpt
fi

for (( c=$OptStartCount; c<=$OptEndCount; c++ ))
    do
    LineByValue2=`printf "%s\n" "$OptValues" | sed 1d`
    CurrentLine=2`printf "%s\n" "$LineByValue2" | sed -n $c\p`
    printf "%s\n" "       $c)" >> $CUSTENVPatchEvalFileOpt
    printf "%s\n" "           printf \"$CurrentLine2 selected\"" >> $CUSTENVPatchEvalFileOpt
#    printf "%s\n" "           SelectedProfile=$c" >> $CUSTENVPatchEvalFileOpt (This is currently bugged, but will be fixed in the next release.)
    printf "%s\n" "           ;;" >> $CUSTENVPatchEvalFileOpt
done

printf "%s\n" "       h)" >> $CUSTENVPatchEvalFileOpt
printf "%s\n" "            printf \"Environment Scanner requires no arguments: Execute and follow on screen prompts.\""
printf "%s\n" "            ;;" >> $CUSTENVPatchEvalFileOpt
printf "%s\n" "esac" >> $CUSTENVPatchEvalFileOpt
#Souce our painfully constructed file for use in CASE
source $CUSTENVPatchEvalFileOpt

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)
clear
# Functions ( I wanted to functionize everything, because why not, but in reality, we don't even need them. We are not reusing, well, anything really. At anyrate this is version 1.0, and I have a deadline to grab basic info for a ton of hosts.)
Read_Profile() {
    if [[ -z $CHOICE ]]
        then
            printf "%s\n" "No choice made, nothing to do, exiting..."
            exit 1
        else
            LineByValue3=`printf "%s\n" "$OptValues" | sed 1d`
            ChosenOne=`printf "%s\n" "$LineByValue3" | sed -n $CHOICE\p`
#               if [[ $SelectedProfile == $CHOICE ]] (Something is currenty broken upon sourcing CASE. We are working around it with CHOICE)
#                   then
#                       printf "%s\n" "Sourcing profile from directory..."
#                       source $ProfileDirectory$ChosenOne
#                       else
#                       exit 1 
#                       printf "%s\n" "Something is not right in CHOICE or Selected Protocol: send this error to jonathan.windham@fostermoore.com or another proficient Linux sysadmin that you trust."
#               fi
    printf "%s\n" "Sourcing profile from directory..."
    source $ProfileDirectory$ChosenOne
    fi
    printf "Moving to contact hosts..."
}
SSH_Action() {

    for i in $CUSTHOSTS; do ssh -oStrictHostKeyChecking=no -i $PubKeyDir$PubKey $SSHUID@$i.$ENV.$CLIENT.$FQDN ' printf "%s\n" "##### Hostname Kernel Distribution and Release Information #####" && uname -a && cat /etc/redhat-release && printf "%s\n" "##### Customer Environmental Core Utilities #####" && rpm -qa "glibc"\|"openssl"\|"nginx"\|"haproxy"\|"jboss"\|"elasticsearch"\|"salt"\|"logstash"\|"clamav"\|"centos-release"\|"newrelic" && java -version && printf "%s\n" "##### Available Security Updates for System #####" && yum makecache fast && yum --security check-update && printf "%s\n" "##### Available Bugzilla updates (Bugfixes)" && yum updateinfo list bugzillas && printf "%s\n" "##### Available CVE (Critical Vulnerabilities) updates #####" && yum updateinfo list cves && printf "%s\n" "##### All packages marked for update by repository and package maintainers #####" && yum makecache fast && yum check-update '; done 2>&1 | tee -a $STDOUTDirectory$CLIENT.$ENV
}
# Logical operators
Read_Profile
SSH_Action