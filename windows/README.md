# The Leap of Space for Windows

This folder is a small Tauri version of the SwiftUI game.

It uses:

- plain HTML
- plain CSS
- plain JavaScript
- Tauri only for the Windows app wrapper

There is no React, Vue, Vite, database, or plugin system. The files are meant to be easy to read and edit.

## Important files

- `app/index.html` has the screen layout.
- `app/styles.css` has the colours, spacing, and planet look.
- `app/app.js` has the game rules.
- `app/assets/data/planets.json` has the planet facts.
- `app/assets/data/questions.json` has the questions.
- `app/assets/images/astronaut.png` is the astronaut picture.

## Try it in a browser

```sh
make preview
```

Then open:

```text
http://localhost:4173
```

## Run with Tauri

Install Rust and Node.js first, then run:

```sh
make setup
make dev
```

## Build a Windows exe on Windows

The most reliable way is to run the build on a Windows computer:

```sh
make setup
make build
```

The finished installer and `.exe` files will be in:

```text
src-tauri/target/release/bundle/
```

## Build a Windows exe on a Mac

This is possible, but it is fussier than building on Windows. Tauri recommends this only when a Windows computer, Windows virtual machine, or GitHub Actions is not a good option.

This project uses the NSIS setup exe target because MSI installers can only be created on Windows.

Install the extra tools first:

```sh
brew install nsis llvm
rustup target add x86_64-pc-windows-msvc
cargo install --locked cargo-xwin
```

Then build:

```sh
make setup
make build-windows-on-mac
```

The Windows setup exe should land in:

```text
src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/
```

Building on Windows, or in a Windows GitHub Actions runner, is still simpler.
