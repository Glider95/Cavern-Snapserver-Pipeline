# Changelog

All notable changes to the Cavern Snapserver Pipeline project will be documented in this file.

## [Unreleased] - 2024-09-19

### Added
- **Project Structure Reorganization**: Complete reorganization of the repository structure for better maintainability
- **Comprehensive Documentation**: Added detailed README.md with usage instructions and architecture overview
- **Documentation Directory**: Created `docs/` directory with detailed guides:
  - `ARCHITECTURE.md`: System architecture and component interaction
  - `INSTALLATION.md`: Step-by-step installation guide
  - `CONFIGURATION.md`: Configuration options and tuning guide
- **Organized Source Code**: Moved all source code to `src/` directory
  - `src/audio-processor/`: Main audio processing application
  - `src/pipe-utilities/`: Helper utilities for data flow
- **Configuration Management**: Centralized configuration files in `config/` directory
  - `asound.conf.example`: ALSA configuration template
  - `cavern-pipeline.service`: Systemd service configuration
- **Script Organization**: Moved all scripts to `scripts/` directory
  - `install.sh`: Automated installation script
  - `run_pipeline.sh`: Main pipeline execution script
  - `demo_run_pipeline.sh`: Demo/testing script
- **Proper .gitignore**: Added comprehensive .gitignore for build artifacts and temporary files

### Changed
- **Directory Structure**: Reorganized from flat structure to hierarchical organization
- **Script Paths**: Updated all scripts to work with new directory structure
- **Installation Process**: Modified install script to work with new organization
- **Documentation**: Migrated from inline comments to comprehensive documentation files

### Removed
- **Backup Files**: Removed duplicate `.backup.sh` files
- **Temporary Files**: Cleaned up temporary configuration files
- **Root Directory Clutter**: Moved files from root to appropriate subdirectories

### Technical Details

#### Before (Old Structure)
```
├── FifoToPipe/Program.cs
├── PipeToFifo/Program.cs
├── audio-processor/src/
├── demo_run_pipeline.backup.sh
├── demo_run_pipeline.sh
├── asound.conf.tmp
└── linux-arm64/
    ├── bin/
    ├── install.sh
    ├── run_pipeline.sh
    └── cavern-pipeline.service
```

#### After (New Structure)
```
├── README.md
├── config/
│   ├── asound.conf.example
│   └── cavern-pipeline.service
├── docs/
│   ├── ARCHITECTURE.md
│   ├── CONFIGURATION.md
│   └── INSTALLATION.md
├── scripts/
│   ├── demo_run_pipeline.sh
│   ├── install.sh
│   └── run_pipeline.sh
├── src/
│   ├── audio-processor/
│   └── pipe-utilities/
└── linux-arm64/bin/
```

#### Migration Benefits
- **Clarity**: Clear separation of source code, documentation, configuration, and binaries
- **Maintainability**: Easier to locate and modify specific components
- **Documentation**: Comprehensive guides for installation, configuration, and architecture
- **Standard Layout**: Follows common open-source project conventions
- **Developer Experience**: Improved onboarding for new contributors

#### Breaking Changes
- **Path Updates**: Scripts now use relative paths from new locations
- **Installation Process**: Install script updated to copy from new structure
- **Configuration References**: Documentation references updated configuration file locations

### Migration Guide

If upgrading from the old structure:

1. **Pull Latest Changes**: `git pull origin main`
2. **Review New Structure**: Familiarize yourself with new directory layout
3. **Update Local Scripts**: Any custom scripts should reference new paths
4. **Reinstall Service**: Run `sudo scripts/install.sh` to update installation
5. **Review Documentation**: Check new documentation for updated procedures

### Future Enhancements

- **Build System**: Consider adding proper build scripts for C# components
- **Containerization**: Docker support for easier deployment
- **Testing Framework**: Automated testing for pipeline components
- **Package Management**: Debian/RPM package creation for distribution