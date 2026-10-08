{
  description = "Nixos config flake";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  
	zen-browser = {
      		url = "github:youwen5/zen-browser-flake";
      		inputs.nixpkgs.follows = "nixpkgs";
    	};
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: {
    extraSpecialArgs = {
       pkgs-unstable = import nixpkgs-unstable { system = "x86_64-linux"; };
    };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
