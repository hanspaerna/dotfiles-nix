{ lib, pkgs, nix-flatpak, ... }:

{
  imports = [
    # Import the nix-flatpak NixOS module and install applications system wide.
    # HomeManager users should import `${nix-flatpak}/modules/home-manager.nix`
    # where appropriate.
    "${nix-flatpak}/modules/home-manager.nix"
  ];

  home = {
    username = "yanumibaal";
    homeDirectory = "/home/yanumibaal";

    # Add "Return to Gaming Mode" desktop shortcut, like in Steam Deck
    file."Desktop/Return-to-Gaming-Mode.desktop".source =
      (pkgs.makeDesktopItem {
        desktopName = "Return to Gaming Mode";
        exec = "qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout";
        icon = "steam";
        name = "Return-to-Gaming-Mode";
        startupNotify = false;
        terminal = false;
        type = "Application";
      })
      + "/share/applications/Return-to-Gaming-Mode.desktop";

    # Automatically start Steam when going into Desktop mode
    file.".config/autostart/steam.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Steam
      Exec=${pkgs.steam}/bin/steam -silent
      Terminal=false
    '';

    # Automatically start Trayscale in Desktop mode
    file.".config/autostart/trayscale.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Trayscale
      Exec=${pkgs.trayscale}/bin/trayscale --hide-window
      Terminal=false
    '';

    # Do not touch
    stateVersion = "26.11";
  };

  # Use only if there is no other way to install an application
  services.flatpak = {
    enable = true;
    packages = [
      "net.retrodeck.retrodeck"
    ];
  };
}
