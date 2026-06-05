#!/bin/bash
# ~/bin/git-ai-assist.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configs
CONFIG_DIR="$HOME/.config/git-ai-assist"
CONFIG_FILE="$CONFIG_DIR/config.env"
HISTORY_FILE="$CONFIG_DIR/history.log"

CURRENT_DIR=$(pwd)
CURRENT_CONFIG_DIR="$CURRENT_DIR/.git-ai-assist"
CURRENT_CONFIG_FILE="$CURRENT_CONFIG_DIR/config.env"

# Create config directory
mkdir -p "$CONFIG_DIR"

# Setup
setup_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}Initial config required ${NC}"
        echo "Choice your LLM:"
        echo "1) OpenAI (GPT-4/GPT-3.5)"
        echo "2) Anthropic Claude"
        echo "3) Google Gemini"
        read -p "Option (1-3): " llm_choice

        case $llm_choice in
            1)
                read -p "API Key OpenAI: " api_key
                echo "LLM_TYPE=openai" > "$CONFIG_FILE"
                echo "OPENAI_API_KEY=$api_key" >> "$CONFIG_FILE"
                echo "OPENAI_MODEL=gpt-4" >> "$CONFIG_FILE"
                ;;
            2)
                # read -p "API Key Anthropic: " api_key
                # echo "LLM_TYPE=anthropic" > "$CONFIG_FILE"
                # echo "ANTHROPIC_API_KEY=$api_key" >> "$CONFIG_FILE"
                echo "Unavailable in this version"
                ;;
            3)
                # read -p "API Key Google: " api_key
                # echo "LLM_TYPE=google" > "$CONFIG_FILE"
                # echo "GOOGLE_API_KEY=$api_key" >> "$CONFIG_FILE"
                echo "Unavailable in this version"
                ;;
        esac
        
        echo -e "${GREEN}Config saved in $CONFIG_FILE${NC}"
    fi
}

check_git_repository() {
    if [ ! -d ".git" ]; then
        echo -e "${RED}You do not have a git repository in this project. ${NC}"
        exit 1
    fi
}

setup_project(){
    check_git_repository

    if [ ! -f "$CURRENT_CONFIG_FILE" ]; then
        mkdir -p "$CURRENT_CONFIG_DIR"
        read -p "Type your branch [Enter for default (main)]: " branch
        if [ -z "$branch" ]; then
            branch="main"
        fi
        echo "BRANCH=$branch" > "$CURRENT_CONFIG_FILE"

        read -p "Enable auto commit? (y/n): " auto_commit
        if [[ "$auto_commit" == "y" ]]; then
            auto_commit=true
        else
            auto_commit=false
        fi
        echo "AUTO_COMMIT=$auto_commit" >> "$CURRENT_CONFIG_FILE"

        read -p "Add in .gitignore? (y/n): " git_ignore_config
        if [[ "$git_ignore_config" == "y" ]]; then
            echo ".git-ai-assist/" >> .gitignore
        fi

        echo -e "${GREEN}Config saved in $CURRENT_CONFIG_FILE${NC}"
    else
        echo -e "${YELLOW}Config already exists ${NC}"
        read -p "Do you want to overwrite it? (y/n): " overwrite
        if [[ "$overwrite" == "y" ]]; then
            rm -f "$CURRENT_CONFIG_FILE"
            setup_project
        else
            echo -e "${YELLOW}Keeping existing config ${NC}"
        fi
    fi
}

help(){
    echo "Git AI Assistant - Automação Inteligente para Git"
    echo ""
    echo "usage: git-ai-assist [-h | --help]"
    echo "                     [-v | --version]"
    echo "                     <command> [args]"
    echo "Comandos:"
    echo "  init                     # Inicializa o projeto atual para uso do assistente"
    echo "  gen-commit               # Gera uma mensagem de commit inteligente com base nas mudanças"
    echo "  gen-report               # Gera um relatório inteligente com base nas mudanças"
    echo "  see-alt                  # Apresenta as mudanças realizadas"
    exit 0
}

check_project_initialized() {
    if [ ! -f "$CURRENT_CONFIG_FILE" ]; then
        echo -e "${RED}Project not initialized. Run 'git-ai-assist init' first. ${NC}"
        exit 1
    fi
}

commit (){
    check_project_initialized
}

see_alt (){
    check_project_initialized
    
    git add -N .

    modified_files=$(git diff --name-only)

    new_files=$(git ls-files --others --exclude-standard)

    for file in $modified_files; do
        echo "===== $file ====="
        git diff HEAD -- "$file"
    done

    for file in $new_files; do
        echo "===== NEW FILE: $file ====="
        cat "$file"
    done
    
}

main() {
    version="1.0.0"

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}jq não está instalado. Instale com: sudo apt install jq${NC}"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}curl não está instalado. Instale com: sudo apt install curl${NC}"
        exit 1
    fi

    setup_config

    if [ $# -eq 0 ]; then
        help
    fi

    case "$1" in
        init)
            setup_project
            ;;
        commit)
            commit
            ;;
        -h|--help)
            help
            ;;
        -v|--version)
            echo "$version"
            ;;
        see-alt)
            see_alt
            ;;
        *)
            echo -e "${RED}Erro: comando ou opção '$1' não existe.${NC}"
            echo ""
            help
            ;;
    esac
}

main "$@"