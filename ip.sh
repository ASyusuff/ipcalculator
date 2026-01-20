#!/bin/bash

# IP Calculator - Lengkap dengan Network Address, Range, Broadcast, Netmask, Host, Block
# Usage: ./ipcalc.sh <IP/CIDR>

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fungsi untuk konversi IP ke desimal
ip_to_decimal() {
    local ip=$1
    local IFS='.'
    read -r a b c d <<< "$ip"
    echo $((a * 256**3 + b * 256**2 + c * 256 + d))
}

# Fungsi untuk konversi desimal ke IP
decimal_to_ip() {
    local num=$1
    echo "$((num >> 24 & 255)).$((num >> 16 & 255)).$((num >> 8 & 255)).$((num & 255))"
}

# Fungsi untuk konversi CIDR ke netmask
cidr_to_netmask() {
    local cidr=$1
    local mask=$((0xffffffff << (32 - cidr)))
    decimal_to_ip $mask
}

# Fungsi untuk konversi netmask ke CIDR
netmask_to_cidr() {
    local netmask=$1
    local num=$(ip_to_decimal "$netmask")
    local cidr=0
    local mask=$((0xffffffff))
    
    for ((i=0; i<32; i++)); do
        if [[ $((num & (1 << (31 - i)))) -ne 0 ]]; then
            ((cidr++))
        else
            break
        fi
    done
    echo $cidr
}

# Fungsi untuk mendapatkan wildcard mask
get_wildcard() {
    local netmask=$1
    local IFS='.'
    read -r a b c d <<< "$netmask"
    echo "$((255 - a)).$((255 - b)).$((255 - c)).$((255 - d))"
}

# Fungsi untuk mendapatkan class IP
get_ip_class() {
    local first_octet=$1
    if [[ $first_octet -ge 1 && $first_octet -le 126 ]]; then
        echo "A"
    elif [[ $first_octet -ge 128 && $first_octet -le 191 ]]; then
        echo "B"
    elif [[ $first_octet -ge 192 && $first_octet -le 223 ]]; then
        echo "C"
    elif [[ $first_octet -ge 224 && $first_octet -le 239 ]]; then
        echo "D (Multicast)"
    elif [[ $first_octet -ge 240 && $first_octet -le 255 ]]; then
        echo "E (Reserved)"
    else
        echo "Invalid"
    fi
}

# Fungsi untuk cek IP private
is_private() {
    local ip=$1
    local IFS='.'
    read -r a b c d <<< "$ip"
    
    if [[ $a -eq 10 ]]; then
        echo "Yes (Class A Private)"
    elif [[ $a -eq 172 && $b -ge 16 && $b -le 31 ]]; then
        echo "Yes (Class B Private)"
    elif [[ $a -eq 192 && $b -eq 168 ]]; then
        echo "Yes (Class C Private)"
    else
        echo "No (Public IP)"
    fi
}

# Fungsi untuk konversi IP ke binary
ip_to_binary() {
    local ip=$1
    local IFS='.'
    read -r a b c d <<< "$ip"
    
    # Konversi setiap oktet ke binary 8-bit
    local bin_a=$(printf "%08s" $(echo "obase=2; $a" | bc 2>/dev/null || echo "0") | tr ' ' '0')
    local bin_b=$(printf "%08s" $(echo "obase=2; $b" | bc 2>/dev/null || echo "0") | tr ' ' '0')
    local bin_c=$(printf "%08s" $(echo "obase=2; $c" | bc 2>/dev/null || echo "0") | tr ' ' '0')
    local bin_d=$(printf "%08s" $(echo "obase=2; $d" | bc 2>/dev/null || echo "0") | tr ' ' '0')
    
    echo "${bin_a}.${bin_b}.${bin_c}.${bin_d}"
}

# Fungsi untuk menampilkan header
print_header() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${NC}          ${GREEN}IP CALCULATOR - SUBNET INFORMATION${NC}     			 ${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo
}

# Main program
if [[ $# -eq 0 ]]; then
    echo -e "${RED}Usage: $0 <IP/CIDR> [output_file]${NC}"
    echo -e "${YELLOW}Example: $0 192.168.1.10/24${NC}"
    echo -e "${YELLOW}Example: $0 192.168.1.10/24 result.txt${NC}"
    echo -e "${YELLOW}Example: $0 10.0.0.0/8 subnet_info.txt${NC}"
    exit 1
fi

# Parse input
input=$1
output_file=$2
if [[ ! $input =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
    echo -e "${RED}Error: Invalid format. Use IP/CIDR notation (e.g., 192.168.1.0/24)${NC}"
    exit 1
fi

IP="${input%/*}"
CIDR="${input#*/}"

# Validasi CIDR
if [[ $CIDR -lt 0 || $CIDR -gt 32 ]]; then
    echo -e "${RED}Error: CIDR must be between 0 and 32${NC}"
    exit 1
fi

# Validasi IP
IFS='.' read -r a b c d <<< "$IP"
if [[ $a -gt 255 || $b -gt 255 || $c -gt 255 || $d -gt 255 ]]; then
    echo -e "${RED}Error: Invalid IP address${NC}"
    exit 1
fi

# Kalkulasi
NETMASK=$(cidr_to_netmask $CIDR)
WILDCARD=$(get_wildcard "$NETMASK")

# Konversi ke desimal
IP_DEC=$(ip_to_decimal "$IP")
MASK_DEC=$(ip_to_decimal "$NETMASK")

# Network Address
NETWORK_DEC=$((IP_DEC & MASK_DEC))
NETWORK=$(decimal_to_ip $NETWORK_DEC)

# Broadcast Address
WILDCARD_DEC=$(ip_to_decimal "$WILDCARD")
BROADCAST_DEC=$((NETWORK_DEC | WILDCARD_DEC))
BROADCAST=$(decimal_to_ip $BROADCAST_DEC)

# Host Range
FIRST_HOST_DEC=$((NETWORK_DEC + 1))
LAST_HOST_DEC=$((BROADCAST_DEC - 1))
FIRST_HOST=$(decimal_to_ip $FIRST_HOST_DEC)
LAST_HOST=$(decimal_to_ip $LAST_HOST_DEC)

# Total hosts
TOTAL_IPS=$((2 ** (32 - CIDR)))
USABLE_HOSTS=$((TOTAL_IPS - 2))

if [[ $CIDR -eq 32 ]]; then
    USABLE_HOSTS=1
elif [[ $CIDR -eq 31 ]]; then
    USABLE_HOSTS=2
fi

# Subnet block size
BLOCK_SIZE=$TOTAL_IPS

# IP Class
IP_CLASS=$(get_ip_class $a)

# Private/Public
IP_TYPE=$(is_private "$IP")

# Binary representations
IP_BINARY=$(ip_to_binary "$IP")
NETMASK_BINARY=$(ip_to_binary "$NETMASK")
NETWORK_BINARY=$(ip_to_binary "$NETWORK")
BROADCAST_BINARY=$(ip_to_binary "$BROADCAST")

# Fungsi untuk membuat output
generate_output() {
    local use_color=$1
    local output=""
    
    if [[ $use_color -eq 1 ]]; then
        output+="$(echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}")\n"
        output+="$(echo -e "${CYAN}${NC}    ${GREEN}IP CALCULATOR - SUBNET INFORMATION${NC}               ${NC}")\n"
        output+="$(echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}")\n"
        output+="\n"
        
        output+="$(echo -e "${YELLOW}┌─ INPUT INFORMATION${NC}")\n"
        output+="$(echo -e "${YELLOW}├──────────────────────────────────────────────────────────────${NC}")\n"
        output+="$(printf "%-25s : ${GREEN}%s${NC}\n" "IP Address" "$IP")\n"
        output+="$(printf "%-25s : ${GREEN}%s${NC}\n" "CIDR Notation" "/$CIDR")\n"
        output+="\n"
        
        output+="$(echo -e "${YELLOW}┌─ NETWORK INFORMATION${NC}")\n"
        output+="$(echo -e "${YELLOW}├──────────────────────────────────────────────────────────────${NC}")\n"
        output+="$(printf "%-25s : ${BLUE}%s${NC}\n" "Network Address (NA)" "$NETWORK")\n"
        output+="$(printf "%-25s : ${BLUE}%s${NC}\n" "Broadcast Address (BA)" "$BROADCAST")\n"
        output+="$(printf "%-25s : ${BLUE}%s${NC}\n" "Netmask" "$NETMASK")\n"
        output+="$(printf "%-25s : ${BLUE}%s${NC}\n" "Wildcard Mask" "$WILDCARD")\n"
        output+="$(printf "%-25s : ${BLUE}%s${NC}\n" "CIDR" "/$CIDR")\n"
        output+="\n"
        
        output+="$(echo -e "${YELLOW}┌─ HOST INFORMATION${NC}")\n"
        output+="$(echo -e "${YELLOW}├──────────────────────────────────────────────────────────────${NC}")\n"
        output+="$(printf "%-25s : ${GREEN}%s${NC}\n" "First Usable Host" "$FIRST_HOST")\n"
        output+="$(printf "%-25s : ${GREEN}%s${NC}\n" "Last Usable Host" "$LAST_HOST")\n"
        output+="$(printf "%-25s : ${GREEN}%s${NC}\n" "Total IP Addresses" "$TOTAL_IPS")\n"
        output+="$(printf "%-25s : ${GREEN}%s${NC}\n" "Usable Hosts" "$USABLE_HOSTS")\n"
        output+="$(printf "%-25s : ${GREEN}%s${NC}\n" "Subnet Block Size" "$BLOCK_SIZE")\n"
        output+="\n"
        
        output+="$(echo -e "${YELLOW}┌─ IP CLASSIFICATION${NC}")\n"
        output+="$(echo -e "${YELLOW}├──────────────────────────────────────────────────────────────${NC}")\n"
        output+="$(printf "%-25s : ${CYAN}%s${NC}\n" "IP Class" "$IP_CLASS")\n"
        output+="$(printf "%-25s : ${CYAN}%s${NC}\n" "Private/Public" "$IP_TYPE")\n"
        output+="\n"
        
        output+="$(echo -e "${YELLOW}┌─ BINARY REPRESENTATION${NC}")\n"
        output+="$(echo -e "${YELLOW}├──────────────────────────────────────────────────────────────${NC}")\n"
        output+="$(printf "%-25s : %s\n" "IP Address" "$IP_BINARY")\n"
        output+="$(printf "%-25s : %s\n" "Netmask" "$NETMASK_BINARY")\n"
        output+="$(printf "%-25s : %s\n" "Network Address" "$NETWORK_BINARY")\n"
        output+="$(printf "%-25s : %s\n" "Broadcast Address" "$BROADCAST_BINARY")\n"
        output+="\n"
        
        output+="$(echo -e "${YELLOW}┌─ SUBNET RANGE${NC}")\n"
        output+="$(echo -e "${YELLOW}├──────────────────────────────────────────────────────────────${NC}")\n"
        output+="$(printf "%-25s : ${GREEN}%s - %s${NC}\n" "Network Range" "$NETWORK" "$BROADCAST")\n"
        output+="$(printf "%-25s : ${GREEN}%s - %s${NC}\n" "Usable Host Range" "$FIRST_HOST" "$LAST_HOST")\n"
        output+="\n"
        
        output+="$(echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}")\n"
    else
        output+="================================================================\n"
        output+="          IP CALCULATOR - SUBNET INFORMATION\n"
        output+="================================================================\n"
        output+="\n"
        
        output+="--- INPUT INFORMATION ---\n"
        output+="$(printf "%-25s : %s\n" "IP Address" "$IP")\n"
        output+="$(printf "%-25s : %s\n" "CIDR Notation" "/$CIDR")\n"
        output+="\n"
        
        output+="--- NETWORK INFORMATION ---\n"
        output+="$(printf "%-25s : %s\n" "Network Address (NA)" "$NETWORK")\n"
        output+="$(printf "%-25s : %s\n" "Broadcast Address (BA)" "$BROADCAST")\n"
        output+="$(printf "%-25s : %s\n" "Netmask" "$NETMASK")\n"
        output+="$(printf "%-25s : %s\n" "Wildcard Mask" "$WILDCARD")\n"
        output+="$(printf "%-25s : %s\n" "CIDR" "/$CIDR")\n"
        output+="\n"
        
        output+="--- HOST INFORMATION ---\n"
        output+="$(printf "%-25s : %s\n" "First Usable Host" "$FIRST_HOST")\n"
        output+="$(printf "%-25s : %s\n" "Last Usable Host" "$LAST_HOST")\n"
        output+="$(printf "%-25s : %s\n" "Total IP Addresses" "$TOTAL_IPS")\n"
        output+="$(printf "%-25s : %s\n" "Usable Hosts" "$USABLE_HOSTS")\n"
        output+="$(printf "%-25s : %s\n" "Subnet Block Size" "$BLOCK_SIZE")\n"
        output+="\n"
        
        output+="--- IP CLASSIFICATION ---\n"
        output+="$(printf "%-25s : %s\n" "IP Class" "$IP_CLASS")\n"
        output+="$(printf "%-25s : %s\n" "Private/Public" "$IP_TYPE")\n"
        output+="\n"
        
        output+="--- BINARY REPRESENTATION ---\n"
        output+="$(printf "%-25s : %s\n" "IP Address" "$IP_BINARY")\n"
        output+="$(printf "%-25s : %s\n" "Netmask" "$NETMASK_BINARY")\n"
        output+="$(printf "%-25s : %s\n" "Network Address" "$NETWORK_BINARY")\n"
        output+="$(printf "%-25s : %s\n" "Broadcast Address" "$BROADCAST_BINARY")\n"
        output+="\n"
        
        output+="--- SUBNET RANGE ---\n"
        output+="$(printf "%-25s : %s - %s\n" "Network Range" "$NETWORK" "$BROADCAST")\n"
        output+="$(printf "%-25s : %s - %s\n" "Usable Host Range" "$FIRST_HOST" "$LAST_HOST")\n"
        output+="\n"
        
        output+="================================================================\n"
    fi
    
    echo -e "$output"
}

# Display hasil di terminal dengan warna
generate_output 1

# Jika ada parameter output file, simpan tanpa warna
if [[ -n $output_file ]]; then
    generate_output 0 > "$output_file"
    echo -e "${GREEN}✓ Output saved to: $output_file${NC}"
fi
