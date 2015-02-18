#!/bin/sh

start_dir=$1

# bash check if directory exists
if [ -n "$1" ] && [ -d $start_dir ]; then
  echo "Scanning directory $start_dir..."
else 
  echo "Please provide a valid directory as the first argument\n    Example: $0 app/"
  exit 1
fi 

# Gets the total lines of source code
total_lines() {
  source_files | xargs cat | wc -l
}

# Gets all the source files in the repository
# (excluding bindary files)
source_files() {
  git ls-files -z $start_dir | xargs -0 grep -Il -d skip .
}

# Gets all blamed lines of all source files in the repository
git_blames() {
  source_files | xargs -n1 git blame -t -l -c
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

total_lines=$(total_lines)
current_lines_by_users=$(current_lines_by_users)
longest_name_count=$(echo "$current_lines_by_users" | awk '{$1=""; print $0}' | wc -L)
name_pad=$(expr $longest_name_count + 2)

echo "$current_lines_by_users" | while read line; do
  line_count=$(echo $line | awk '{print $1}')
  contributor=$(echo $line | awk '{$1=""; print $0}')
  percent=$(percent $line_count $total_lines)
  printf "%-${name_pad}s %6s/%-6s (%s%%)\n" "$contributor" $line_count $total_lines $percent
done
