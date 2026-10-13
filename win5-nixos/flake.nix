# flake.nix
{
  description = "GPD Win 5 Configuration";

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
    libfprint-win5 = {
      url = "github:hanspaerna/libfprint-win5";
      flake = false;
    };
  };

  outputs = { nixpkgs, jovian, nixos-hardware, nix-cachyos-kernel, home-manager, plasma-manager, nix-flatpak, libfprint-win5,  ... }: {
    nixosConfigurations = {
      win5-nixos = nixpkgs.lib.nixosSystem { # Replace "hostname" with your system's hostname
        system = "x86_64-linux";
        specialArgs = { inherit nix-cachyos-kernel; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          jovian.nixosModules.default

          # nix-cachyos-kernel:
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
            boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;
          })


          {
            nixpkgs.overlays = [
              # libfprint does not include the fingerprint sensonr of GPD Win 5, but there is already a Realtek driver that should work
              (final: prev: {
                libfprint = prev.libfprint.overrideAttrs (old: { 
                  src = libfprint-win5; 
                  version = "1.94.100-win5";
                  patches = old.patches or [ ];
		  nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
		    final.python3
		  ]; 
		  postPatch = (old.postPatch or "") + ''
		    patchShebangs scripts/sync-unsupported-devices.py
		  ''; 
                });
              })
            ];
          }

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

