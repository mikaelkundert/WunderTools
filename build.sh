#!/bin/bash
# Helper function to parse yaml configs
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Remember to update this on each release
# Also update the changelog!
VERSION=6

pushd `dirname $0` > /dev/null
ROOT=`pwd -P`
popd > /dev/null
# Parse project config
PROJECTCONF=$ROOT/conf/project.yml
eval $(parse_yaml $PROJECTCONF)
ALIASFILE=${project_name}.aliases.drushrc.php
ALIASPATH=$ROOT/drupal/conf/$ALIASFILE
ALIASTARGET=$HOME/.drush/$ALIASFILE

if [ -z "$wundertools_branch" ]; then
  GITBRANCH="master"
else
  GITBRANCH=$wundertools_branch
fi

VERSIONFILE=$ROOT/VERSION
CHANGELOG=$ROOT/CHANGELOG
CHANGELOGURL="https://raw.githubusercontent.com/wunderkraut/WunderTools/$GITBRANCH/CHANGELOG"

if [ -f $VERSIONFILE ]; then
  typeset -i CURRENT_VERSION=$(<$VERSIONFILE)
else
  CURRENT_VERSION=0
fi

if [ "$CURRENT_VERSION" -ne "$VERSION" ]; then
  echo -e "\033[0;31mBuild.sh version has been updated.\033[0m Make sure your project complies with the changes outlined in the CHANGELOG since version $CURRENT_VERSION"
  while read -p "I have updated everything ([y]es / [n]o / show [c]hangelog)? " -n 1 -r && [[ $REPLY =~ ^[Cc]$ ]]; do
    echo $CHANGELOGURL
    if [ ! -f $CHANGELOG ]; then
      curl -s -o $CHANGELOG $CHANGELOGURL
    fi
    sed -e '/^'$CURRENT_VERSION'$/,$d' $CHANGELOG
  done
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo $VERSION > $VERSIONFILE
    echo "Current version updated, make sure to commit all the changes before continuing."
  fi
fi

if command -v md5sum >/dev/null 2>&1; then
  MD5COMMAND="md5sum"
else
  MD5COMMAND="md5 -r"
fi

if [[ $1 == "reset" ]]; then
  read -p "This will reset everything! Are you sure (y/n)? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd $ROOT
    vagrant destroy
    rm -r $ROOT/ansible
    rm $ALIASTARGET
  fi
# Only run when running vagrant up or provision
elif [[ $1 == "up" || $1 == "provision" ]]; then
  # First we check if there is update for this script
  SELF=$(basename $0)
  UPDATEURL="https://raw.githubusercontent.com/wunderkraut/WunderTools/$GITBRANCH/build.sh"
  MD5SELF=$($MD5COMMAND $0 | awk '{print $1}')
  MD5LATEST=$(curl -s $UPDATEURL | $MD5COMMAND | awk '{print $1}')
  if [[ "$MD5SELF" != "$MD5LATEST" ]]; then
    while read -p "There is update for this script available. Update now ([y]es / [n]o / show [c]hangelog)?" -n 1 -r && [[ $REPLY =~ ^[Cc]$ ]]; do
      curl -s $CHANGELOGURL | sed -e '/^'$CURRENT_VERSION'$/,$d'
    done
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      cd $ROOT
      curl -s -o $SELF $UPDATEURL
      curl -s -o $CHANGELOG $CHANGELOGURL
      echo "Update complete, please rerun any command you were running previously."
      echo "See CHANGELOG for more info."
      echo "Also remember to add updated script to git."
      exit
    fi
  fi
  # Clone and update virtual environment configurations
  if [ ! -d "ansible" ]; then
    git clone  -b $ansible_branch $ansible_remote $ROOT/ansible
    if [ -n "$ansible_revision" ]; then
      cd $ROOT/ansible
      git reset --hard $ansible_revision
      cd $ROOT
    fi
  else
    if [ -z "$ansible_revision" ]; then
      cd $ROOT/ansible
      git pull
      cd $ROOT
    fi
  fi

  # If it is enabled in project.yml - get & update drupal/build.sh
  if $buildsh_enabled; then
    if [ -n "$buildsh_revision" ]; then
      curl -s -o $ROOT/drupal/build.sh https://raw.githubusercontent.com/wunderkraut/build.sh/$buildsh_revision/build.sh
    else
      curl -s -o $ROOT/drupal/build.sh https://raw.githubusercontent.com/wunderkraut/build.sh/$buildsh_branch/build.sh
    fi
  fi

  # Ensure drush aliases file is linked
  if [ ! -h $ALIASTARGET ] || [ ! "$(readlink $ALIASTARGET)" -ef "$ALIASPATH" ]; then
    rm $ALIASTARGET
    ln -s $ALIASPATH $ALIASTARGET
  fi

  if [ ! -z $externaldrupal_remote ]; then
    if [ ! -d "drupal/current" ]; then
      if [ -z $externaldrupal_branch ]; then
        $externaldrupal_branch = 'master'
      fi
      git clone -b $externaldrupal_branch $externaldrupal_remote $ROOT/drupal/current
    fi
  fi
fi

