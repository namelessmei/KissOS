# KissOS

A minimal, barebone template for cross-platform OS development with Assembly and C,
designed for macOS environments.

> [!CAUTION]
> The project is in its early stages and not yet ready for production or practical use.

## Components

- [ ] Bootloader
- [ ] Kernel Entry Point

## Requirement

To build and run KissOS, ensure the following tools are installed on your system:

- Homebrew
- NASM
- GNU Binutils
- QEMU

## Configuration

KissOS includes scripts for automating dependency installation and configuration:

1. Run the `autogen` script to set up the project environment:
```bash
./autogen
```

2. Configure the project using the provided `configure` script:
```bash
./configure
```

3. Build and run KissOS as described in the Makefile.

## Project Goals

KissOS aims to be a lightweight and portable operating system template, focusing on simplicity and avoiding unnecessary bloat.
It targets the x86_64 architecture and uses minimal external tools to keep the project straightforward and accessible.
Designed as a foundation for future OS projects and educational purposes.
KissOS provides clear, practical examples of essential components like the bootloader and kernel entry point.

## License

The project is licensed under the MIT License. See [LICENSE](./LICENSE) for more info.
