.PHONY: setup dev build build-windows build-windows-on-mac mac-cross-help preview clean

setup:
	npm install

dev:
	npm run tauri -- dev

build:
	npm run tauri -- build

build-windows:
	@echo "To make a real Windows .exe, run this on Windows:"
	@echo "  make setup"
	@echo "  make build"
	@echo ""
	@echo "The finished files will be in src-tauri/target/release/bundle/"

build-windows-on-mac:
	npm run tauri -- build -- --runner cargo-xwin --target x86_64-pc-windows-msvc

mac-cross-help:
	@echo "Windows builds from macOS are possible, but they are fussier than building on Windows."
	@echo "Install these first:"
	@echo "  brew install nsis llvm"
	@echo "  rustup target add x86_64-pc-windows-msvc"
	@echo "  cargo install --locked cargo-xwin"
	@echo ""
	@echo "Then run:"
	@echo "  make setup"
	@echo "  make build-windows-on-mac"
	@echo ""
	@echo "The Windows setup exe should land in:"
	@echo "  src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/"

preview:
	python3 -m http.server 4173 --bind 127.0.0.1 --directory app

clean:
	cargo clean --manifest-path src-tauri/Cargo.toml
