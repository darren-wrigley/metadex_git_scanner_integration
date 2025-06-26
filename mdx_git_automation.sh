#!/bin/sh

usage() {
    echo "Usage: $0 mdx_project mdx_configuration git_folder [testmode]"
    exit 1
}

is_metadex_running() {
    # check if processes are running 
    echo "step 2: checking metadex is running"

    #echo "    checking pids for metadex ps -eo pid,command | grep $SCANNERS_HOME | grep -v grep | awk '{print $1}'"
    mdx_pids="$(ps -eo pid,command | grep $SCANNERS_HOME | grep -v grep | awk '{print $1}')"
    # echo "metadex processes=$mdx_pids"
    if [[ -z "$mdx_pids" ]]
    then
	 echo "     failed: mdx is not running"
     	 return 1
    else
        echo "    success: mdx is running"
	return 0
    fi
}

check_mdx_config() {
    # check mdx project and config names are valie
    echo "step 3: checking mdx config - project=$mdx_project config=$mdx_config"
    mdx_configs="$($SCANNERS_HOME/bin/scanners-cli.sh show project $mdx_project | grep $mdx_config)"
    #echo "mdx_configs=$mdx_configs"
    if [[ "$mdx_configs" == "$mdx_config" ]]; then
        echo "    success: config $mdx_config is valid"
	return 0
    else
        echo "    failed: config $mdx_config is not found for projecgt $mdx_project"
	return 1
    fi
}

ok_to_scan() {
    # check if scan is queued or running, if running return false (1) otherwise 0 (true)
    echo "step 4: checking for running/queued scan project=$mdx_project config=$mdx_config"
    jobs="$($INFA_HOME/services/CatalogService/AdvancedScannersApplication/app/bin/scanners-cli.sh processings list  | grep Project:\ $mdx_project | grep Configuration:\ $mdx_config)"

    #echo $jobs
    if [[ $jobs ]]; then
        echo "    failed: metaadex job is running - try later"
	return 1
    else
        echo "    success: no scan is running for $mdx_project/$mdx_config"
	return 0
    fi
}


start_mdx_scan() {
    # start scan - all checks complete
    echo "step 6: starting metadex scan project=$mdx_project config=$mdx_config"
    job="$($SCANNERS_HOME/bin/scanners-cli.sh run $mdx_project/$mdx_config | grep 'Job\ scheduled:')"

    #echo "    scan started:$job"
    if [[ $jobs ]]; then
        echo "    failed: scan could not start"
        return 1
    else
        echo "    success: scan submitted running for $mdx_project/$mdx_config"
	echo "    $job"
        return 0
    fi
}

is_git_updated() {
    # check git folder is valid, and run fetch/status
    # if status shows local branch is behind - process can continue otherwise nothing to do
    echo "step 1: checking git fetch/status in $git_folder"
    if [ -d $git_folder ]; then
        echo "    git repo folder exists. $git_folder"
    else
	echo "    error: git folder does not exist. $git_folder"
	exit 1
    fi

    current_dir=$(pwd)
    cd $git_folder
    git fetch --quiet
    git_status=$(git status)
    #echo "    git status output==$git_status"
    cd ${current_dir}

    if [[ $git_status =~ "branch is behind" ]]; then
        echo "    success: git status shows updates"
        #git pull --quiet
        #echo "  success: git repository updated"
        return 0
    else
        echo "    no changes to git repository upstream, exiting"
        return 1
    fi
}

update_git_repo() {
    # sync local git files with upstream repo
    echo "step 5: updating git repos in $git_folder"
    current_dir=$(pwd)
    cd $git_folder
    echo "    executing git pull ${current_dir}"
    if git pull --quiet ;
    then
        echo "    success: git repository updated"
        return 0
    else
        echo "    error: git pull failed"
        return 1
    fi
}

# script processing starts here
if [ "$#" -lt 3 ]
then
  echo "Incorrect number of arguments"
  usage
fi

# store parameters passed
mdx_project=$1
mdx_config=$2
git_folder=$3
echo "parameters:  Project=$mdx_project Config=$mdx_config Folder=$git_folder"

# assumptions
# INFA_HOME is set
# METADEX_URL is set (or add -s=<metadex url with port)
# METADEX_USER is set (or add -u-<username>)
# METADEX_PASSWORD is set (or add -p=<encrypted password> $INFA_HOME/services/CatalogService/AdvancedScannersApplication/app/encrypt.sh"
# METADEX_SECURITY_DOMAIN is set (or add -d=<security domain>)
SCANNERS_HOME=$INFA_HOME/services/CatalogService/AdvancedScannersApplication/app

echo "variables in use"
echo "  INFA_HOME=$INFA_HOME"
echo "  SCANNERS_HOME=$SCANNERS_HOME"
echo "  METADEX_URL=$METADEX_URL"
echo "  METADEX_USER=$METADEX_USER"
echo "  METADEX_SECURITY_DOMAIN=$METADEX_SECURITY_DOMAIN"


if (is_git_updated && is_metadex_running && check_mdx_config && ok_to_scan && update_git_repo && start_mdx_scan)
then
    echo "success: files have been updated, mdx scan started"
else
    echo "no changes to files in git repo, or error running scan"
fi

