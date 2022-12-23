{
  description = " Explore the Nix components relation through a generated web page";
  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      defaultPackage = forAllSystems (system: let
        pkgs = import nixpkgs { inherit system; };
      in pkgs.callPackage ./. {});
    };
}
