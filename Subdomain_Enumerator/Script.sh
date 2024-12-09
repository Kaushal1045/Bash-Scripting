#!/bin/bash

runme() {
    while read sub; do
        if host -t A "$sub.$domain" &>/dev/null; then
            echo "$sub.$domain"
        fi
    done < "$wordlist"
}

help() {
    echo "TOOL: Identify subdomains
Usage:
    -d DOMAIN : Provide the target domain
    -w WORDLIST : Provide the wordlist file
    -h/--help : Print help/usage

Example:
    ./script.sh -d domain.tld -w wordlist.txt
    "
}

# Verify dependencies
command -v host &>/dev/null || { echo "Error: 'host' command not found."; exit 1; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d)
            domain=$2
            shift 2
            ;;
        -w)
            wordlist=$2
            if [[ ! -f $wordlist ]]; then
                echo "Error: Wordlist must be a file."
                exit 12
            fi
            shift 2
            ;;
        -h|--help)
            help
            exit 0
            ;;
        *)
            echo "Error: Invalid argument '$1'. Use -h/--help for usage."
            exit 128
            ;;
    esac
done

# Check for required arguments
if [[ -z $domain || -z $wordlist ]]; then
    echo "Error: Both -d and -w are required arguments. Use -h/--help for usage."
    exit 9
fi

# Execute subdomain enumeration
runme
