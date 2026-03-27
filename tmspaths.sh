#! /bin/bash
process_folders() {
    local all_folders=()

    # Combine all arrays passed as arguments
    for folder in "$@"; do
        # Expand the path if it contains ~
        expanded_folder="${folder/#\~/$HOME}"
        # Remove any quotes from the path
        cleaned_folder="${expanded_folder//\"}"

        if [ -d "$cleaned_folder" ]; then
            all_folders+=("$cleaned_folder")
        else
            echo "Directory not found: $cleaned_folder"
        fi
    done

    # Execute tms config once with all valid folders
    if [ ${#all_folders[@]} -gt 0 ]; then
        echo "Executing tms config with folders: ${all_folders[*]}"
        tms config -p "${all_folders[@]}" --search-submodules=true
    fi
}

# Define your arrays
folders_personal=("$HOME/secondBrain")
folders_general=("$HOME/source" "$HOME/dotfiles" "$HOME/nixos-config")
folders_netlab=("~/bulk/cobra/source" "~/home/bulk/cobra/source" "/bulk/cobra0/home/nclshrnk/", "/bulk/netserv0/wimas/nclshrnk/source")

# Call the function with all folders at once
process_folders "${folders_general[@]}" "${folders_netlab[@]}" "${folders_personal[@]}"
