#!/bin/bash

# Set default values
VERBOSE=false
DOWNLOADER=""
ASSET_DIR="."

# List of CDN providers
cdn_providers=(
    "cdn1.com"
    "cloudflare.com"
    "akamai.net"
    "maxcdn.bootstrapcdn.com"
    "fastly.net"
    "jsdelivr.net"
    "cdnjs.cloudflare.com"
    "unpkg.com"
    "stackpath.com"
    "bunnycdn.com"
    "keycdn.com"
    "cloudfront.net"
    "azureedge.net"
    "googleusercontent.com"
    "gstatic.com"
    "edgekey.net"
    "azure.net"
    "rackcdn.com"
    "cdn.jsdelivr.net"
)

# Initialize arrays
excluded_paths=()
FILE_EXTENSIONS=("html" "jsx" "js" "css" "php")
EXCLUDE_DIRS=("node_modules" ".git" "dist" "build")

# Logging function for verbose output
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[VERBOSE] $1" >&2
    fi
}

# Function to perform preliminary checks
preliminary_checks() {
    log_verbose "Starting preliminary checks..."

    # Check for curl or wget
    if type curl >/dev/null 2>&1; then
        DOWNLOADER="curl"
        log_verbose "Downloader 'curl' found."
    elif type wget >/dev/null 2>&1; then
        DOWNLOADER="wget"
        log_verbose "Downloader 'curl' not found. Falling back to 'wget'."
    else
        echo "Error: Neither 'curl' nor 'wget' is installed. Please install one to proceed." >&2
        exit 1
    fi

    # Build find exclusion expression
    find_exclude_expr=""
    if [ ${#excluded_paths[@]} -gt 0 ]; then
        log_verbose "Building exclusion patterns for find..."
        for path in "${excluded_paths[@]}"; do
            # Use sed compatible with older versions
            escaped_path=$(echo "$path" | sed 's/[]\.[^$*]/\\&/g')
            if [ -d "$path" ]; then
                find_exclude_expr="$find_exclude_expr -path './$escaped_path/*' -prune -o"
                log_verbose "Excluding directory: $path"
            else
                find_exclude_expr="$find_exclude_expr -path './$escaped_path' -prune -o"
                log_verbose "Excluding file: $path"
            fi
        done
    else
        log_verbose "No paths to exclude."
    fi

    # Build complete find expression
    find_expr="$find_exclude_expr -type f -print"
    log_verbose "Executing find command to list files..."
    file_count=$(eval "find . $find_expr" | wc -l)
    log_verbose "Number of files to be checked: $file_count"
    echo "Number of files to be checked: $file_count"

    if [ "$VERBOSE" = true ]; then
        if [ ${#excluded_paths[@]} -gt 0 ]; then
            echo "Excluding the following paths: ${excluded_paths[*]}"
        else
            echo "No paths are being excluded."
        fi
    fi
}

# Function to extract vendor name from URL
extract_vendor() {
    local url="$1"
    local path vendor filename

    # Remove protocol and domain
    path=$(echo "$url" | sed 's|^[^/]*//[^/]*/||')

    # Split path into segments
    IFS='/' read -ra segments <<< "$path"

    # Look for version pattern
    for segment in "${segments[@]}"; do
        if [[ "$segment" == *@* ]]; then
            vendor="${segment%%@*}"
            if [ -z "$vendor" ]; then
                filename=$(basename "$url" | cut -d'?' -f1 | cut -d'#' -f1)
                vendor="${filename%%.*}"
                vendor="${vendor//./_}"
            fi
            echo "$vendor"
            return
        fi
    done

    # Look for version number pattern
    local i
    for ((i=0; i<${#segments[@]}; i++)); do
        if [[ "${segments[i]}" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
            if [ "$i" -gt 0 ]; then
                vendor="${segments[i-1]}"
                vendor="${vendor//./_}"
                echo "$vendor"
                return
            fi
        fi
    done

    # Fallback to filename
    filename=$(basename "$url" | cut -d'?' -f1 | cut -d'#' -f1)
    vendor="${filename%%.*}"
    vendor="${vendor//./_}"
    echo "$vendor"
}

# Function to get HTTP status code
get_status_code() {
    local url="$1"
    local response

    if [ "$DOWNLOADER" = "curl" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    else
        response=$(wget --spider --server-response "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -1)
    fi
    echo "$response"
}

# Function to get filesize
get_filesize() {
    local url="$1"
    local content_length

    if [ "$DOWNLOADER" = "curl" ]; then
        content_length=$(curl -sI "$url" | grep -i '^content-length:' | awk '{print $2}' | tr -d '\r')
    else
        content_length=$(wget --spider --server-response "$url" 2>&1 | grep -i '^  Content-Length:' | awk '{print $2}' | tr -d '\r')
    fi

    if [ -n "$content_length" ]; then
        awk "BEGIN {printf \"%.2f\", $content_length/1024}"
    else
        echo "N/A"
    fi
}

# Function to download asset
download_asset() {
    local url="$1"
    local dest_dir="$2"
    local filename

    filename=$(basename "$url" | cut -d'?' -f1 | cut -d'#' -f1)
    mkdir -p "$dest_dir"
    log_verbose "Downloading asset: $url to $dest_dir/$filename"

    if [ "$DOWNLOADER" = "curl" ]; then
        curl -s -L -o "$dest_dir/$filename" "$url"
    else
        wget -q -O "$dest_dir/$filename" "$url"
    fi
}

# Function to download CSS assets
download_css_assets() {
    local css_file="$1"
    local css_url="$2"
    local css_dir base_url

    css_dir=$(dirname "$css_file")
    log_verbose "Parsing CSS file for assets: $css_file"

    base_url=$(echo "$css_url" | sed 's|/[^/]*$||')
    log_verbose "Base URL for relative assets: $base_url"

    # Use grep -E instead of grep -P for better compatibility
    grep -o 'url([^)]*)' "$css_file" | sed "s/url(\([\"']\)\(.*\)\1)/\2/" | sed 's/url(\([^)]*\))/\1/' | while read -r asset_url; do
        log_verbose "Found asset in CSS: $asset_url"

        # Skip data URLs
        if [[ "$asset_url" == data:* ]]; then
            log_verbose "Skipping data URL: $asset_url"
            continue
        fi

        # Handle absolute URLs
        if [[ "$asset_url" =~ ^https?:// ]]; then
            status_code=$(get_status_code "$asset_url")
            log_verbose "Status code for $asset_url: $status_code"
            if [ "$status_code" = "200" ]; then
                download_asset "$asset_url" "$css_dir"
            else
                log_verbose "Skipping $asset_url due to status code $status_code"
            fi
        else
            # Handle relative URLs
            asset_path=$(echo "$asset_url" | cut -d'?' -f1 | cut -d'#' -f1)
            base_url="${base_url%/}"
            asset_path="${asset_path#/}"
            full_url="$base_url/$asset_path"
            log_verbose "Resolved relative URL to: $full_url"

            status_code=$(get_status_code "$full_url")
            log_verbose "Status code for $full_url: $status_code"
            if [ "$status_code" = "200" ]; then
                download_asset "$full_url" "$css_dir/$(dirname "$asset_path")"
            else
                log_verbose "Skipping $full_url due to status code $status_code"
            fi
        fi
    done
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --exclude=*)
            IFS=',' read -ra excluded_paths <<< "${1#*=}"
            shift
            ;;
        --asset-dir=*)
            ASSET_DIR="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--exclude=path1,path2,...] [--verbose] [--asset-dir=/path/to/assets]" >&2
            exit 1
            ;;
    esac
done

# Run preliminary checks
preliminary_checks

# Escape CDN provider domains for regex
escaped_providers=()
for provider in "${cdn_providers[@]}"; do
    escaped_providers+=("$(echo "$provider" | sed 's/\./\\./g')")
done

# Build pattern for grep
pattern=$(IFS='|'; echo "${escaped_providers[*]}")
log_verbose "Compiled CDN regex pattern: $pattern"

# Create temporary file
temp_file=$(mktemp)
log_verbose "Created temporary file: $temp_file"
log_verbose "Searching for CDN URLs in files..."

# Find and process files
eval "find . $find_expr" | while IFS= read -r file; do
    log_verbose "Processing file: $file"
    grep -o 'https\?://[^[:space:]"'"'"'<]*' "$file" | while IFS= read -r url; do
        log_verbose "Found URL: $url in file: $file"
        if echo "$url" | grep -E "$pattern" >/dev/null; then
            vendor=$(extract_vendor "$url")
            status_code=$(get_status_code "$url")
            filesize=$(get_filesize "$url")
            echo "$file:$vendor:$status_code:$filesize:$url" >> "$temp_file"
            log_verbose "Recorded URL: $url with vendor: $vendor, status code: $status_code, filesize: $filesize KB"
        else
            log_verbose "URL $url does not match any CDN providers. Skipping."
        fi
    done
done

# Sort and deduplicate results
sort "$temp_file" | uniq > "${temp_file}.uniq"
mv "${temp_file}.uniq" "$temp_file"

# Check if any URLs were found
if [ ! -s "$temp_file" ]; then
    echo "No URLs containing the specified CDN providers were found."
    rm "$temp_file"
    exit 0
fi

# Display results
echo
echo "Found CDN URLs:"
cat "$temp_file"

# Generate summary
file_count=$(cut -d':' -f1 "$temp_file" | sort -u | wc -l)
assets_found=$(wc -l < "$temp_file")
status_breakdown=$(cut -d':' -f3 "$temp_file" | sort | uniq -c)

echo
echo "Summary:"
echo "--------"
echo "File Count: $file_count"
echo "Assets Found: $assets_found"
echo "Status Code Breakdown:"
echo "$status_breakdown"

# Handle asset downloads
download_dir="$ASSET_DIR"
if [ ! -d "$download_dir" ]; then
    printf "Directory '%s' does not exist. Create it? (y/N): " "$download_dir"
    read -r create_choice
    if [[ "$create_choice" =~ ^[Yy]$ ]]; then
        if ! mkdir -p "$download_dir"; then
            echo "Failed to create directory. Exiting." >&2
            rm "$temp_file"
            exit 1
        fi
        log_verbose "Created directory: $download_dir"
    else
        echo "Directory not created. Exiting."
        rm "$temp_file"
        exit 1
    fi
fi

printf "Would you like to proceed with downloading the assets to '%s'? (y/N): " "$download_dir"
read -r download_choice
if [[ ! "$download_choice" =~ ^[Yy]$ ]]; then
    echo "Download cancelled. Exiting."
    rm "$temp_file"
    exit 0
fi

echo
echo "Downloading assets to: $download_dir"
while IFS=: read -r file vendor status_code filesize url; do
    if [ "$vendor" != "N/A" ] && [ "$status_code" = "200" ]; then
        vendor_dir="$download_dir/$vendor"
        mkdir -p "$vendor_dir"
        log_verbose "Downloading $url to $vendor_dir"
        download_asset "$url" "$vendor_dir"
        if [[ "$url" == *.css ]]; then
            downloaded_css="$vendor_dir/$(basename "$url" | cut -d'?' -f1 | cut -d'#' -f1)"
            download_css_assets "$downloaded_css" "$url"
        fi
    else
        [ "$VERBOSE" = true ] && echo "[VERBOSE] Skipping download for $url due to status code $status_code or undefined vendor."
    fi
done < "$temp_file"

echo "Assets have been downloaded."

# Cleanup
rm "$temp_file"
log_verbose "Removed temporary file: $temp_file"