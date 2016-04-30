#!/bin/bash

Server='https://matrix.org'

read -p '      Please enter your access token: ' Token
read -p '      Please enter your new password: ' PW1
read -p 'Please enter your new password again: ' PW2

if ! [[ $PW1 == $PW2 ]]; then
    echo "ERROR: NEW Passwords do not match!"
    exit 1
fi

#curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
#  "new_password": "TestPW"
#}' 'http://localhost:8008/_matrix/client/unstable/account/password?access_token=SomeCharsThatMakeUpAnAccessToken'

cat <<-EOF
	This script doesn't work yet.
	It issues the initial change password command but requires additional verification steps that have not been implemented yet.
EOF

Resp=`curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "new_password": "'"$PW"'"
}' "$Server/_matrix/client/unstable/account/password?access_token=$Token" `

jq . <<<$Resp

