#!/bin/bash
# Program:
# Do dockerized e2e testing inside Docker container
# Author:
# Alan Tai
# History:
# 04/06/2017

# export env. variables
source ./scripts/environment_variables

NO_ARGS=0 
E_OPTERROR=85

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-u)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi

TARGET_TESTING_SITE=""
while getopts u: option;
do
  case "${option}" in
    u) u_arg="$OPTARG"
      echo "check whether website, $u_arg, is live or not"
      # Current Response:
      # HTTP/1.1 302 FOUND
      # Date: Mon, 10 Apr 2017 02:42:05 GMT
      # Server: Apache
      # Vary: Cookie,User-Agent
      # X-Frame-Options: SAMEORIGIN
      # X-UA-Compatible: IE=edge
      # Set-Cookie: _rbt_login_message=notFound; httponly; Path=/
      # Set-Cookie: sessionid=ced433ef37ef0b8414634965091a0ce1; expires=Thu, 01-Jan-1970 00:00:00 GMT; httponly; Max-Age=0; Path=/
      # Location: http://main-vva9.lab.nbttech.com/login?next=/
      # Content-Length: 0
      # Content-Type: text/html; charset=utf-8
      curl -sk --head  --request GET $u_arg | grep -E "302 FOUND|200 OK" > /dev/null && \
      curl -sk --head --request GET $u_arg | grep -E "302 FOUND|200 OK" > /dev/null

      if [ $? -eq 0 ]; then
        echo "website is up and ready for testing"
        TARGET_TESTING_SITE=$u_arg
      else
        echo ERROR: "The given url is invalid or the web server is down!"
        exit 0
      fi
    ;;
    *)
      echo ERROR: "Invalid value for option -u"
      exit 0
  esac
done

# create image if not exist
app_image="$IMG_NAME:$IMG_VERSION"
inspect_result=$(docker inspect $app_image)

if [[ "[]" == "$inspect_result" ]]; then
  echo "Docker image, $app_image, not exist and a new one will be created"
  docker build -t ${app_image} .
else
  echo "Docker image, $app_image, already exist"
fi

# create container if not exist
app_container="$CONTAINER_NAME"
inspect_result=$(docker inspect $app_container)

if [[ "[]" == "$inspect_result" ]]; then
  echo "Container not exist and a new one will be created for e2e testing"
else
  echo "Container exist and ready for e2e testing"
fi

# Make sure e2e/ exist
e2e_dir="$PWD/e2e/"
if [[ "$(ls -A $e2e_dir)" ]]; then
  echo "$e2e_dir exists and ready for e2e testing"
  echo "↓"
else
  exit "$e2e_dir not exists or is empty!"
fi

# spin up a docker container
commands=(
  "cd /app/ && "
  "export TARGET_TESTING_SITE=$TARGET_TESTING_SITE && "
  "ng e2e --serve false"
)
docker run \
  --name ${app_container} \
  -v ${PWD}/e2e/:/app/e2e-testing/ \
  --rm ${app_image} \
  sh -c "${commands[*]}"

# Clean up docker volumes; this part can be put in a function
echo "Clean up Docker volumes..."
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker:/var/lib/docker \
  --rm martin/docker-cleanup-volumes