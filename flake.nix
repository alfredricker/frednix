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
    codex-cli.url = "github:sadjow/codex-cli-nix";
    sandhouse.url = "github:Rotomodo/sandhouse-nix-flake";
    sandhouse.inputs.nixpkgs.follows = "nixpkgs";
    # Fetched with submodules: this is also the source for pkgs/kytyps5.
    kytyps5.url = "git+https://github.com/KytyPS5/KytyPS5?submodules=1&shallow=1";
    kytyps5.inputs.nixpkgs.follows = "nixpkgs";
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
      # Upstream's dev shell, for hacking on the emulator itself:
      #   nix develop /etc/nixos#kytyps5
      devShells.x86_64-linux.kytyps5 = inputs.kytyps5.devShells.x86_64-linux.default;

      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.overlays = [
                inputs.claude-code.overlays.default
                inputs.codex-cli.overlays.default
                # KytyPS5 has no upstream package; build it from the flake input.
                (final: prev: {
                  kytyps5 = final.callPackage ./pkgs/kytyps5/package.nix { src = inputs.kytyps5; };
                })
                # Work around poetry 2.4.1 test failures on python 3.14 in
                # nixos-unstable (test_executor.py assertion mismatches).
                (final: prev: {
                  poetry = prev.poetry.overridePythonAttrs (old: {
                    disabledTests = (old.disabledTests or [ ]) ++ [
                      "test_execute_executes_a_batch_of_operations"
                      "test_execute_prints_warning_for_yanked_package"
                    ];
                  });
                })
              ];
            }
            ./system/configuration.nix
            nix-index-database.nixosModules.nix-index
            inputs.sandhouse.nixosModules.default
            { programs.sandhouse.enable = true; }

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
