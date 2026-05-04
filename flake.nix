{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    musnix.url = "github:musnix/musnix";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      stylix,
      niri-flake,
      nix-index-database,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            {
            nixpkgs.overlays = [
              inputs.claude-code.overlays.default
              (final: prev: {
                tinymediamanager = final.callPackage ./pkgs/tinymediamanager.nix { };
              })
            ];
          }
            ./system/configuration.nix
            nix-index-database.nixosModules.nix-index

            # HOME MANAGER
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.sharedModules = [
                stylix.homeModules.stylix
                niri-flake.homeModules.niri
                inputs.nixvim.homeModules.nixvim
              ];
              home-manager.users.fred = ./home/home.nix;
            }
          ];
        };
      };
    };
}
