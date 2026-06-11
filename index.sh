#!/bin/bash

# ~/bin/git-ai-assist.sh
# Git AI Assistant - Automação Inteligente para Git

set -euo pipefail

# ===========================
# Colors
# ===========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===========================
# Paths
# ===========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/git-ai-assist"
CONFIG_FILE="$CONFIG_DIR/config.env"
HISTORY_FILE="$CONFIG_DIR/history.log"

CURRENT_DIR="$(pwd)"
CURRENT_CONFIG_DIR="$CURRENT_DIR/.git-ai-assist"
CURRENT_CONFIG_FILE="$CURRENT_CONFIG_DIR/config.env"

# ===========================
# Defaults
# ===========================
DEFAULT_MODEL="llama-3.3-70b-versatile"
DEFAULT_TEMPERATURE=0.7
DEFAULT_MAX_TOKENS=800

# ===========================
# Helpers
# ===========================
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

info() {
    echo -e "${GREEN}$1${NC}"
}

log_history() {
    mkdir -p "$CONFIG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$HISTORY_FILE"
}

# ===========================
# Setup config
# ===========================
setup_config() {
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}Initial configuration required${NC}"
        echo ""
        echo "Choose your LLM provider:"
        echo "  1) Groq (Llama 3, Mixtral, etc.)"
        echo "  2) OpenAI (GPT-4, GPT-3.5)"
        echo "  3) xAI Grok (Grok 2, etc.)"
        read -rp "Option (1-3): " llm_choice

        case $llm_choice in
            1)
                read -rp "Enter your Groq API Key: " api_key
                echo "LLM_TYPE=groq" > "$CONFIG_FILE"
                echo "GROQ_API_KEY=$api_key" >> "$CONFIG_FILE"
                echo "LLM_MODEL=$DEFAULT_MODEL" >> "$CONFIG_FILE"
                echo "LLM_API_URL=https://api.groq.com/openai/v1/chat/completions" >> "$CONFIG_FILE"
                ;;
            2)
                read -rp "Enter your OpenAI API Key: " api_key
                read -rp "Enter model name [gpt-4o]: " model
                model="${model:-gpt-4o}"
                echo "LLM_TYPE=openai" > "$CONFIG_FILE"
                echo "OPENAI_API_KEY=$api_key" >> "$CONFIG_FILE"
                echo "LLM_MODEL=$model" >> "$CONFIG_FILE"
                echo "LLM_API_URL=https://api.openai.com/v1/chat/completions" >> "$CONFIG_FILE"
                ;;
            3)
                read -rp "Enter your xAI Grok API Key: " api_key
                read -rp "Enter model name [grok-2-latest]: " model
                model="${model:-grok-2-latest}"
                echo "LLM_TYPE=grok" > "$CONFIG_FILE"
                echo "GROK_API_KEY=$api_key" >> "$CONFIG_FILE"
                echo "LLM_MODEL=$model" >> "$CONFIG_FILE"
                echo "LLM_API_URL=https://api.x.ai/v1/chat/completions" >> "$CONFIG_FILE"
                ;;
            *)
                die "Invalid option."
                ;;
        esac
        echo -e "${GREEN}Config saved in $CONFIG_FILE${NC}"
    fi

    # Source global config
    source "$CONFIG_FILE"

    # Source project config if it exists (overrides global)
    if [ -f "$CURRENT_CONFIG_FILE" ]; then
        source "$CURRENT_CONFIG_FILE"
    fi

    # Validate API key exists
    case "$LLM_TYPE" in
        groq)
            [ -z "${GROQ_API_KEY:-}" ] && die "GROQ_API_KEY not set in $CONFIG_FILE"
            API_KEY="$GROQ_API_KEY"
            ;;
        openai)
            [ -z "${OPENAI_API_KEY:-}" ] && die "OPENAI_API_KEY not set in $CONFIG_FILE"
            API_KEY="$OPENAI_API_KEY"
            ;;
        grok)
            [ -z "${GROK_API_KEY:-}" ] && die "GROK_API_KEY not set in $CONFIG_FILE"
            API_KEY="$GROK_API_KEY"
            ;;
        *)
            die "Unknown LLM_TYPE: $LLM_TYPE. Supported: groq, openai, grok"
            ;;
    esac

    # Set defaults if not configured
    LLM_MODEL="${LLM_MODEL:-$DEFAULT_MODEL}"
    LLM_API_URL="${LLM_API_URL:-https://api.groq.com/openai/v1/chat/completions}"
}

# ===========================
# Check git repository
# ===========================
check_git_repository() {
    if [ ! -d ".git" ]; then
        die "No git repository found in this project."
    fi
}

# ===========================
# Setup project
# ===========================
setup_project() {
    check_git_repository

    if [ ! -f "$CURRENT_CONFIG_FILE" ]; then
        mkdir -p "$CURRENT_CONFIG_DIR"

        read -rp "Enter your branch name [main]: " branch
        branch="${branch:-main}"

        read -rp "Enable auto commit? (y/n) [n]: " auto_commit
        if [[ "$auto_commit" == "y" || "$auto_commit" == "Y" ]]; then
            auto_commit="true"
        else
            auto_commit="false"
        fi

        read -rp "Add .git-ai-assist/ to .gitignore? (y/n) [y]: " git_ignore_config
        if [[ "$git_ignore_config" != "n" && "$git_ignore_config" != "N" ]]; then
            # Only add if not already present
            if ! grep -q ".git-ai-assist/" .gitignore 2>/dev/null; then
                echo ".git-ai-assist/" >> .gitignore
            fi
        fi

        {
            echo "BRANCH=$branch"
            echo "AUTO_COMMIT=$auto_commit"
        } > "$CURRENT_CONFIG_FILE"

        echo -e "${GREEN}Project config saved in $CURRENT_CONFIG_FILE${NC}"
    else
        warn "Project config already exists."
        read -rp "Do you want to overwrite it? (y/n): " overwrite
        if [[ "$overwrite" == "y" || "$overwrite" == "Y" ]]; then
            rm -f "$CURRENT_CONFIG_FILE"
            setup_project
        else
            info "Keeping existing config."
        fi
    fi
}

# ===========================
# Check project initialized
# ===========================
check_project_initialized() {
    if [ ! -f "$CURRENT_CONFIG_FILE" ]; then
        die "Project not initialized. Run 'git-ai-assist init' first."
    fi
    # Re-source project config to ensure variables are current
    source "$CURRENT_CONFIG_FILE"
    AUTO_COMMIT="${AUTO_COMMIT:-false}"
}

# ===========================
# Collect changes
# ===========================
see_alt() {
    check_project_initialized
    
    local has_changes=false
    
    if git diff --name-only HEAD 2>/dev/null | grep -q .; then
        has_changes=true
    fi
    
    if [ "$has_changes" = false ] && git ls-files --others --exclude-standard 2>/dev/null | grep -q .; then
        has_changes=true
    fi
    
    if [ "$has_changes" = false ]; then
        echo -e "${YELLOW}No changes detected in the repository. Nothing to show.${NC}" >&2
        return 0
    fi

    local tmp_file
    tmp_file=$(mktemp)
    trap "rm -f '$tmp_file'" EXIT

    echo "# GIT STATUS" >> "$tmp_file"
    git status --short >> "$tmp_file"
    echo "" >> "$tmp_file"
    echo "# DIFFS" >> "$tmp_file"

    while IFS= read -r file; do
        case "$file" in
            package-lock.json|yarn.lock|composer.lock|*.log|*.zip|*.gz|*.jpg|*.jpeg|*.png|*.gif|*.pdf|*.svg|*.ico)
                echo "===== SKIPPED (binary/lock): $file =====" >> "$tmp_file"
                continue
                ;;
        esac

        echo "" >> "$tmp_file"
        echo "===== FILE: $file =====" >> "$tmp_file"
        git diff HEAD -- "$file" >> "$tmp_file" 2>/dev/null || true

    done < <(git diff --name-only HEAD 2>/dev/null)

    while IFS= read -r file; do
        case "$file" in
            package-lock.json|yarn.lock|composer.lock|*.log|*.zip|*.gz|*.jpg|*.jpeg|*.png|*.gif|*.pdf|*.svg|*.ico)
                echo "===== SKIPPED (binary/lock): $file =====" >> "$tmp_file"
                continue
                ;;
        esac

        echo "" >> "$tmp_file"
        echo "===== NEW FILE: $file =====" >> "$tmp_file"
        head -n 100 "$file" >> "$tmp_file"

    done < <(git ls-files --others --exclude-standard 2>/dev/null)

    cat "$tmp_file"
}

# ===========================
# Call LLM API
# ===========================
call_llm() {
    local prompt="$1"
    local response=""
    local http_code=""
    local tmp_response
    tmp_response=$(mktemp)
    trap "rm -f '$tmp_response'" EXIT

    http_code=$(curl -s -w "%{http_code}" -o "$tmp_response" \
        "$LLM_API_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "{
            \"model\": \"${LLM_MODEL}\",
            \"messages\": [{\"role\": \"user\", \"content\": $(printf '%s' "$prompt" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$prompt")}],
            \"temperature\": ${DEFAULT_TEMPERATURE},
            \"max_tokens\": ${DEFAULT_MAX_TOKENS}
        }")

    response=$(cat "$tmp_response")

    # Handle HTTP errors
    if [[ "$http_code" -ge 400 ]] 2>/dev/null; then
        echo -e "${RED}HTTP Error $http_code from API${NC}" >&2
        echo -e "${RED}Response: $response${NC}" >&2
        return 1
    fi

    # Extract message content using jq
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)

    if [ -z "$content" ] || [ "$content" = "null" ]; then
        echo -e "${RED}Error: Empty response from API.${NC}" >&2
        echo -e "${RED}Raw response: $response${NC}" >&2
        echo -e "${RED}API Key prefix: ${API_KEY:0:8}...${NC}" >&2
        return 1
    fi

    echo "$content"
}

# ===========================
# Git commit
# ===========================
git_commit() {
    local message="$1"

    git add -A
    git commit -m "$message"
    echo -e "${GREEN}Changes committed with message:${NC}"
    echo -e "${MAGENTA}$message${NC}"
    log_history "COMMIT: $message"
}

# ===========================
# Generate commit message
# ===========================
generate_commit_message() {
    check_project_initialized

    local changes="$1"
    local custom_note="${2:-}"

    if [ -z "$changes" ] || [[ "$changes" =~ ^[[:space:]]*$ ]]; then
        echo -e "${YELLOW}No changes detected. Nothing to commit.${NC}"
        return 0
    fi

    local prompt="You are a specialized assistant in generating Git commit messages based on code changes.

Analyze the following changes and generate a commit message following these rules:

1. Use the conventional format: type(scope): description
2. Types: feat, fix, docs, style, refactor, test, chore
3. Be specific and descriptive
4. Maximum 72 characters on the first line
5. Add explanatory body if necessary (no more than 3 lines)


CHANGES:
$changes
$([ -n "$custom_note" ] && echo "
USER NOTE: $custom_note")

Generate ONLY the commit message, without additional explanations or markdown formatting."

    local response
    response=$(call_llm "$prompt") || return 1

    echo -e "${BLUE}Suggested commit message:${NC}"
    echo -e "${MAGENTA}$response${NC}"
    echo ""

    if [ "$AUTO_COMMIT" == "true" ]; then
        git_commit "$response"
    else
        read -rp "Do you want to commit with this message? (y/n) [y]: " confirm
        if [[ "$confirm" != "n" && "$confirm" != "N" ]]; then
            git_commit "$response"
        else
            echo -e "${YELLOW}Commit skipped.${NC}"
        fi
    fi
}

# ===========================
# Generate daily report
# ===========================
generate_report() {
    check_project_initialized

    local changes="$1"
    local custom_note="${2:-}"

    if [ -z "$changes" ] || [[ "$changes" =~ ^[[:space:]]*$ ]]; then
        echo -e "${YELLOW}No changes detected. Nothing to generate report for.${NC}"
        return 0
    fi

    local today
    today=$(date '+%d/%m/%Y')

    local prompt="You are an experienced developer creating a daily work report.

Based on the code changes below, generate a professional summary of what was done today.

The report should:

1. Be in Brazilian Portuguese
2. Begin with a short executive paragraph summarizing the main deliverables
3. List the main tasks performed (use bullet points)
4. Mention important files/keys modified
5. Be professional, short, and objective
6. Tone: professional but human

CHANGES:
$changes
$([ -n "$custom_note" ] && echo "
ADDITIONAL NOTE: $custom_note")

Output format:
${today} - Resumo do dia
=====================

[Resumo executivo]

Principais atividades:
• [atividade 1]
• [atividade 2]
...

Arquivos modificados importantes:
• [arquivo 1]
...

Generate the report in the format above, without additional explanations or markdown."

    echo -e "${CYAN}Generating daily report...${NC}"
    local response
    response=$(call_llm "$prompt") || return 1

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}$response${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""

    if command -v xclip &>/dev/null; then
        read -rp "Copy to clipboard? (y/n) [y]: " copy_clip
        if [[ "$copy_clip" != "n" && "$copy_clip" != "N" ]]; then
            echo "$response" | xclip -selection clipboard
            info "Report copied to clipboard!"
        fi
    elif command -v pbcopy &>/dev/null; then
        read -rp "Copy to clipboard? (y/n) [y]: " copy_clip
        if [[ "$copy_clip" != "n" && "$copy_clip" != "N" ]]; then
            echo "$response" | pbcopy
            info "Report copied to clipboard!"
        fi
    fi

    read -rp "Save report to file? (y/n) [n]: " save_file
    if [[ "$save_file" == "y" || "$save_file" == "Y" ]]; then
        local report_file="daily-report-${today//\//_}.md"
        echo "$response" > "$report_file"
        info "Report saved to $report_file"
        log_history "REPORT: $report_file"
    fi
}

# ===========================
# Help
# ===========================
show_help() {
    echo "Git AI Assistant - Automação Inteligente para Git"
    echo ""
    echo "Usage: git-ai-assist <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init                     Initialize current project for AI assistant"
    echo "  gen-commit [note]        Generate smart commit message from changes"
    echo "  gen-report [note]        Generate daily report for Teams/Slack"
    echo "  see-alt                  Show current changes and diffs"
    echo "  config                   Reconfigure LLM provider and API key"
    echo "  history                  Show command history"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -v, --version            Show version"
    echo ""
    echo "Providers: Groq (default), OpenAI, xAI Grok"
}

# ===========================
# Main
# ===========================
main() {
    local version="1.0.0"

    # Check dependencies
    if ! command -v jq &>/dev/null; then
        die "jq is not installed. Install with: sudo apt install jq"
    fi
    if ! command -v curl &>/dev/null; then
        die "curl is not installed. Install with: sudo apt install curl"
    fi

    # Setup config first (needed for most commands)
    setup_config

    # No arguments → show help
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    case "$1" in
        init)
            setup_project
            ;;
        commit)
            commit
            ;;
        gen-commit)
            check_git_repository
            changes=$(see_alt)
            custom_note=""
            if [ -n "${2:-}" ]; then
                custom_note="$2"
            else
                echo -e "${YELLOW}Add a custom note? (y/n) [n]:${NC}"
                read -rp "" add_note
                if [[ "$add_note" == "y" || "$add_note" == "Y" ]]; then
                    read -rp "Your note: " custom_note
                fi
            fi
            generate_commit_message "$changes" "$custom_note"
            ;;
        gen-report)
            check_git_repository
            changes=$(see_alt)
            custom_note=""
            if [ -n "${2:-}" ]; then
                custom_note="$2"
            else
                echo -e "${YELLOW}Add a custom note? (y/n) [n]:${NC}"
                read -rp "" add_note
                if [[ "$add_note" == "y" || "$add_note" == "Y" ]]; then
                    read -rp "Your note: " custom_note
                fi
            fi
            generate_report "$changes" "$custom_note"
            ;;
        see-alt)
            see_alt
            ;;
        config)
            rm -f "$CONFIG_FILE"
            setup_config
            ;;
        history)
            if [ -f "$HISTORY_FILE" ]; then
                cat "$HISTORY_FILE"
            else
                info "No history found."
            fi
            ;;
        -h|--help)
            show_help
            ;;
        -v|--version)
            echo "$version"
            ;;
        *)
            die "Command '$1' not found. Run 'git-ai-assist --help' for usage."
            ;;
    esac
}

main "$@"