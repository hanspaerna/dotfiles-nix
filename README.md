# dotfiles-nix

Put this repo directly into /home/yanumibaal (home-manager symlinks are tied to absolute paths due to an issue between relative paths and flakes).

## ally-nixos

A customization and continuation of this helpful repo: https://github.com/bayazidbh/nixos-configuration/tree/main/bbh-ally-nixos

### Quirks & manual steps

#### Steam/Proton

Some games (like Skyrim SE) require ProtonGE 11+ to appear in Plasma Wayland mode. 

#### Emulation

RetroDECK is distributed only via Flatpak, and running AppImage of an external emulator inside Flatpak environment is not an option in NixOS (flatpak-spawn is broken in Gaming mode, shows black screen). To solve this issue, you need to unpack AppImage (./emulator.AppImage --appimage-extract) of your emulator and symlink its unpacked folder into `/home/{user}/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/files/retrodeck/components/`. Create a launch script named ` for RetroDECK inside its folder:

```
#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

export LD_LIBRARY_PATH="$rd_shared_libs:$rd_shared_libs/org.freedesktop.Platform/24.08/:${DEFAULT_LD_LIBRARY_PATH}"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$component_path/bin/your_emulator" "$@"
```

Now add these elements into your `retrodeck/ES-DE/custom_systems/` folder:

- es_find_rules.xml

```
<ruleList>
    <emulator name="YOUR_EMULATOR">
        <rule type="staticpath">
            <entry>
                /app/retrodeck/components/your_emulator/component_launcher.sh
            </entry>
        </rule>
    </emulator>
</ruleList>
```

- es_systems.xml

```
<systemList>
    <system>
        <name>switch</name>
        <fullname>Nintendo Switch</fullname>
        <path>%ROMPATH%/switch</path>
        <extension>.nca .NCA .nro .NRO .nso .NSO .nsp .NSP .xci .XCI .7z .7Z .zip .ZIP</extension>
        <command label="Your_emulator">%EMULATOR_YOUR_EMULATOR% -f %ROM%</command>
        <platform>switch</platform>
        <theme>switch</theme>
    </system>
</systemList>
```

Open settings of the external emulator and change all paths to corresponding subdirs of "retrodeck/", to keep all emulation data in one place.
