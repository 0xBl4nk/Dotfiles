#!/usr/bin/env bash

REPO_CONFIG="$PWD/.config"  # Path to .config in repository
DOTPATH="$HOME/.config"     # Destination path
VERBOSE=false               # Default to non-verbose mode
BACKUP_LIST=""              # List to store backed up items

# Check if verbose flag is set
if [ "$1" = "-v" ]; then
  VERBOSE=true
fi

# Function for verbose output
log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo "$1"
  fi
}

# Function for standard output (always shown)
log_standard() {
  echo "$1"
}

clear

# Check if repository .config directory exists
if [ ! -d "$REPO_CONFIG" ]; then
  log_standard "Error: Directory $REPO_CONFIG not found."
  exit 1
fi

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install requirements based on OS
install_requirements() {
  local OS="$1"
  local REQUIREMENTS_FILE="$PWD/requirements.json"
  
  log_standard "Checking and installing required programs for $OS..."
  
  # Check if requirements file exists
  if [ ! -f "$REQUIREMENTS_FILE" ]; then
    log_standard "Error: Requirements file not found at $REQUIREMENTS_FILE"
    return 1
  fi
  
  # Check if jq is installed (needed to parse JSON)
  if ! command_exists jq; then
    log_standard "Error: jq is required to parse the requirements file."
    log_standard "Please install jq first and try again."
    return 1
  fi
  
  # Verifica se existe a seção do SO no JSON
  if ! jq -e ".$OS" "$REQUIREMENTS_FILE" >/dev/null 2>&1; then
    log_standard "No configuration found for '$OS' in $REQUIREMENTS_FILE"
    return 1
  fi
  
  # Pega a lista de "programas" em .$OS (ex.: neovim, git, curl, etc.)
  local PROGRAMS
  PROGRAMS=$(jq -r "keys[]" <<< "$(jq ".$OS" "$REQUIREMENTS_FILE")")
  
  for PROG in $PROGRAMS; do
    local PROGRAM_NAME
    local INSTALL_COMMAND
    
    # Extrai o nome e comando de instalação
    PROGRAM_NAME=$(jq -r ".$OS.$PROG.name" "$REQUIREMENTS_FILE")
    INSTALL_COMMAND=$(jq -r ".$OS.$PROG.command" "$REQUIREMENTS_FILE")

    # Se não tiver name/command, pode pular
    if [ -z "$PROGRAM_NAME" ] || [ -z "$INSTALL_COMMAND" ] || [ "$PROGRAM_NAME" = "null" ] || [ "$INSTALL_COMMAND" = "null" ]; then
      log_standard "Warning: Missing name or command in requirements.json for '$PROG'. Skipping..."
      continue
    fi

    log_standard "Checking for $PROGRAM_NAME..."

    # Check if program is already installed
    if ! command_exists "$PROGRAM_NAME"; then
      log_standard "$PROGRAM_NAME is not installed. Installing..."
      log_verbose "Running command: $INSTALL_COMMAND"

      # Execute the installation command
      eval "$INSTALL_COMMAND"

      if [ $? -eq 0 ]; then
        log_standard "$PROGRAM_NAME was installed successfully."
      else
        log_standard "Error: Failed to install $PROGRAM_NAME."
      fi
    else
      log_standard "$PROGRAM_NAME is already installed."
    fi
  done
}

# Parse command line arguments
OS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v)
      VERBOSE=true
      ;;
    -os)
      if [[ "$2" == "arch" || "$2" == "gentoo" ]]; then
        OS="$2"
        shift
      else
        log_standard "Error: Supported OS options are 'arch' or 'gentoo'"
        exit 1
      fi
      ;;
    *)
      log_standard "Unknown option: $1"
      log_standard "Usage: $0 [-v] [-os arch|gentoo]"
      exit 1
      ;;
  esac
  shift
done

# Check if OS parameter was provided
if [ -z "$OS" ]; then
  log_standard "Error: -os parameter is required (arch or gentoo)"
  log_standard "Usage: $0 [-v] [-os arch|gentoo]"
  exit 1
fi

# Install requirements based on specified OS
install_requirements "$OS"

# Create destination directory if it doesn't exist
mkdir -p "$DOTPATH"

# List all items that will be transferred
log_standard "The following items will be transferred to $DOTPATH:"
ls -1 "$REPO_CONFIG" | sed 's/^/- /'
echo ""

log_verbose "Starting dotfiles copy script"
log_verbose "Source: $REPO_CONFIG"
log_verbose "Destination: $DOTPATH"

# Process all items in repository .config directory
for item in "$REPO_CONFIG"/*; do
  if [ -e "$item" ]; then
    # Get just the name of file/directory
    basename=$(basename "$item")
    
    log_verbose "Processing item: $basename"
    
    # Check if file/directory already exists in destination
    if [ -e "$DOTPATH/$basename" ]; then
      mv "$DOTPATH/$basename" "$DOTPATH/${basename}.bak"
      BACKUP_LIST="$BACKUP_LIST$basename "
      
      if [ "$VERBOSE" = true ]; then
        if [ $? -eq 0 ]; then
          log_verbose "Backup created successfully: $DOTPATH/${basename}.bak"
        else
          log_verbose "Error creating backup for $basename"
        fi
      fi
    else
      log_verbose "Item $basename doesn't exist in destination, no backup needed."
    fi
    
    # Copy item to destination
    cp -r "$item" "$DOTPATH/"
    log_verbose "Item $basename copied successfully."
  fi
done

# Report on backups
if [ -n "$BACKUP_LIST" ]; then
  log_standard "Backup created for the following items:"
  for item in $BACKUP_LIST; do
    echo "- $item (saved as ${item}.bak)"
  done
else
  log_standard "No backups were needed. All items are new."
fi

log_standard "=============================================="

# Clone nvim configuration from GitHub
log_standard "Cloning nvim configuration from GitHub..."
if [ -d "$DOTPATH/nvim" ]; then
  log_standard "Existing nvim directory found, creating backup..."
  mv "$DOTPATH/nvim" "$DOTPATH/nvim.bak"
  BACKUP_LIST="$BACKUP_LIST nvim"
fi

git clone https://github.com/0xbl4nk/nvim "$DOTPATH/nvim"
if [ $? -eq 0 ]; then
  log_standard "Neovim configuration successfully cloned to $DOTPATH/nvim"
else
  log_standard "Error: Failed to clone nvim configuration. Please check your internet connection."
  if [ -d "$DOTPATH/nvim.bak" ]; then
    log_standard "Restoring previous nvim configuration..."
    mv "$DOTPATH/nvim.bak" "$DOTPATH/nvim"
  fi
fi
