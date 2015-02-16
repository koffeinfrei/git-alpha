#!/bin/sh

start_dir=$1

# bash check if directory exists
if [ -n "$1" ] && [ -d $start_dir ]; then
  echo "Scanning directory $start_dir..."
else 
  echo "Please provide a valid directory as the first argument\n    Example: $0 app/"
  exit 1
fi 

# Gets all the lines that were last editred
# by the user '$1'
current_lines_by_user() {
  git_blames | grep $1 | wc -l
}

# Gets the total lines of source code
total_lines() {
  source_files | xargs wc -l | grep ' total$' | awk '{print $1}'
}

# Gets all the source files in the repository
source_files() {
  find $start_dir -type f -exec grep -Il . {} \;
}

# Gets all blamed lines of all source files in the repository
git_blames() {
  source_files | xargs -n1 git blame
}

# Gets the unique contributors to the source code repository
git_contributors() {
 git shortlog -ns | awk '{print $2}' | uniq
}

# Calculates the percentage, rounded to 2 decimal places
# $1: to be calculated number
# $2: total number
percent() {
  printf "%0.2f" $(echo "100 / $2 * $1" | bc -l)
}

# ------------------------------------------------------------------------------

total_lines=$(total_lines)

for contributor in $(git_contributors); do
  current_lines_by_user=$(current_lines_by_user $contributor)
  percent=$(percent $current_lines_by_user $total_lines)
  
  printf "%-15s %6s/%-6s (%s%%)\n" $contributor $current_lines_by_user $total_lines $percent
done