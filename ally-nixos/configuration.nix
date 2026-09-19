# configuration.nix
{ config, lib, pkgs, ... }:

{
  # {BOOT}
  # {{{

  # Set kernel to use
  # boot.kernelPackages = pkgs.linux_jovian; # currently set in flake.nix
  # activate ntsync module, preload hid drivers to prevent race condition
  boot.kernelModules = [ "ntsync" "hid_nintendo" "hid_playstation" ];
  services.scx.enable = true; # by default uses scx_rustland scheduler
  # services.scx.scheduler = "scx_rusty"; # jovian's steam.nix module sets this to "scx_lavd"

  # Enable SysRq key and BORE scheduler
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.split_lock_mitigate" = 0;
    "kernel.nmi_watchdog"        = 0;
    "kernel.sched_bore"          = "1";
    };

  # Use the systemd-boot EFI boot loader with quiet, graphical boot
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = true;
    kernelParams = [
      "quiet"
      "amd_pstate=active"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "amdgpu.gttsize=8128"
    ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        configurationLimit = 10;
        enable = true;
      };
      timeout = 5;
    };
    plymouth.enable = false; # Incompatible with unl0kr
    initrd.unl0kr.enable = true;
  };

  # Make performance-related device attributes controllable by users.
  services.udev.extraRules = ''
    # Enables manual GPU clock control in Steam
    # - /sys/class/drm/card0/device/power_dpm_force_performance_level
    # - /sys/class/drm/card0/device/pp_od_clk_voltage
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="amdgpu", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/%p/power_dpm_force_performance_level /sys/%p/pp_od_clk_voltage"

    # https://github.com/ublue-os/bazzite/blob/f5f033424281f88f0a132ec0561a5a5f002faf24/system_files/deck/shared/usr/lib/udev/rules.d/50-ally-fingerprint.rules
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{idVendor}=="1c7a", ATTR{idProduct}=="0588", ATTR{power/control}="auto"
    '';

  # Create swapfile
  swapDevices = [{
    device = "/var/swapfile";
    size = 20*1024; # 20GB for hibernate
  }];

  # }}}

  # {NETWORKING}
  # {{{

  # Define your hostname.
  networking.hostName = "ally-nixos";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Disable firewall, open all ports
  networking.firewall.enable = false;

  # }}}

  # {LOCALE}
  # {{{

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  # Steam IME uses/requires ibus
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ table-chinese pinyin anthy hangul mozc ];
    ibus.panel = "${pkgs.kdePackages.plasma-desktop}/libexec/kimpanel-ibus-panel";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # }}}

  # {DRIVERS}
  # {{{

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        MultiProfile     = "multiple";
        FastConnectable  = true;
      };
    };
  };

  # Setup graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # OpenCL support using the ROCM runtime library
  # hardware.amdgpu.opencl.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true; # If you want to use JACK applications, uncomment this
  };

  # Enable udev rules for Steam hardware such as the Steam Controller
  hardware.steam-hardware.enable = true;
  # Enable the xone driver for Xbox One and Xbox Series X / S accessories
  # (disabled due to the kernel module tend to cause build fail)
  # hardware.xone.enable = true;
  # Enable uinput support
  hardware.uinput.enable = true;

  # }}}

  # {DESKTOP ENVIRONMENT}
  # {{{

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;
  programs.kdeconnect.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.displayManager.startx.enable = true; # Needed for x11 desktop mode

  # Configure SDDM with wayland as defaults
  services.displayManager = {
    sddm = {
      # enable = lib.mkForce false; # cannot use with jovian gamescope session
      enable = true;
      wayland.enable = true;
      settings.General.DisplayServer = "wayland"; # "wayland" or "x11-user"
    };
    defaultSession = "gamescope-wayland"; # "gamescope-wayland" for jovian game mode, "plasma" or "plasmax11" for desktop mode
    autoLogin = {
      enable = true;
      user = "yanumibaal";
    };
  };

  # Enable Flatpak
  xdg.portal.enable = true; # only needed if you are not using Gnome
  services.flatpak.enable = true; # optional

  # }}}

  # {STEAM}
  # {{{

  # Enable Gamescope (not needed with Jovian)
  # programs.gamescope = {
  #   enable = true;
  #   capSysNice = true;
  # };

  # Enable Steam
  programs.steam = {
    enable = true;
    package = pkgs.steam.override { # adds needed xorg library for nested gamescope
      extraPkgs = pkgs': with pkgs'; [
        xorg.libXcursor xorg.libXi xorg.libXinerama xorg.libXScrnSaver
        libpng libpulseaudio libvorbis
        stdenv.cc.cc.lib # Provides libstdc++.so.6
        libkrb5 keyutils # Add other libraries as needed
      ];
    };
    # Manual, non-jovian gamescope
    # see https://wiki.nixos.org/wiki/Steam
    # gamescopeSession = { # Integrates Game Mode with Steam
    #   enable = true;
    #   env = {};
    #   args = [ "-W 1920" "-H 1080" "-f" "-e" "--xwayland-count 2" "--hdr-enabled" "--hdr-itm-enabled" ];
    #   steamArgs = [ "-pipewire-dmabuf" "-gamepadui" "-steamdeck" "-steamos3" ];
    # };
    protontricks.enable = true; #  Enable protontricks.
    extest.enable = false; # Make sure extest is disabled since currently it causes issues.
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers.
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    extraCompatPackages = with pkgs; [ # additional compatibility packages
      steamtinkerlaunch thcrap-steam-proton-wrapper
      # other runners tended to be redundant as non-Steam launchers can't access them
    ];
  };

  # Enable Jovian
  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "yanumibaal";
      updater.splash = "steamos"; #  one of "steamos", "jovian", "bgrt", "vendor" for splash screen when launching Steam.
    };
    hardware.has.amd.gpu = true; # https://jovian-experiments.github.io/Jovian-NixOS/options.html
    steamos.useSteamOSConfig = true; # https://jovian-experiments.github.io/Jovian-NixOS/options.html#jovian.steamos.useSteamOSConfig
    steamos.enableZram = false; # conflicts with swap
    steam.desktopSession = "plasma"; # "plasma" or "plasmax11"
    decky-loader = {
      enable = true; # make sure to enable CEF debugging
      user = "yanumibaal";
      extraPackages = with pkgs; [ ryzenadj ];
    };
  };

  # Set game launcher: gamemoderun %command%
  #   Set this for each game in Steam, if the game could benefit from a minor
  #   performance tweak: YOUR_GAME > Properties > General > Launch > Options
  #   It's a modest tweak that may not be needed. Jovian is optimized for
  #   high performance by default.

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility"; # For systems with AMD GPUs
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  # Install and configure handheld-daemon.
  services.handheld-daemon = {
    enable = true;
    user = "yanumibaal";
    ui.enable = true;
    adjustor.enable = true; # Enable Handheld Daemon TDP control plugin.
    adjustor.loadAcpiCallModule = true; # Load the acpi_call kernel module. Required for TDP control by adjustor on most devices.
    };

  # Disable InputPlumber ROG Ally input support to avoid HHD conflict
  services.inputplumber.enable = lib.mkForce false; # use 'lib.mkForce false;' in case of Jovian
  # Disable PowerStation TDP control support to avoid HHD conflict
  services.powerstation.enable = false;
  # Enable asusd
  services.asusd.enable = true;

  # Disable PPD and TuneD to avoid conflict with HHD power profile management (optional)
  # services.power-profiles-daemon.enable = false;
  services.tuned.enable = false;

  # Environment variables for Steamm
  environment.sessionVariables = {
    PROTON_USE_NTSYNC       = "1";
    ENABLE_HDR_WSI          = "1";
    DXVK_HDR                = "1";
    PROTON_ENABLE_AMD_AGS   = "1";
    PROTON_ENABLE_NVAPI     = "1";
    ENABLE_GAMESCOPE_WSI    = "1";
    STEAM_MULTIPLE_XWAYLANDS = "1";

    STEAMOS_NESTED_DESKTOP_WIDTH  = "1920";
    STEAMOS_NESTED_DESKTOP_HEIGHT = "1080";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.local/share/Steam/compatibilitytools.d";
  };

  # Enable CEF debugging for decky-loader
  systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
    description = "Create Steam CEF debugging file";
    serviceConfig = {
      Type = "oneshot";
      User = config.jovian.steam.user;
      ExecStart = "/bin/sh -c 'mkdir -p ~/.steam/steam && [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true'";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # }}}

  # {User Setup}
  # {{{

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.yanumibaal = {
    isNormalUser = true;
    description = "Hans Paerna";
    extraGroups = [ "yanumibaal" "networkmanager" "wheel" "podman" "libvirtd" "gamemode" "docker" "video" "seat" "audio" "uinput" "decky" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Environment variables
  environment.sessionVariables = {
    XDG_CACHE_HOME  = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_STATE_HOME  = "$HOME/.local/state";
  };

  # }}}

  # {Packages}
  # {{{

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = _: true; # needed for flakes
  # Allow insecure packages
  # RECHECK what needs them later with nix-tree!
  # nixpkgs.config.permittedInsecurePackages = [ ];

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    # background system packages
    cmake busybox
    xdg-utils desktop-file-utils
    wl-clipboard wl-clipboard-x11
    libwebp libva libva-utils libvpx # codecs

    # CLI tools
    vim htop
    dust nix-du graphviz # nix tools
    git git-credential-manager gh github-desktop # build tools
    grc highlight # text coloring
    firejail # sandboxing
    wget aria2 rsync zsync # file transfer tools
    appimage-run inxi chezmoi sqlitebrowser rmtrash unrar xdg-ninja chkcrontab # CLI utils
    file ryzenadj # other dependencies

    # KDE packages
    kdePackages.kcron kdePackages.fcitx5-configtool # kdePackages.sddm-kcm
    kdePackages.partitionmanager kdePackages.filelight
    kdePackages.kate kdePackages.kcharselect kdePackages.kcalc kdePackages.kcolorchooser
    kdePackages.kontrast kdePackages.arianna haruna krename

    firefox # browser
    # CuboCore.corekeyboard # on-screen keyboad (x11 only)

    # Gaming
    # wineWowPackages.stagingFull dxvk winetricks umu-launcher-unwrapped # wine
    protonup-qt sgdboop # steam-rom-manager # steam management
    # lutris heroic # game management (use wrapped version so executable can run in the fhs env)
    # faugus-launcher (pkgs.bottles.override { removeWarningPopup = true; }) # nero-umu # wine launchers
    # scanmem # installs GameConqueror
    mangohud # performance overlay

    maliit-keyboard maliit-framework

    # Create an FHS environment using the command `fhs`, enabling the execution of non-NixOS packages in NixOS!
    (let base = pkgs.appimageTools.defaultFhsEnvArgs; in
      pkgs.buildFHSEnv (base // {
      name = "fhs";
      targetPkgs = pkgs:
        # pkgs.buildFHSEnv provides only a minimal FHS environment,
        # lacking many basic packages needed by most software.
        # Therefore, we need to add them manually.
        #
        # pkgs.appimageTools provides basic packages required by most software.
        (base.targetPkgs pkgs) ++ (with pkgs; [
          pkg-config
          ncurses
          # Feel free to add more packages here if needed.
        ]
      );
      profile = "export FHS=1";
      runScript = "bash";
      extraOutputsToInstall = ["dev"];
    }))
  ];
  

  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd = { # enable for virtual machine support
      enable = true; # use libvirtd for qemu/kvm
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ]; # enable shared folder with guest,
    };
    containers.enable = true; # enable containers support for distrobox support
    podman = {
      enable = true; # use podman for containers
      dockerCompat = true; # help compatibility with Docker
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
    waydroid.enable = false; # wayland-based android virtualizer
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Fix for /bin/bash scripts
  services.envfs.enable = true;
  # Needed to run non-NixOS binary (optionally used with nix-alien)
  # programs.nix-ld.enable = true;
  # Registers AppImage files to be run with appimage-run as interpreter
  programs.appimage = { enable = true; binfmt = true; };

  # Install firefox.
  programs.firefox.enable = true;

  # Device off commands without sudo
  security.sudo = {
  enable = true;
  extraRules = [{
    commands = [
      {
        command = "${pkgs.systemd}/bin/systemctl suspend";
        options = [ "NOPASSWD" ];
      }
      {
        command = "${pkgs.systemd}/bin/reboot";
        options = [ "NOPASSWD" ];
      }
      {
        command = "${pkgs.systemd}/bin/poweroff";
        options = [ "NOPASSWD" ];
      }
    ];
    groups = [ "wheel" ];
  }];
  extraConfig = with pkgs; ''
    Defaults:picloud secure_path="${lib.makeBinPath [
      systemd
    ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
  '';
};

  # }}}

  # {NIX}
  # {{{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable garbage collection
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Binary cache
  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org" # nix-community
      "https://attic.xuyh0120.win/lantian" # nix-cachyos-kernel
      "https://ezkea.cachix.org" # an-anime-game-launcher
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
    ];
  };


  # DO NOT CHANGE FROM GENERATED DEFAULT
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.05"; # DO NOT CHANGE
  # }}}
}

