# Subdomain Enumeration Script

This Bash script is designed to identify subdomains of a given domain using a wordlist. It checks each subdomain for a valid DNS "A" record and outputs the identified subdomains.

---

## Features

- Enumerates subdomains for a target domain.
- Uses a wordlist file to generate potential subdomains.
- Outputs valid subdomains with DNS "A" records.

---

## Requirements

1. **Bash**: Ensure you have Bash installed on your system.
2. **Host Command**: The script requires the `host` command for DNS queries. Install it if not already available:
   - On Debian-based systems: `sudo apt install dnsutils`
   - On Red Hat-based systems: `sudo yum install bind-utils`
3. **Wordlist File**: A wordlist file with potential subdomain names is required.

---

## Setup

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <repository-folder>
2. **Create a Wordlist File**:
     Create a file named wordlist.txt in the same directory as the script or in a specified location. Add potential subdomain names, one per line:
        plaintext
        Copy code
        www
        mail
        blog
        shop


## Usage

Run the script with the following syntax:
    ./script.sh -d <domain> -w <wordlist_path>

**Arguments**:

    -d: Specify the target domain (e.g., example.com).
    -w: Specify the path to the wordlist file.
    -h or --help: Display help and usage instructions.

**Example**:
    
    ./script.sh -d example.com -w ./wordlist.txt

    Target Domain: example.com
    Wordlist File: ./wordlist.txt (Ensure the correct path is provided.)

**Output**:

    The script will print the identified subdomains with valid DNS "A" records:
        www.example.com
        mail.example.com
        blog.example.com

## Notes:

Ensure the wordlist file exists and the path is correct before running the script.
If you encounter issues with dependencies (e.g., host command not found), refer to the Requirements section to resolve them.
