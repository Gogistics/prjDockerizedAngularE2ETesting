#!/bin/bash
# 
# Program:
# Do dockerized e2e testing inside Docker container
# Author:
# Alan Tai
# History:
# 04/06/2017
# Note:
# Please follow Google Shell Style Guide of Shell/Bash

############################################
# Global varialbles
############################################
OPT=""
URL=""
TARGET_URL=""
APP_IMAGE=""
APP_CONTAINER=""
NO_ARGS=0 
E_OPTERROR=85


############################################
# Set environment variables
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
############################################
set_env_variables () {
  # export env. variables
  source ./scripts/environment_variables
}


############################################
# Check whether user pass valid url    
# Globals:
#   None
# Arguments:
#   -u
#   url (EX: https://github.com)
# Returns:
#   None
############################################
check_if_user_pass_valid_url () {
  # check if users pass -u and the corresponding value which is a url
  if [[ $# -eq "$NO_ARGS" ]]  # Script invoked with no command-line args?
  then
    echo "Usage: `basename $0` options (-u)" >&2
    exit $E_OPTERROR          # Exit and explain usage.
                              # Usage: scriptname -options
                              # Note: dash (-) necessary
  fi

  # read arguments (option and the corresponding value)
  while getopts u: option;
  do
    case "${option}" in
      u) u_arg="$OPTARG"
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

        # check if the url start with http because angular-cli/protractor doesn't recognize it
        local url_prefix="http"
        if [[ $u_arg != $url_prefix* ]]; then
          echo "Please specify the url prefix (http or https)" >&2
          exit $E_OPTERROR
        fi

        curl -sk --head  --request GET $u_arg | grep -E "302 Found|200 OK" > /dev/null
        if [[ $? -eq 0 ]]; then
          TARGET_URL=$u_arg
        else
          echo ERROR: "The given url is invalid or the web server is down!" >&2
          exit $E_OPTERROR
        fi
      ;;
      *)
        echo ERROR: "Invalid value for option -u" >&2
        exit $E_OPTERROR
    esac
  done
}


############################################
# Create Docker image and container
# Globals:
#   None
# Arguments:
#   -u
#   URL (EX: https://github.com)
# Returns:
#   None
############################################
create_docker_img_container () {
  # create image if not exist
  local app_image="$IMG_NAME:$IMG_VERSION"
  APP_IMAGE=$app_image

  local inspect_result=$(docker inspect $app_image)

  if [[ "[]" == "$inspect_result" ]]; then
    echo "Docker image, $app_image, not exist and a new one will be created"
    docker build -t ${app_image} .
  else
    echo "Docker image, $app_image, already exist"
  fi

  # create container if not exist
  local app_container="$CONTAINER_NAME"
  APP_CONTAINER=$app_container

  local inspect_result=$(docker inspect $app_container)

  if [[ "[]" == "$inspect_result" ]]; then
    echo "Container not exist and a new one will be created for e2e testing"
  else
    echo "Container exist and ready for e2e testing"
  fi
}


############################################
# Check whether e2e/ exists
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
############################################
check_if_e2e_folder_exist () {
  # make sure e2e/ exist; exit program if not exist
  local e2e_dir="$PWD/e2e/"
  if [[ "$(ls -A $e2e_dir)" ]]; then
    echo "$e2e_dir exists and ready for e2e testing"
  else
    exit "$e2e_dir not exists or is empty!"
  fi
}


############################################
# Do e2e functional testing
# Globals:
#   None
# Arguments:
#   TARGET_URL
#   APP_IMAGE
#   APP_CONTAINER
# Returns:
#   None
############################################
do_e2e_testing () {
  # spin up a docker container for e2e testing
  # 1. change directory to /app/
  # 2. set environment variables
  # 3. start to do e2e testing
  set -e

  # set variables
  local valid_target_url=$1
  local app_image=$2
  local app_container=$3
  local commands=(
    "cd /app/ && "
    "export TARGET_TESTING_SITE=$valid_target_url && "
    "ng e2e --serve false"
  )
  docker run \
    --name ${app_container} \
    -v ${PWD}/e2e/:/app/e2e-testing/ \
    --rm ${app_image} \
    sh -c "${commands[*]}"
}


############################################
# Remove Docker volumes
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
############################################
clean_up_docker_volumes () {
  # clean up docker volumes; this part can be put in a function
  docker run \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker:/var/lib/docker \
    --rm martin/docker-cleanup-volumes
}


############################################
# Go through all steps
############################################

# read option & the corresponding value
OPT=$1
URL=$2

# set environment variable
echo "Set environment variables..."
set_env_variables &&
echo "↓" &&

echo "Get url of the testing site..." &&
check_if_user_pass_valid_url $OPT $URL &&
echo "↓" &&

echo "Create the docker image and the corresponding container"
create_docker_img_container &&
echo "↓" &&

echo "Check if e2e/ exists"
check_if_e2e_folder_exist &&
echo "↓" &&

echo "Start to do e2e testing..." &&
do_e2e_testing $TARGET_URL $APP_IMAGE $APP_CONTAINER &&
echo "↓" &&

echo "Clean up Docker volumes..." &&
clean_up_docker_volumes
