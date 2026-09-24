{
  description = "Tanjun — Quickshell desktop shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      homeManagerModules.default = import ./nix/hm-module.nix { inherit self; };
      homeManagerModules.tanjun = self.homeManagerModules.default;

      nixosModules.default = import ./nix/nixos-module.nix;
      nixosModules.tanjun = self.nixosModules.default;

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./nix/package.nix { };
          tanjun-quickshell = self.packages.${system}.default;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
