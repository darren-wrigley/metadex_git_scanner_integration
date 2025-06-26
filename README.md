# Metadex file scanner automation with git repository
example script to use a git repository (github, bitbucket, gitlab, ...) to identify new/updated/deleted files and call metadex scan when changes have been committed

# Disclaimer
the script can be used as-is or modified to suit your environment. 
it is not supported by informatica GCS.

# Usage
`./mdx_git_automation.sh <metadex_project> <metadex_configuration> <git_folder>`

# Process Outline
each process must be successful (produce the expected result) or the script will exit
1. check if local git repo needs to be updated from upstream repo (git fetch and git status)
2. check if metadex is running
3. check if configuration exists for project
4. check if scan for project/config is already queued/running
5. update git repository (git pull)
6. execute scan


# Assumptions/Configuration needed
- metadex & git repository hosted on machine that script is run
- local git repository exists via any git app (github, bitbucket, gitlab)
- local git clone should be clean (not used to update & commit) & the branch set is the branch to use for detecting updates (e.g. main)
- metadex project and configuration has been created to scan files in local git repository
- script can be scheduled to run at any time (not part of the script itself)
- Environment variables should be set:<br/>see https://docs.informatica.com/data-catalog/enterprise-data-catalog/10-5-8/metadex-scanner-administrator-guide/appendix-d--scanners-cli-utility/configurations-parameters-set.html
  - INFA_HOME
  - SCANNERS_URL - url for metadex ui, with port
  - SCANNERS_USER
  - SCANNERS_PASSWORD (use $INFA_HOME/services/CatalogService/AdvancedScannersApplication/app/encrypt.sh to create encrypted password)
  - SCANNERS_SECURITY_DOMAIN (Native, Metadex, or LDAP Security Domain)

   
   
# git commands used

- `git fetch` - will sync commits from master repository to local (does not update local branch), can use with git status (after fetch)
- `git status` - will tell if branch in origin is behind local.  if git status does not return anything, there is need to start scan in metadex
  ```
  git status
  On branch main
  Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
    (use "git pull" to update your local branch)
  ```
- `git pull --quiet` - update local branch from upstream (new & updated files will be in local file system)

# Metadex commands used
- check if metadex processes are running<br/>
  `ps -eo pid,command | grep $SCANNERS_HOME | grep -v grep | awk '{print $1}'`
- check if metadex project/configuration exist<br/>
  `$SCANNERS_HOME/bin/scanners-cli.sh show project ${mdx_project} | grep ${mdx_config}`
- check if metadex scanner is queued/running<br/>
  `$INFA_HOME/services/CatalogService/AdvancedScannersApplication/app/bin/scanners-cli.sh processings list  | grep Project:\ $mdx_project | grep Configuration:\ $mdx_config)`
- start metadex scan<br/>
  `$SCANNERS_HOME/bin/scanners-cli.sh run $mdx_project/$mdx_config`

# Questions

- is it enough to detect any changes using git status?   or check for new .sql files only (e.g. if non-scanned files are updated - could trigger a scan with no changes)
  - assumption for now, yes this is enough (any updates like direct commit, or pull request should trigger the process)
 
  
# Examples

## Example 1: changed files, metadex scan started
```
./mdx_git_automation.sh SQL_Script_automation script_scan_sqlserver /data/git/mdx_sql_script_automation
parameters:  Project=SQL_Script_automation Config=script_scan_sqlserver Folder=/data/git/mdx_sql_script_automation
variables in use
  INFA_HOME=/data/informatica/CURRENT
  SCANNERS_HOME=/data/informatica/CURRENT/services/CatalogService/AdvancedScannersApplication/app
  SCANNERS_URL=https://asvedcpmtest01.informatica.com:48090
  SCANNERS_USER=admin
  SCANNERS_SECURITY_DOMAIN=Native
step 1: checking git fetch/status in /data/git/mdx_sql_script_automation
    git repo folder exists. /data/git/mdx_sql_script_automation
    success: git status shows updates
step 2: checking metadex is running
    success: mdx is running
step 3: checking mdx config - project=SQL_Script_automation config=script_scan_sqlserver
    success: config script_scan_sqlserver is valid
step 4: checking for running/queued scan project=SQL_Script_automation config=script_scan_sqlserver
    success: no scan is running for SQL_Script_automation/script_scan_sqlserver
step 5: updating git repos in /data/git/mdx_sql_script_automation
    executing git pull /data/git/metadex_git_scanner_integration
    success: git repository updated
step 6: starting metadex scan project=SQL_Script_automation config=script_scan_sqlserver
    success: scan submitted running for SQL_Script_automation/script_scan_sqlserver
    Job scheduled: {name: "["SQL_Script_automation","script_scan_sqlserver"]", id : 34403}
success: files have been updated, mdx scan started
```

## Example 2:  no changes in git repository
```
./mdx_git_automation.sh SQL_Script_automation script_scan_sqlserver /data/git/mdx_sql_script_automation
parameters:  Project=SQL_Script_automation Config=script_scan_sqlserver Folder=/data/git/mdx_sql_script_automation
variables in use
  INFA_HOME=/data/informatica/CURRENT
  SCANNERS_HOME=/data/informatica/CURRENT/services/CatalogService/AdvancedScannersApplication/app
  SCANNERS_URL=https://asvedcpmtest01.informatica.com:48090
  SCANNERS_USER=admin
  SCANNERS_SECURITY_DOMAIN=Native
step 1: checking git fetch/status in /data/git/mdx_sql_script_automation
    git repo folder exists. /data/git/mdx_sql_script_automation
    no changes to git repository upstream, exiting
no changes to files in git repo, or error running scan
```

## Example 3: changed files, metadex not running
```
./mdx_git_automation.sh SQL_Script_automation script_scan_sqlserver /data/git/mdx_sql_script_automation
parameters:  Project=SQL_Script_automation Config=script_scan_sqlserver Folder=/data/git/mdx_sql_script_automation
variables in use
  INFA_HOME=/data/informatica/CURRENT
  SCANNERS_HOME=/data/informatica/CURRENT/services/CatalogService/AdvancedScannersApplication/app
  SCANNERS_URL=https://asvedcpmtest01.informatica.com:48090
  SCANNERS_USER=admin
  SCANNERS_SECURITY_DOMAIN=Native
step 1: checking git fetch/status in /data/git/mdx_sql_script_automation
    git repo folder exists. /data/git/mdx_sql_script_automation
    success: git status shows updates
step 2: checking metadex is running
     failed: mdx is not running
no changes to files in git repo, or error running scan
```

## Example 4: changed files, invalid project or configuration
```
./mdx_git_automation.sh SQL_Script_automation bad_config /data/git/mdx_sql_script_automation
parameters:  Project=SQL_Script_automation Config=bad_config Folder=/data/git/mdx_sql_script_automation
variables in use
  INFA_HOME=/data/informatica/CURRENT
  SCANNERS_HOME=/data/informatica/CURRENT/services/CatalogService/AdvancedScannersApplication/app
  SCANNERS_URL=https://asvedcpmtest01.informatica.com:48090
  SCANNERS_USER=admin
  SCANNERS_SECURITY_DOMAIN=Native
step 1: checking git fetch/status in /data/git/mdx_sql_script_automation
    git repo folder exists. /data/git/mdx_sql_script_automation
    success: git status shows updates
step 2: checking metadex is running
    success: mdx is running
step 3: checking mdx config - project=SQL_Script_automation config=bad_config
    failed: config bad_config is not found for projecgt SQL_Script_automation
no changes to files in git repo, or error running scan
```

## Example 5: changed files, metadex scan already queued/running
```
./mdx_git_automation.sh SQL_Script_automation script_scan_sqlserver /data/git/mdx_sql_script_automation
parameters:  Project=SQL_Script_automation Config=script_scan_sqlserver Folder=/data/git/mdx_sql_script_automation
variables in use
  INFA_HOME=/data/informatica/CURRENT
  SCANNERS_HOME=/data/informatica/CURRENT/services/CatalogService/AdvancedScannersApplication/app
  SCANNERS_URL=https://asvedcpmtest01.informatica.com:48090
  SCANNERS_USER=admin
  SCANNERS_SECURITY_DOMAIN=Native
step 1: checking git fetch/status in /data/git/mdx_sql_script_automation
    git repo folder exists. /data/git/mdx_sql_script_automation
    success: git status shows updates
step 2: checking metadex is running
    success: mdx is running
step 3: checking mdx config - project=SQL_Script_automation config=script_scan_sqlserver
    success: config script_scan_sqlserver is valid
step 4: checking for running/queued scan project=SQL_Script_automation config=script_scan_sqlserver
    failed: metaadex job is running - try later
no changes to files in git repo, or error running scan
```