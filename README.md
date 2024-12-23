# CDN Asset Finder and Downloader

Utility script that finds and downloads CDN-hosted assets from your project files. It identifies assets from major CDN providers, checks their availability, and organizes downloads by vendor.

## Description

The script recursively searches through your project files for URLs pointing to CDN-hosted assets. It supports:
- Customizable file extensions to search
- Configurable directory exclusions
- Status code checking
- File size reporting
- Organized downloads by vendor
- CSS asset dependency resolution
- Verbose logging option

## Dependencies

- `bash` (version 3.2+)
- Either `curl` or `wget`
- Core Unix utilities: `grep`, `sed`, `awk`, `find`

## OS Compatibility

Tested and compatible with:
- macOS (10.15+)
- Ubuntu (18.04, 20.04)
- Debian-based Linux distributions

## Usage

Basic usage:
```bash
./cdn-downloader.sh
```

With options:
```bash
./cdn-downloader.sh --verbose --asset-dir=/path/to/downloads --exclude=node_modules,dist
```

Overriding default file extensions:
```bash
./cdn-downloader.sh --extensions=js,css,html,php
```

Overriding default excluded directories:
```bash
./cdn-downloader.sh --exclude-dirs=node_modules,vendor,dist
```

### Options

- `--verbose`: Enable detailed logging
- `--asset-dir=PATH`: Specify download directory (default: current directory)
- `--exclude=DIR1,DIR2`: Comma-separated list of paths to exclude
- `--extensions=EXT1,EXT2`: Comma-separated list of file extensions to search (default: html,jsx,js,css,php)
- `--exclude-dirs=DIR1,DIR2`: Comma-separated list of directories to exclude (default: node_modules,.git,dist,build)

## Examples

1. Search and download assets with verbose logging:
```bash
./cdn-downloader.sh --verbose --asset-dir=./cdn-assets
```

2. Search only JavaScript and CSS files:
```bash
./cdn-downloader.sh --extensions=js,css
```

3. Exclude specific directories and set custom download location:
```bash
./cdn-downloader.sh --exclude-dirs=node_modules,vendor --asset-dir=/var/www/assets
```

4. Search all file types except specific directories:
```bash
./cdn-downloader.sh --extensions=all --exclude-dirs=node_modules,vendor,dist
```