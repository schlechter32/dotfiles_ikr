{
  description = "Devcontainer toolchain";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable-nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { nixpkgs, unstable-nixpkgs, neovim-nightly-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          neovim-nightly-overlay.overlays.default
          (final: _prev: {
            unstable = import unstable-nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          })
        ];
      };
      btopGpu = pkgs.btop.override {
        cudaSupport = true;
        rocmSupport = true;
      };
      runtimeLibs = with pkgs; [
        zlib
        zstd
        stdenv.cc.cc
        stdenv.cc.cc.lib
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd
      ];
      systemPython = pkgs.symlinkJoin {
        name = "system-python";
        paths = [ pkgs.python314 ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          lib_path="${pkgs.lib.makeLibraryPath runtimeLibs}"
          wrapProgram "$out/bin/python3.14" --prefix LD_LIBRARY_PATH : "$lib_path"
          wrapProgram "$out/bin/python3" --prefix LD_LIBRARY_PATH : "$lib_path"
          ln -sf "$out/bin/python3" "$out/bin/python"
        '';
      };
    in {
      packages.${system}.container-tools = pkgs.buildEnv {
        name = "container-tools";
        paths = with pkgs; [
          bat
          btopGpu
          cargo-binstall
          eza
          fd
          file
          fzf
          git
          git-lfs
          jq
          lazygit
          pass
          ripgrep
          starship
          tmux
          tmux-sessionizer
          uv
          xclip
          yazi
          zellij
          zoxide
          neovim-nightly-overlay.packages.${system}.default
          unstable.claude-code
          unstable.codex
          systemPython
        ] ++ runtimeLibs;
      };
    };
}
