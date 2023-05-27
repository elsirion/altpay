{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, fenix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        fenixChannel = fenix.packages.${system}.stable;
        fenixToolchain = (fenixChannel.withComponents [
          "rustc"
          "cargo"
          "rustfmt"
          "clippy"
          "rust-analysis"
          "rust-src"
          "llvm-tools-preview"
        ]);
        craneLib = crane.lib.${system}.overrideToolchain fenixToolchain;
      in
    {
      # Once you actually want to build the project as a nix package, you can use this:
      packages.default = craneLib.buildPackage {
        src = craneLib.cleanCargoSource ./.;
        buildInputs = [];
        nativeBuildInputs = with pkgs; [ fenixToolchain pkgconfig openssl ];
        cargoVendorDir = craneLib.vendorCargoDeps { cargoLock = ./Cargo.lock; };
      };

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [ fenixToolchain ];
        RUST_SRC_PATH = "${fenixChannel.rust-src}/lib/rustlib/src/rust/library";
      };
    });
}
