#!/bin/bash
##  Written By Anoop Singh from https://www.hostingshades.com/

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

subscription_key="active ultimate"

# Check if running as root  
if ! [ "$(id -u)" = 0 ]; then echo  -e "$BRed This script must be run as sudo or root, try again...$Color_Off"; exit 1; fi

spinner() {
    local pid=$1
    local duration=$2
    local delay=0.1
    local spinstr='|/-\'
    local start_time=$(date +%s)
    local color="\033[32m"  # Green color
    local reset="\033[0m"   # Reset color
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        local elapsed=$(( $(date +%s) - start_time ))
        local minutes=$(( elapsed / 60 ))
        local seconds=$(( elapsed % 60 ))
        printf "${BBlue} [%c] %02d:%02d  " "$spinstr" $minutes $seconds
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    done
    local elapsed=$(( $(date +%s) - start_time ))
    local minutes=$(( elapsed / 60 ))
    local seconds=$(( elapsed % 60 ))
    printf "    \b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\n"
    echo -e "$BYellow Operation completed in $minutes:$seconds. $Color_Off"
}




PRITUNL_CENTOS_7 (){
    # Add the Pritunl repository for centos 7
echo "[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/centos/7/
gpgcheck=1
enabled=1" >/etc/yum.repos.d/pritunl.repo
    
}

PRITUNL_ALMALINUX_9 (){
    # Add the Pritunl repository for Almalinux
echo "[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/oraclelinux/8/
gpgcheck=1
enabled=1" >/etc/yum.repos.d/pritunl.repo

}

MONGODB_CENTOS_7 (){
    #Add the MongoDB repository for Centos 7
echo "[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
" >/etc/yum.repos.d/mongodb-org-5.0.repo

}

MONGODB_ALMALINUX_9 (){
    #Add the MongoDB repository for Almalinux
echo "[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/5.0/x86_64/
gpgcheck=yes
enabled=yes
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
" >/etc/yum.repos.d/mongodb-org-5.0.repo

}

if [ -f /etc/almalinux-release ] && grep -q "AlmaLinux" /etc/almalinux-release >/dev/null; then
    PRITUNL_ALMALINUX_9; MONGODB_ALMALINUX_9;
    
elif [ -f /etc/centos-release ] && grep -q "CentOS" /etc/centos-release >/dev/null; then
    PRITUNL_CENTOS_7; MONGODB_CENTOS_7;
else
    echo -e "$BRed The operating system is not AlmaLinux or CentOS. $Color_Off"
    exit 
fi

echo -e "$BGreen Updating The Packages ... $Color_Off"
yum update -y >/dev/null 2>&1 & spinner $!

echo -e " $BGreen Installation The Packages ... $Color_Off"
yum -y install git epel-release >/dev/null 2>&1 & spinner $!


# Import the Pritunl GPG key
echo -e "$BGreen Downloading EPEL package repository... $Color_Off"
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm  >/dev/null 2>&1 & spinner $!

echo -e "$BGreen Importing Pritunl GPG key... $Color_Off"
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A  >/dev/null 2>&1 & spinner $!
echo -e "$BGreen Importing Pritunl GPG key... Done"

echo -e "$BGreen Importing Pritunl RPM package signing key... $Color_Off"
gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A > key.tmp; sudo rpm --import key.tmp; rm -f key.tmp  >/dev/null 2>&1 & spinner $!
echo -e "$BGreen Importing Pritunl RPM package signing key... Done $Color_Off"

# Install Pritunl
echo -e "$BGreen Installing Pritunl ... $Color_Off"
yum -y install pritunl mongodb-org  >/dev/null 2>&1 & spinner $!


# Start Pritunl
systemctl start mongod pritunl
systemctl enable mongod pritunl

echo -e "$BGreen Installing Pritunl Fake API... $Color_Off"
git clone https://gitlab.simonmicro.de/simonmicro/pritunl-fake-api.git  >/dev/null 2>&1 & spinner $!
cd pritunl-fake-api/server && chmod +x setup.py
python3 setup.py 

# Generate the setup key
setup_key=$(pritunl setup-key)

# Set the MongoDB connection URI
mongo_uri="mongodb://localhost:27017/pritunl"
pritunl set-mongodb $mongo_uri

# Restart the service
systemctl restart pritunl


echo -e "$BCyan Please Go To Browser and run https://your-server-ip  and follow instrucation $Color_Off"
echo -e "$BCyan Your Administrator Default Password $Color_Off"
echo -e "$BCyan Your Subscription Key  is "$subscription_key" $Color_Off"

# Generate The Pritunl Password
echo -e "$BCyan"
pritunl_pass=$(pritunl default-password)
echo -e "$BCyan $pritunl_pass $Color_Off"
