#!/bin/bash

# Clean up a path typed or drag-and-dropped into the terminal:
# strips surrounding quotes ('...' or "...") and backslash escapes (e.g. "My\ Game").
clean_path() {
    local p="$1"
    p="${p#"${p%%[![:space:]]*}"}"   # trim leading spaces
    p="${p%"${p##*[![:space:]]}"}"   # trim trailing spaces
    if [[ "$p" == \'*\' || "$p" == \"*\" ]]; then
        p="${p:1:${#p}-2}"
    else
        p="${p//\\/}"
    fi
    p="${p/#\~/$HOME}"
    echo "$p"
}

# Prompt for the name of the .desktop file
read -r -p "Enter the name of the .desktop file: " name
while [[ -z "$name" ]]; do
    read -r -p "Name can't be empty. Enter the name: " name
done

# Prompt for the comment for the .desktop file
read -r -p "Enter the comment for the .desktop file: " comment

# Prompt for the executable path
read -r -p "Enter the executable path: " exec
exec="$(clean_path "$exec")"
if [[ ! -e "$exec" ]]; then
    echo "Warning: '$exec' doesn't exist (yet). The launcher won't work until it does."
elif [[ ! -x "$exec" ]]; then
    read -r -p "'$exec' isn't executable. Make it executable? (y/n): " make_exec
    [[ "$make_exec" =~ ^[Yy] ]] && chmod +x "$exec"
fi

# Prompt for the icon path
read -r -p "Enter the icon path: " icon
icon="$(clean_path "$icon")"

# Prompt for whether the terminal should be opened
read -r -p "Should the terminal be opened? (true/false) [false]: " terminal
case "${terminal,,}" in
    true|t|yes|y) terminal=true ;;
    *) terminal=false ;;
esac

# Prompt for categories (these are the standard menu categories)
echo "Select categories (enter numbers separated by spaces):"
echo "1. Game"
echo "2. Development"
echo "3. Utility"
echo "4. Education"
echo "5. Settings"
echo "6. Network (internet, chat)"
echo "7. AudioVideo (music, video)"
echo "8. Graphics"
echo "9. Office"
echo "10. System"
read -r -p "Categories: " categories

# Convert categories to a string (the trailing ";" is required by the spec)
categories_string=""
for category in $categories; do
    case $category in
        1) categories_string+="Game;" ;;
        2) categories_string+="Development;" ;;
        3) categories_string+="Utility;" ;;
        4) categories_string+="Education;" ;;
        5) categories_string+="Settings;" ;;
        6) categories_string+="Network;" ;;
        7) categories_string+="AudioVideo;" ;;
        8) categories_string+="Graphics;" ;;
        9) categories_string+="Office;" ;;
        10) categories_string+="System;" ;;
        *) echo "Invalid category: $category" ;;
    esac
done
[[ -z "$categories_string" ]] && categories_string="Utility;"

# Quote the executable so paths with spaces work
exec_escaped="${exec//\\/\\\\}"
exec_escaped="${exec_escaped//\"/\\\"}"
exec_escaped="${exec_escaped//\$/\\\$}"
exec_escaped="${exec_escaped//\`/\\\`}"

# Create the .desktop file in the local user's applications directory
file_name="${name//\//-}"
desktop_file_path="$HOME/.local/share/applications/$file_name.desktop"
mkdir -p "$HOME/.local/share/applications"  # Ensure the directory exists

cat > "$desktop_file_path" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=$comment
Exec="$exec_escaped"
Path=$(dirname "$exec")
Icon=$icon
Terminal=$terminal
Categories=$categories_string
EOF

# Check if the file was created successfully
if [[ -f "$desktop_file_path" ]]; then
    command -v update-desktop-database >/dev/null && update-desktop-database -q "$HOME/.local/share/applications"
    echo "Desktop file created successfully: $desktop_file_path"
else
    echo "Error creating desktop file."
fi
