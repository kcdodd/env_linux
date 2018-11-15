

# Add following commented lines to $HOME/.zshrc
# Path to your oh-my-zsh installation.
# export ZSH="/path/to/.oh-my-zsh"
# export ZSH_CUSTOM="/path/to/env_linux/oh_my_zsh_custom"
# . "/path/to/env_linux/.zshrc"

export VIRTUAL_ENV_DISABLE_PROMPT=1

ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"

plugins=(
  git
  svn
  web-search
)

source $ZSH/oh-my-zsh.sh

# Initialize environment modules
source /usr/share/modules/init/zsh

# Generalized environment cleaning
purge () {
  #echo "Deactivating virtual environment and purging modules"
  module purge

  if typeset -f deactivate > /dev/null; then
    deactivate
  fi
}

# Generalized environment loading
load_venv() {
  if [ -f "$1/bin/activate" ]; then

    if typeset -f deactivate > /dev/null; then
      deactivate
    fi

    # activate the virtual environment
    source "$1/bin/activate"

    echo "$VIRTUAL_ENV"

  fi

  if [ -f "$1/modules" ]; then
    # if there is also a modules file, load those modules as well
    module purge
    module load $(cat "$1/modules")
    module list
  fi
}

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
      load_venv "$1"
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

unsetopt share_history
