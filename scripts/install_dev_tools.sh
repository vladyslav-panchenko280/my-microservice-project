#!/bin/bash

PATTERN="command not found"

# Determine if the OS is macOS
OS_IS_MAC=false
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS_IS_MAC=true
fi

prepare_docker() {
    local out
    out=$(docker --version 2>&1)

    if echo "$out" | grep -q "$PATTERN"; then
        echo "Docker not found. Installing Docker..."
        if [[ "$OS_IS_MAC" == true ]]; then
            echo "Installing Docker on macOS..."
            brew install --cask docker
        else
            echo "Installing Docker on Linux..."
            sudo apt-get update
            sudo apt-get install -y docker.io
        fi
    else
        echo "Docker is already installed."
    fi
}

prepare_docker_compose() {
    local out
    out=$(docker-compose --version 2>&1)

    if echo "$out" | grep -q "$PATTERN"; then
        echo "Docker Compose not found. Installing Docker Compose..."
        if [[ "$OS_IS_MAC" == true ]]; then
            echo "Installing Docker Compose on macOS..."
            brew install docker-compose
        else
            echo "Installing Docker Compose on Linux..."
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi
    else
        echo "Docker Compose is already installed."
    fi
}

prepare_python_env() {
    local out
    out=$(python3 --version 2>&1)

    if echo "$out" | grep -q "command not found"; then
        echo "Python3 not found. Installing Python3..."
        if [[ "$OS_IS_MAC" == true ]]; then
            echo "Installing Python3 on macOS..."
            brew install python
        else
            echo "Installing Python3 on Linux..."
            sudo apt-get update
            sudo apt-get install -y python3 python3-venv python3-pip
        fi
    else
        # Check version
        version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
        major=$(echo $version | cut -d. -f1)
        minor=$(echo $version | cut -d. -f2)
        if [ "$major" -gt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -ge 9 ]; }; then
            echo "Python $version ≥ 3.9 — update not required"
        else
            echo "Python $version < 3.9 — updating to latest version..."
            if [[ "$OS_IS_MAC" == true ]]; then
                brew install python
                brew upgrade python
            else
                sudo apt-get update
                sudo apt-get install -y python3 python3-venv python3-pip
            fi
        fi
    fi
}

create_venv() {
    if [ ! -d ".venv" ]; then
        python3 -m venv .venv
        echo "Virtual environment created."
    else
        echo "Virtual environment already exists."
    fi
}

install_django_tools() {
    source .venv/bin/activate
    echo -e "django\ndjango-debug-toolbar" > requirements.txt

    pip install -r requirements.txt
    
    deactivate
    echo "Django and Django Debug Toolbar installed in the virtual environment."
}


main() {
    prepare_docker

    prepare_docker_compose

    prepare_python_env

    create_venv

    install_django_tools

    echo "Development tools installation completed."
}

main