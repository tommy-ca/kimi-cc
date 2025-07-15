#!/bin/bash

set -e

install_nodejs() {
    local platform=$(uname -s)

    case "$platform" in
        Linux|Darwin)
            echo "🚀 Installing Node.js on Unix/Linux/macOS..."

            echo "📥 Downloading and installing nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

            echo "🔄 Loading nvm environment..."
            \. "$HOME/.nvm/nvm.sh"

            echo "📦 Downloading and installing Node.js v22..."
            nvm install 22

            echo -n "✅ Node.js installation completed! Version: "
            node -v
            echo -n "✅ Current nvm version: "
            nvm current
            echo -n "✅ npm version: "
            npm -v
            ;;
        *)
            echo "Unsupported platform: $platform"
            exit 1
            ;;
    esac
}

check_node() {
    if command -v node >/dev/null 2>&1; then
        local current_version=$(node -v | sed 's/v//')
        local major_version=$(echo "$current_version" | cut -d. -f1)
        if [ "$major_version" -ge 18 ]; then
            echo "Node.js is already installed: v$current_version"
        else
            echo "Node.js v$current_version is installed but version < 18. Upgrading..."
            install_nodejs
        fi
    else
        echo "Node.js not found. Installing..."
        install_nodejs
    fi
}

install_claude() {
    if command -v claude >/dev/null 2>&1; then
        echo "Claude Code is already installed: $(claude --version)"
    else
        echo "Claude Code not found. Installing..."
        npm install -g @anthropic-ai/claude-code
    fi
}

configure_skip_onboarding() {
    echo "Configuring Claude Code to skip onboarding..."
    node --eval '
        const fs = require("fs");
        const os = require("os");
        const path = require("path");
        const homeDir = os.homedir();
        const filePath = path.join(homeDir, ".claude.json");
        if (fs.existsSync(filePath)) {
            const content = JSON.parse(fs.readFileSync(filePath, "utf-8"));
            fs.writeFileSync(filePath, JSON.stringify({ ...content, hasCompletedOnboarding: true }, null, 2), "utf-8");
        } else {
            fs.writeFileSync(filePath, JSON.stringify({ hasCompletedOnboarding: true }, null, 2), "utf-8");
        }
    '
}

prompt_api_key() {
    echo "🔑 Please enter your API key for the selected provider:"
    echo "   (Input is hidden for security. Paste your API key directly.)"
    echo ""
    read -rs api_key
    echo ""
    if [ -z "$api_key" ]; then
        echo "⚠️  API key cannot be empty. Please run the script again."
        exit 1
    fi
}

select_provider() {
    echo "🌐 Select Claude API provider:" 
    echo " 1) Moonshot (default)"
    echo " 2) Anthropic"
    echo " 3) Custom URL"
    read -r -p "Choice [1]: " choice
    case "$choice" in
        2)
            api_base_url="https://api.anthropic.com/"
            ;;
        3)
            read -r -p "Enter the API base URL: " api_base_url
            ;;
        *)
            api_base_url="https://api.moonshot.cn/anthropic/"
            ;;
    esac
}

detect_rc_file() {
    local current_shell=$(basename "$SHELL")
    case "$current_shell" in
        bash)
            rc_file="$HOME/.bashrc"
            ;;
        zsh)
            rc_file="$HOME/.zshrc"
            ;;
        fish)
            rc_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            rc_file="$HOME/.profile"
            ;;
    esac
}

add_env_vars() {
    echo ""
    echo "📝 Adding environment variables to $rc_file..."
    if [ -f "$rc_file" ] && grep -q "ANTHROPIC_BASE_URL\|ANTHROPIC_API_KEY" "$rc_file"; then
        echo "⚠️ Environment variables already exist in $rc_file. Skipping..."
    else
        echo "" >> "$rc_file"
        echo "# Claude Code environment variables" >> "$rc_file"
        echo "export ANTHROPIC_BASE_URL=$api_base_url" >> "$rc_file"
        echo "export ANTHROPIC_API_KEY=$api_key" >> "$rc_file"
        echo "✅ Environment variables added to $rc_file"
    fi
}

finish_message() {
    echo ""
    echo "🎉 Installation completed successfully!"
    echo ""
    echo "🔄 Please restart your terminal or run:"
    echo "   source $rc_file"
    echo ""
    echo "🚀 Then you can start using Claude Code with:"
    echo "   claude"
}

main() {
    check_node
    install_claude
    configure_skip_onboarding
    select_provider
    prompt_api_key
    detect_rc_file
    add_env_vars
    finish_message
}

main "$@"
