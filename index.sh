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
        echo "2) Grok"
        read -p "Option (1-2): " llm_choice

        case $llm_choice in
            1)
                read -p "API Key OpenAI: " api_key
                echo "LLM_TYPE=openai" > "$CONFIG_FILE"
                echo "OPENAI_API_KEY=$api_key" >> "$CONFIG_FILE"
                echo "OPENAI_MODEL=gpt-4" >> "$CONFIG_FILE"
                ;;
            2)
                read -p "API Key Grok: " api_key
                echo "LLM_TYPE=grok" > "$CONFIG_FILE"
                echo "GROK_API_KEY=$api_key" >> "$CONFIG_FILE"
    
                ;;
        esac
                
        echo -e "${GREEN}Config saved in $CONFIG_FILE${NC}"
    fi

    source "$CONFIG_FILE"
    source "$CURRENT_CONFIG_FILE"
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

see_alt() {
    check_project_initialized

    git add -N . >/dev/null 2>&1

    local tmp_file=$(mktemp)

    cat > "$tmp_file" <<EOF
        # GIT STATUS
        $(git status --short)
        # CHANGES
EOF

    while IFS= read -r file; do

        case "$file" in
            package-lock.json|yarn.lock|composer.lock|*.log|*.zip|*.gz|*.jpg|*.jpeg|*.png|*.gif|*.pdf)
                continue
                ;;
        esac

        echo "" >> "$tmp_file"
        echo "===== FILE: $file =====" >> "$tmp_file"

        git diff HEAD -- "$file" >> "$tmp_file"

    done < <(git diff --name-only HEAD)

    while IFS= read -r file; do

        case "$file" in
            package-lock.json|yarn.lock|composer.lock|*.log|*.zip|*.gz|*.jpg|*.jpeg|*.png|*.gif|*.pdf)
                continue
                ;;
        esac

        echo "" >> "$tmp_file"
        echo "===== NEW FILE: $file =====" >> "$tmp_file"

        head -n 100 "$file" >> "$tmp_file"

    done < <(git ls-files --others --exclude-standard)

    cat "$tmp_file"

    rm -f "$tmp_file"
}

git_commit(){
    local message="$1"

    git add .
    git commit -m "$(echo "$response" | sed 's/"/\\"/g')"
    echo -e "${GREEN}Changes committed with message: $message ${NC}"
}


call_llm(){
    local prompt="$1"
    local response=""

        response=$(curl -s https://api.groq.com/openai/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -d "{
            \"model\": \"llama-3.3-70b-versatile\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}],
            \"temperature\": 0.7,
            \"max_tokens\": 200
        }" | jq -r '.choices[0].message.content')
    

    if [ -z "$response" ] || [ "$response" = "null" ]; then
        echo -e "${RED} Error: Empty response from API. Verify your API key and connection.${NC}"
        return 1
    fi


    if [ $AUTO_COMMIT == "true" ]; then
        git_commit "$response"
    else
        echo -e "Do you want to commit with this message? ${YELLOW}$response${NC} (y/n)"
        read -p "" confirm
        if [[ "$confirm" == "y" ]]; then
            git_commit "$response"
        fi
    fi
}

generate_commit_message() {
    check_project_initialized

    local changes="$1"
    local custom_note="$2"

    local prompt="
You are a specialized assistant in generating Git commit messages based on code changes.

Analyze the following changes and generate a commit message following these rules:

1. Use the conventional format: type(scope): description
2. Types: feat, fix, docs, style, refactor, test, chore
3. Be specific and descriptive
4. Maximum 72 characters on the first line
5. Add explanatory body if necessary (no more than 3 lines)
6. Be in Portuguese

CHANGES:

$changes

$([ -n "$custom_note" ] && echo "USER NOTE: $custom_note")

Generate ONLY the commit message, without additional explanations.
"

call_llm "$prompt"
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
        gen-commit)
            changes=$(see_alt)
            echo "Do you want to add a custom note to the LLM? (y/n)"
            read -p "" add_note
            if [[ "$add_note" == "y" ]]; then
                echo "Type your note:"
                read -p "" custom_note
            fi
            generate_commit_message "$changes" "$custom_note"
            ;;
        *)
            echo -e "${RED}Erro: comando ou opção '$1' não existe.${NC}"
            echo ""
            help
            ;;
    esac
}

main "$@"