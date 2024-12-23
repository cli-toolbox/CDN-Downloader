# CDN Asset Finder and Downloader

Utility script that finds and downloads CDN-hosted assets from your project files. It identifies assets from major CDN providers, checks their availability, and organizes downloads by vendor.

## Installation

Using curl:
```bash
curl -o- https://raw.githubusercontent.com/cli-toolbox/CDN-Downloader/refs/heads/main/install.sh | bash
```

Using wget:
```bash
wget -qO- https://raw.githubusercontent.com/cli-toolbox/CDN-Downloader/refs/heads/main/install.sh | bash
```

After installation, close and reopen your terminal or source your profile:
```bash 
source ~/.bashrc  # or ~/.zshrc, ~/.profile, depending on your shell
```

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

## Supported CDN Providers

### JavaScript/CSS CDNs
- cdnjs.cloudflare.com
- cdn.jsdelivr.net
- unpkg.com
- code.jquery.com
- maxcdn.bootstrapcdn.com
- stackpath.bootstrapcdn.com
- ajax.googleapis.com
- ajax.aspnetcdn.com
- cdn.jsdelivr.net
- cdn.skypack.dev

### Font CDNs
- fonts.googleapis.com
- fonts.gstatic.com
- use.typekit.net
- use.fontawesome.com

### General Purpose CDNs
- Amazon CloudFront (*.cloudfront.net)
- Cloudflare (*.cloudflare.com)
- Akamai
- Fastly
- StackPath
- Google Cloud CDN
- Azure CDN
- Bunny.net
- KeyCDN

## Usage

Basic usage:
```bash
cdn-downloader
```

With options:
```bash
cdn-downloader --verbose --asset-dir=/path/to/downloads --exclude=node_modules,dist
```

Overriding default file extensions:
```bash
cdn-downloader --extensions=js,css,html,php
```

Overriding default excluded directories:
```bash
cdn-downloader --exclude-dirs=node_modules,vendor,dist
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
cdn-downloader --verbose --asset-dir=./cdn-assets
```

2. Search only JavaScript and CSS files:
```bash
cdn-downloader --extensions=js,css
```

3. Exclude specific directories and set custom download location:
```bash
cdn-downloader --exclude-dirs=node_modules,vendor --asset-dir=/var/www/assets
```

4. Search all file types except specific directories:
```bash
cdn-downloader --extensions=all --exclude-dirs=node_modules,vendor,dist
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Submit bug reports and feature requests at [Issues](https://github.com/cli-toolbox/CDN-Downloader/issues)
- Read the [Wiki](https://github.com/cli-toolbox/CDN-Downloader/wiki) for detailed documentation
- Ask questions in [Discussions](https://github.com/cli-toolbox/CDN-Downloader/discussions)