

# Add following commented lines to $HOME/.zshrc
# Path to your oh-my-zsh installation.
# export ZSH="/path/to/.oh-my-zsh"
# export ZSH_CUSTOM="/path/to/env_linux/oh_my_zsh_custom"
# . "/path/to/env_linux/.zshrc"

# Initialize environment modules
# source /usr/share/modules/init/zsh
# source /usr/local/Modules/3.2.10/init/zsh

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi


export VIRTUAL_ENV_DISABLE_PROMPT=1

ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"

plugins=(
  git
  svn
  web-search
)

source $ZSH/oh-my-zsh.sh

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
psalive () {
  if [[ -z "$1" ]]; then
    return 1
  fi

  if [[ -n "$(ps -p $1 -o pid=)" ]]; then
    return 0
  fi

  return 1
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sshid () {
  local AGENT_FILE="$HOME/.ssh/sshid_run"

  # test if agent is available
  ssh-add -l &>/dev/null

  if [[ $? -eq 2 ]]; then
    # not available

    if [[ -n $SSH_AGENT_PID ]]; then
      # bad environment variable
      echo "Agent pid $SSH_AGENT_PID not available"
      unset SSH_AGENT_PID
    fi

    if [[ (-z $SSH_AGENT_PID || -z $SSH_AUTH_SOCK) && -f $AGENT_FILE ]]; then
      # environment variables not set, but there appears to be an agent file
      echo "Loading existing agent variables from $AGENT_FILE"
      source $AGENT_FILE || return 1

      ssh-add -l &>/dev/null

      if [[ $? -eq 2 ]]; then
        echo "Loaded agent pid $SSH_AGENT_PID not available"
        unset SSH_AGENT_PID
        rm $AGENT_FILE
      fi
    fi
  fi

  if [[ -n $SSH_AGENT_PID ]]; then
    # environment variables set, but make sure it's actually running
    echo "Agent pid $SSH_AGENT_PID still running"

  else
    echo "Starting new ssh-agent"

    ssh-agent -s &> $AGENT_FILE || return 1

    source $AGENT_FILE || return 1
  fi

  if [[ -n $1 ]]; then
    echo "Adding $1"
    ssh-add $1
  fi

  ssh-add -l

  if [[ $? -eq 0 ]]; then
    return 0

  else
    echo "Adding default"
    ssh-add || return 1
  fi

  ssh-add -l || return 1
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sshkill () {
  local AGENT_FILE="$HOME/.ssh/sshid_run"

  for i in $(pidof ssh-agent) ; do
    SSH_AGENT_PID=$i
    echo "Killing Agent pid $SSH_AGENT_PID"

    ssh-agent -k &>/dev/null
  done

  unset SSH_AGENT_PID
  unset SSH_AUTH_SOCK

  if [[ -f $AGENT_FILE ]]; then
    rm $AGENT_FILE
  fi
}

# Generalized environment cleaning
purge () {
  #echo "Deactivating virtual environment and purging modules"
  if typeset -f deactivate > /dev/null; then
    deactivate
  fi

  # must be done in reverse order as load_venv
  module purge
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Generalized environment loading
load_venv() {
  if [ -f "$1/bin/activate" ]; then

    if typeset -f deactivate > /dev/null; then
      deactivate
    fi


  fi

  if [ -f "$1/modules" ]; then
    # if there is also a modules file, load those modules as well
    module purge
    module load $(cat "$1/modules") || return 1
    module list || return 1
  fi

  if [ -f "$1/bin/activate" ]; then

    # activate the virtual environment
    source "$1/bin/activate" || return 1

    echo "$VIRTUAL_ENV"

  fi

}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
load () {
  # load a virtual environment by recursivly going to parent directories until
  # a $1 folder is found with a bin/activate script.

  if [ ! $1 ]; then
    echo "Must specify a virtual environment <id>."
    return 1
  fi

  if [ $(echo "$1" | grep '^/') ]; then
    # this is an absolute path to the directory
    if [ -f "$1/bin/activate" ]; then
      load_venv "$1" || return 1
    else
      echo "Could not find a folder for virtual environment '$1'"
    fi
  else

    dir="${PWD}"
    target_dir="$1"

    while [ $dir != "/" ] && [ ! -f "$dir/$target_dir/bin/activate" ]; do
      dir="$(dirname $dir)"
    done

    if [ -f "$dir/$target_dir/bin/activate" ]; then
      load_venv "$dir/$target_dir"
    else
      echo "Could not find a folder for virtual environment '$target_dir'"
    fi
  fi
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
save () {
  # save loaded modules into current virtual_env
  if [ -n "$VIRTUAL_ENV" ]; then
    module list --terse 2>&1 | tail -n +2 | tr '\n' ' ' > "$VIRTUAL_ENV/modules"
    echo "Saved modules to $VIRTUAL_ENV/modules"
    cat "$VIRTUAL_ENV/modules"
  else
    echo "No virtual environment currently loaded"
  fi
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
svn_add_new() {
  svn st | grep '^?' | awk '{print $2}' | xargs svn add
}

svn_rm_deleted() {
  svn st | grep '^!' | awk '{print $2}' | xargs svn delete --force
}

svn_set_id() {
  svn ps svn:keywords 'Id' $1
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
pip_uninstall() {
  # uninstalls all packages matching a given patthern
  # if no pattern, then removes all installed packages
  if [ ! $1 ]; then
    pip freeze | sed 's/^\([a-zA-Z0-9\_\.-]*\)\(.*\)$/\1/g' | xargs pip uninstall -y
  else
    pip freeze | grep $1 | sed 's/^\([a-zA-Z0-9\_\.-]*\)\(.*\)$/\1/g' | xargs pip uninstall -y
  fi

}

unsetopt share_history
