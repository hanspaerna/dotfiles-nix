{ lib, pkgs, ... }:

{
  # You do not need to change this if you're reading this in the future.
  # Don't ever change this after the first build.  Don't ask questions.

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

    stateVersion = "26.11";
  };
}
