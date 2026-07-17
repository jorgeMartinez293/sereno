#!/bin/zsh

# 1. Get the directory passed as parameter
DIR="$1"

# 2. Basic validations
if [[ -z "$DIR" ]]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

if [[ ! -d "$DIR" ]]; then
    echo "Error: '$DIR' is not a valid directory."
    exit 1
fi

# 3. Store all files in an array
# The '(.N)' zsh modifier does two things:
# '.' -> Only picks files (ignores directories).
# 'N' -> If the folder is empty, no error — just an empty list.
files=("$DIR"/*(.N))

# 4. Check if the folder has any files
if [[ ${#files[@]} -eq 0 ]]; then
    echo "Error: No files found in '$DIR'."
    exit 1
fi

# 5. Pick a random file
# $RANDOM generates a random number. With modulo (%) we ensure
# it falls within the range of our file list.
random_index=$(( (RANDOM % ${#files[@]}) + 1 ))
random_file="${files[$random_index]}"

# 6. Return the full path of the chosen file
echo "$random_file"
