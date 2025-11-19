#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' 

print_error() {
    echo -e "${RED}$*${NC}"
}

print_success() {
    echo -e "${GREEN}$*${NC}"
}

print_warning() {
    echo -e "${YELLOW}$*${NC}"
}

print_info() {
    echo -e "${BLUE}$*${NC}"
}

print_debug() {
    echo -e "${CYAN}$*${NC}"
}

print_header() {
    echo -e "${MAGENTA}$*${NC}"
}

color_red() {
    echo -e "${RED}$*${NC}"
}

color_green() {
    echo -e "${GREEN}$*${NC}"
}

color_yellow() {
    echo -e "${YELLOW}$*${NC}"
}

color_blue() {
    echo -e "${BLUE}$*${NC}"
}

print_step() {
    echo -e "${BLUE}▶${NC} $*"
}

print_check() {
    echo -e "${GREEN}${NC} $*"
}

print_cross() {
    echo -e "${RED}${NC} $*"
}

print_arrow() {
    echo -e "${YELLOW}→${NC} $*"
}

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_subsection() {
    echo ""
    echo -e "${CYAN}--- $* ---${NC}"
    echo ""
}

