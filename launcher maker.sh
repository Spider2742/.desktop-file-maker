#!/bin/bash

# Prompt for the name of the .desktop file
read -p "Enter the name of the .desktop file: " name

# Prompt for the comment for the .desktop file
read -p "Enter the comment for the .desktop file: " comment

# Prompt for the executable path and remove quotes if necessary
read -p "Enter the executable path: " exec
if [[ "$exec" =~ \' ]]; then
    exec="${exec//\'/}"
fi

# Prompt for the icon path and remove quotes if necessary
read -p "Enter the icon path: " icon
if [[ "$icon" =~ \' ]]; then
    icon="${icon//\'/}"
fi

# Prompt for whether the terminal should be opened
read -p "Should the terminal be opened? (true/false): " terminal

# Prompt for categories
echo "Select categories (enter numbers separated by spaces):"
echo "1. Game"
echo "2. Application"
echo "3. Utility"
echo "4. Education"
echo "5. Settings"
echo "6. Other"
read -p "Categories: " categories

# Convert categories to a string
categories_string=""
for category in $categories; do
    case $category in
        1) categories_string+="Game;" ;;
        2) categories_string+="Application;" ;;
        3) categories_string+="Utility;" ;;
        4) categories_string+="Education;" ;;
        5) categories_string+="Settings;" ;;
        6) categories_string+="Other;" ;;
        *) echo "Invalid category: $category" ;;
    esac
done

# Create the .desktop file content
desktop_file_content="
[Desktop Entry]
Version=1.0
Name=$name
Comment=$comment
Exec=$exec
Icon=$icon
Terminal=$terminal
Type=Application
Categories=${categories_string::-1}  # Remove trailing semicolon
"

# Create the .desktop file in the local user's applications directory
desktop_file_path="$HOME/.local/share/applications/$name.desktop"
mkdir -p "$HOME/.local/share/applications"  # Ensure the directory exists
echo "$desktop_file_content" > "$desktop_file_path"

# Check if the file was created successfully
if [[ -f "$desktop_file_path" ]]; then
    echo "Desktop file created successfully: $desktop_file_path"
else
    echo "Error creating desktop file."
fi
