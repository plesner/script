# The default user which we won't bother to show.
_prompt_default_user="plesner"

# The default machine which we won't bother to show.
_prompt_default_hostname="hackenschmidt"

# Mappings from names to the abbreviations to use in the pwd.
_prompt_path_segment_abbrevs=(
  Documents=D
  neutrino=n
)

# How long are we willing to wait for the slower commands to yield a result
# before bailing?
_prompt_slow_command_timeout=0.01s

# List of the base64 characters, in order.
_prompt_base64_chars="\
A B C D E F G H I J \
K L M N O P Q R S T \
U V W X Y Z a b c d \
e f g h i j k l m n \
o p q r s t u v w x \
y z 0 1 2 3 4 5 6 7 \
8 9 + /"

# Encodes a single value between 0 and 63 in base 64. Okay it doesn't really,
# it just returns the i'th base64 character.
function _prompt_base64_encode {
  echo $_prompt_base64_chars | cut -f $(($1 + 1)) -d' '
}

# Returns the username if it is different from the default, otherwise returns
# the empty string.
function _prompt_get_user {
  if [[ "${USER}" != "${_prompt_default_user}" ]];
    then printf ' %s' "$USER"
  fi
}

# Returns the hostname if it is different from the default, otherwise returns
# the empty string.
function _prompt_get_hostname {
  if [[ "${HOSTNAME}" != "${_prompt_default_hostname}" ]];
    then printf ' %s' "$HOSTNAME";
  fi
}

# Returns the abbreviation mapping converted into a set of options to sed that
# perform the appropriate translations.
function _prompt_get_abbrev_map {
  for abbrev in ${_prompt_path_segment_abbrevs[*]}
  do
    echo $abbrev | sed -e "s|\(.*\)=\(.*\)|-e s\|/\1\|/\2\|g|g"
  done
}

# Returns the compacted version of the current working directory.
function _prompt_get_pwd {
  home_pwd=$(echo $PWD | sed -e "s|$HOME|~|g")
  abbrev_map="$(_prompt_get_abbrev_map)"
  result=$(echo $home_pwd | sed $abbrev_map)
  if [ -n "$result" ];
    then printf ' %s' "$result"
  fi
}

# Returns a compact representation of the status of the current git branch.
function _prompt_get_branch_status {
  status=$(timeout $_prompt_slow_command_timeout git status --porcelain |      \
    grep -v "??" |                                                             \
    sed "s|\(..\).*|\1|g" |                                                    \
    sort |                                                                     \
    uniq -c |                                                                  \
    sed "s| ||g" |                                                             \
    tr "[:upper:]" "[:lower:]")
  echo $status | sed "s| ||g"
}

# Returns the current git branch and status if we're in a git repo, otheriwse
# the empty string.
function _prompt_get_git_branch {
  output=$(timeout $_prompt_slow_command_timeout git branch 2>&1 |            \
    grep "*" |                                                                \
    sed "s/^\* \(.*\)$/\1/g")
  if [ -n "$output" ]; then
    status=$(_prompt_get_branch_status)
    if [ -n "$status" ]; then
      output="$output@$status"
    fi
    printf ' %s' "$output"
  fi
}

# Works just like date but trims leading zeros off the result.
function _prompt_trim_date {
  date $* | sed "s|^0*\(..*\)$|\1|g"
}

# Returns a compact representation of the current time.
function _prompt_get_time {
  # Just grab the least significant part of the date.
  day=$(_prompt_base64_encode $(_prompt_trim_date "+%d"))
  hour=$(_prompt_base64_encode $(_prompt_trim_date "+%H"))
  min=$(_prompt_base64_encode $(_prompt_trim_date "+%M"))
  printf '%s' "$day$hour$min"
}

# Build the whole prompt. It would be nicer if the color codes could be broken
# out somehow but they can't be inserted dynamically, the terminal needs to
# know which are printing and non-printing directly from the string.
export PS1='\[\033[00m\]\[\033[35m\]$(_prompt_get_time)\[\033[33m\]$(_prompt_get_user)\[\033[31m\]$(_prompt_get_hostname)\[\033[36m\]$(_prompt_get_pwd)\[\033[34m\]$(_prompt_get_git_branch)\[\033[00m\] '
