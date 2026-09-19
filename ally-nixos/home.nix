{ lib, pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      hello
    ];

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


    file.".config/autostart/steam.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Steam
      Exec=${pkgs.steam}/bin/steam -silent
      Terminal=false
    '';

    stateVersion = "26.11";
  };
}
