# flake.nix
{
  description = "ROG Ally X Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    plasma-manager.url = "https://github.com/nix-community/plasma-manager/archive/trunk.tar.gz";
  };

  outputs = { nixpkgs, jovian, nixos-hardware, nix-cachyos-kernel, home-manager, plasma-manager, nix-flatpak, ... }: {
    nixosConfigurations = {
      ally-nixos = nixpkgs.lib.nixosSystem { # Replace "hostname" with your system's hostname
        system = "x86_64-linux";
        specialArgs = { inherit nix-cachyos-kernel; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          jovian.nixosModules.default
          nixos-hardware.nixosModules.asus-ally-rc71l

          # nix-cachyos-kernel:
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
            boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;
          })

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = {
              yanumibaal = import ./home.nix;
            };
            home-manager.extraSpecialArgs = { inherit nix-flatpak; inherit plasma-manager; };
          }
        ];
      };
    };
  };
}

