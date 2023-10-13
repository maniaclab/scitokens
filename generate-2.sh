#!/bin/bash
help() {
  echo "Usage: ./generate.sh <username> <groupname> <lifetime>"
  echo "-h, --help    Print this help message."
  echo <username> Unix user name
  echo <grpname> Unix group name
  echo <lifetime> in seconds  Can not exceed 28800 seconds
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  help
  exit 0
fi

if [ $# -ne 3 ]; then
  echo "Requires 3 arguments"
  exit 0
fi

usrname=$1
grpname=$2
lifetime=$3

##
## Do some checks of whether the user group name combination is valid
##

## Check lifetime
if (( $3 > 28800 )) ; then
    echo lifetime too long

    echo Setting lifetime to maximum
    lifetime=28800
fi

echo Generating Scitoken for Username: $usrname in Group: $grpname with lifetime: $lifetime seconds
rm -rf +i access_token ## Delete previous access_token
rm -rf +i access_token.tmp
ccv=condor_config_val
scope=$($ccv LOCAL_CREDMON_AUTHZ_GROUP_TEMPLATE | sed "s#[{]groupname[}]#$grpname#g")
sudo ./scitokens-admin-create-token.py \
     --keyfile "$($ccv LOCAL_CREDMON_PRIVATE_KEY)" \
     --key_id "$($ccv LOCAL_CREDMON_KEY_ID)" \
     --issuer "$($ccv LOCAL_CREDMON_ISSUER)" \
     --lifetime $lifetime \
     "aud=$($ccv LOCAL_CREDMON_TOKEN_AUDIENCE)" \
     "sub=$usrname" \
     "scope=$scope" \
     "ver=$($ccv LOCAL_CREDMON_TOKEN_VERSION)" > access_token.tmp
httokendecode access_token.tmp
tok=`cat access_token.tmp`
echo -n '{"access_token":' '"'$tok'",' '"expires_in":' $lifetime} > access_token
cat access_token
rm -rf +i /home/$usrname/access_token
mv access_token /home/$usrname/.
chown $usrname /home/$usrname/access_token
chgrp collab.$grpname /home/$usrname/access_token
chmod 400 /home/$usrname/access_token
