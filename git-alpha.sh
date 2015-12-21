#!/bin/sh

# Help output
help() {
  echo "Usage: git-alpha [options] <repository_path>"
  echo "    -m       Machine readable output"
  echo "    -h       Print this help"

  exit 1
}

# Gets the total lines of source code
total_lines() {
  (cd $start_dir && source_files | xargs cat | wc -l)
}

# Gets all the source files in the repository
# (excluding bindary files)
source_files() {
  (cd $start_dir && git ls-files -z | xargs -0 grep -Il -d skip .)
}

# Gets all blamed lines of all source files in the repository
git_blames() {
  (cd $start_dir && source_files | xargs -n1 git blame -t -l -c)
}

# Extract the user from the blame output
# stdin: git blame output
extract_contributors_from_git_blames() {
  awk -F '\t' '{print $2}' | sed 's/(//'
}

# Calculates the percentage, rounded to 2 decimal places
# $1: to be calculated number
# $2: total number
percent() {
  printf "%0.2f" $(echo "100 / $2 * $1" | bc -l)
}

# Gets all the lines that were last edited
# by the contributors
current_lines_by_users() {
  git_blames | extract_contributors_from_git_blames | sort | uniq -c | sort -rn
}

# ------------------------------------------------------------------------------

HUMAN_OUTPUT=true

while getopts ":m" opt; do
  case $opt in
    m)
      HUMAN_OUTPUT=false
      ;;
    \?)
      help
      ;;
  esac
done

# move on to the next argument
shift $((OPTIND - 1))

# get the directory argument
start_dir="$1"

# current directory as default
if ! [ -n "$1" ]; then
  start_dir=$(pwd)
fi

# bash check if directory exists
if ! [ -d $start_dir ]; then
   echo "The directory '$start_dir' does not exist" >&2
   exit 1
fi

if [ "$HUMAN_OUTPUT" = true ]; then
  echo "Scanning directory '$start_dir'..."
fi

total_lines=$(total_lines)
current_lines_by_users=$(current_lines_by_users)
longest_name_count=$(echo "$current_lines_by_users" | awk '{$1=""; print $0}' | wc -L)
name_pad=$(expr $longest_name_count + 2)

echo "$current_lines_by_users" | while read line; do
  line_count=$(echo $line | awk '{print $1}')
  contributor=$(echo $line | awk '{$1=""; gsub(/^ /, "", $0); print $0}')
  percent=$(percent $line_count $total_lines)
  if [ "$HUMAN_OUTPUT" = true ]; then
    printf "%-${name_pad}s %6s/%-6s (%s%%)\n" "$contributor" $line_count $total_lines $percent
  else
    echo "$contributor\t$line_count\t$total_lines\t$percent"
  fi
done
