{ config, lib, pkgs, plasma-manager, nix-flatpak, ... }:


let
  username = "yanumibaal";
  dotfiles = "/home/${username}/dotfiles-nix/ally-nixos";
  wallpaperFolder = "${dotfiles}/assets/wallpapers";
  wallpaper = "${wallpaperFolder}/wallhaven-4yl377.png";
in
{
  imports = [
    # Import the nix-flatpak NixOS module and install applications system wide.
    # HomeManager users should import `${nix-flatpak}/modules/home-manager.nix`
    # where appropriate.
    "${nix-flatpak}/modules/home-manager.nix"
    plasma-manager.homeModules.plasma-manager
  ];

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";

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

    # Create a shortcut for saving the current HHD configuration back into the repo
    file."Desktop/Save-HHD-Settings.desktop".source =
      "${pkgs.makeDesktopItem {
        desktopName = "Save HHD Settings";
	exec = "${pkgs.writeShellScript "save-hhd-settings" ''
	  if ${pkgs.yad}/bin/yad \
	    --image dialog-question \
            --title="Save HHD Settings" \
	    --text="Overwrite the dotfiles HHD state with the current /etc/hhd/state.yml?" \
            --button="Cancel:1" \
	    --button="Save:0"
	  then
	    ${pkgs.coreutils}/bin/cp \
              /etc/hhd/state.yml \
              ${dotfiles}/config/hhd/state.yml
	    fi
	''}";
        icon = "hhd-ui";
	name = "Save-HHD-Settings";
	startupNotify = false;
	terminal = false;
	type = "Application";
    }}/share/applications/Save-HHD-Settings.desktop";

    # Do not touch
    stateVersion = "26.11";
  };

  #
  # symlinks
  #

  home.file = {
    "Steamapps".source = config.lib.file.mkOutOfStoreSymlink "/home/${username}/.steam/steam/steamapps";
  };

  home.file = {
    ".local/share/user-places.xbel".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/user-places.xbel";
    ".local/share/user-places.xbel".force = true;
  };

  #
  # end symlinks
  #

  # Use only if there is no other way to install an application
  services.flatpak = {
    enable = true;
    packages = [
      "net.retrodeck.retrodeck"
      "org.telegram.desktop"
    ];
  };

  programs.konsole = {
    enable = true;
    extraConfig = {
      "KonsoleWindow"."RememberWindowSize" = false;
    };
  };

  # Plasma Manager
  programs.plasma = {
    enable = true;

    overrideConfig = true;
    immutableByDefault = true;

    configFile."kdeglobals"."General"."AccentColor" = "233,187,122";

    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "breeze-dark";
      wallpaper = wallpaper;
      splashScreen = {
        engine = "none";
        theme = "None";
      };
    };

    kscreenlocker = {
      appearance.wallpaper = wallpaper;
    };

    kwin = {
      effects = {
        blur.enable = true;
        translucency.enable = true;
      };

      nightLight = {
        enable = true;
        location.latitude = "52.5";
        location.longitude = "13.4";
        mode = "location";
        temperature.night = 4000;
      };
    };

    panels = [
      {
        location = "bottom";
        floating = true;

        widgets = [
          {
            name = "org.kde.plasma.kickoff"; # Default start menu
            config = {
              General = {
                highlightNewlyInstalledApps = false;
                icon = "nix-snowflake-white";
              };
            };
          }
          "org.kde.plasma.pager" # Workspace switcher
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:firefox.desktop"
                  "applications:org.telegram.desktop.desktop"
                  "applications:org.kde.konsole.desktop"
                  "applications:supersonic.desktop"
                ];
              };
            };
          }
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.volume"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.battery"
              ];
              hidden = [
                "org.kde.plasma.weather"
              ];
            };
          }
          {
            digitalClock = {
              calendar.firstDayOfWeek = "monday";
              time.format = "24h";
              date.format.custom = "d.MM.yyyy";
            };
          } 
        ];
      }
    ];

    input = {
      keyboard = {
        layouts = [
          {
            layout = "us";
          }
          {
            layout = "ru";
          }
        ];
        options = ["grp:win_space_toggle"];
      };
    };

    session = {
      general.askForConfirmationOnLogout = false;
      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    };
  };

}

