{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  nightlightShader = strength: ''
    #version 300 es
    precision highp float;

    in vec2 v_texcoord;
    uniform sampler2D tex;
    out vec4 fragColor;

    const float temperature = 3200.0;
    const float temperatureStrength = ${toString strength};

    vec3 colorTemperatureToRGB(const in float temperatureValue) {
        mat3 m = (temperatureValue <= 6500.0)
            ? mat3(vec3(0.0, -2902.1955, -8257.7998),
                   vec3(0.0, 1669.5804, 2575.2828),
                   vec3(1.0, 1.3302674, 1.8993754))
            : mat3(vec3(1745.0425, 1216.6168, -8257.7998),
                   vec3(-2666.3474, -2173.1012, 2575.2828),
                   vec3(0.5599539, 0.7038120, 1.8993754));

        return mix(
            clamp(m[0] / (vec3(clamp(temperatureValue, 1000.0, 40000.0)) + m[1]) + m[2], 0.0, 1.0),
            vec3(1.0),
            smoothstep(1000.0, 0.0, temperatureValue)
        );
    }

    void main() {
        vec4 pixColor = texture(tex, v_texcoord);
        vec3 color = pixColor.rgb;
        color = mix(color, color * colorTemperatureToRGB(temperature), temperatureStrength);
        fragColor = vec4(color, pixColor.a);
    }
  '';
  stremioApp = pkgs.stremio-linux-shell.overrideAttrs (final: prev: {
    postPatch = ''
      substituteInPlace src/config.rs \
        --replace-fail "@serverjs@" "$out/share/stremio/server.js"

      for file in $cargoDepsCopy/libappindicator-sys-*/src/lib.rs; do
        [ -e "$file" ] || continue
        substituteInPlace "$file" \
          --replace-fail "libayatana-appindicator3.so.1" "${pkgs.libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
      done

      for file in $cargoDepsCopy/xkbcommon-dl-*/src/lib.rs; do
        [ -e "$file" ] || continue
        substituteInPlace "$file" \
          --replace-fail "libxkbcommon.so.0" "${pkgs.libxkbcommon}/lib/libxkbcommon.so.0"
      done

      for file in $cargoDepsCopy/xkbcommon-dl-*/src/x11.rs; do
        [ -e "$file" ] || continue
        substituteInPlace "$file" \
          --replace-fail "libxkbcommon-x11.so.0" "${pkgs.libxkbcommon}/lib/libxkbcommon-x11.so.0"
      done
    '';
  });
in {

  imports = [
	  ./modules/devtools.nix
	  ./modules/devops.nix
	  ./modules/misc.nix
	  ./modules/gaming.nix
	];

  home.username = "dio";
  home.homeDirectory = "/home/dio";

  home.activation.copyNvimConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
  rm -rf $HOME/.config/nvim
  cp -r ${./nvim} $HOME/.config/nvim
  chmod -R u+w $HOME/.config/nvim
'';

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/pnpm"
    "${config.home.homeDirectory}/.local/share/gem/ruby/3.4.0/bin"
    "${config.home.homeDirectory}/.dotnet/tools"
  ];

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 28;
  };

  home.stateVersion = "25.11";

  services.ssh-agent.enable = true;

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    gcc
    gnumake
    pkg-config
    python3
    python3Packages.pip
    wl-clipboard
    ffmpeg
    git
    cheese
    nodejs
    fastfetch
    opencode
    mixxx
    snes9x
	lua-language-server
    discord
    pkgs.nerd-fonts.iosevka-term
    hyprpaper
    qbittorrent
    wofi
    stremioApp
    hyprshade
    grim
    slurp
    (writeShellScriptBin "random-wallpaper" ''
      wallpapers_dir="$HOME/Wallpapers"

      mkdir -p "$wallpapers_dir"

      wallpaper="$(${pkgs.findutils}/bin/find "$wallpapers_dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
        | ${pkgs.coreutils}/bin/shuf -n 1)"

      if [ -z "$wallpaper" ]; then
        exit 0
      fi

      if ! ${pkgs.procps}/bin/pgrep -x hyprpaper >/dev/null; then
        ${pkgs.hyprpaper}/bin/hyprpaper >/dev/null 2>&1 &
        ${pkgs.coreutils}/bin/sleep 1
      fi

      ${pkgs.hyprland}/bin/hyprctl hyprpaper unload all >/dev/null 2>&1 || true
      ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$wallpaper"
      ${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name' | while IFS= read -r monitor; do
        [ -n "$monitor" ] || continue
        ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "$monitor,$wallpaper"
      done
    '')
    (writeShellScriptBin "audio-output-status" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      pactl_bin=${pkgs.pulseaudio}/bin/pactl

      default_sink="$("$pactl_bin" info 2>/dev/null | awk -F': ' '/Default Sink/ {print $2}')"
      if [ -z "$default_sink" ]; then
        echo "No sink"
        exit 0
      fi

      description="$("$pactl_bin" list sinks 2>/dev/null | awk -v sink="$default_sink" 'BEGIN{RS="Sink #"} $0 ~ "Name: "sink {match($0,/Description: (.*)/,a); if (a[1] != "") {print a[1]; exit}}')"
      if [ -z "$description" ]; then
        description="$default_sink"
      fi

      short="$description"
      max=20
      if [ "''${#short}" -gt "$max" ]; then
        trim=$((max - 3))
        short="''${short:0:$trim}..."
      fi

      printf '%s\n' "$short"
    '')
    (writeShellScriptBin "audio-output-cycle" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      pactl_bin=${pkgs.pulseaudio}/bin/pactl

      mapfile -t sinks < <("$pactl_bin" list short sinks | awk '{print $2}')
      if [ "''${#sinks[@]}" -eq 0 ]; then
        exit 0
      fi

      default_sink="$("$pactl_bin" info 2>/dev/null | awk -F': ' '/Default Sink/ {print $2}')"

      next_sink="''${sinks[0]}"
      if [ -n "$default_sink" ]; then
        for ((idx=0; idx<''${#sinks[@]}; idx++)); do
          if [ "''${sinks[$idx]}" = "$default_sink" ]; then
            next_index=$(( (idx + 1) % ''${#sinks[@]} ))
            next_sink="''${sinks[$next_index]}"
            break
          fi
        done
      fi

      "$pactl_bin" set-default-sink "$next_sink"

      while read -r input_id _; do
        if [ -n "$input_id" ]; then
          "$pactl_bin" move-sink-input "$input_id" "$next_sink" || true
        fi
      done < <("$pactl_bin" list short sink-inputs)

      if command -v audio-output-status >/dev/null 2>&1; then
        friendly="$(audio-output-status)"
      else
        friendly="$next_sink"
      fi

      if command -v notify-send >/dev/null 2>&1; then
        notify-send "Audio Output" "$friendly"
      fi
    '')
    (writeShellScriptBin "nightlight-status" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      current="$(${pkgs.hyprshade}/bin/hyprshade current 2>/dev/null || true)"

      case "''${current:-}" in
        nightlight-50)
          printf '{"text":"nightlight 2","tooltip":"50%%","class":["nightlight","active","level-2"]}\n'
          ;;
        nightlight-75)
          printf '{"text":"nightlight 3","tooltip":"75%%","class":["nightlight","active","level-3"]}\n'
          ;;
        nightlight-100)
          printf '{"text":"nightlight 4","tooltip":"100%%","class":["nightlight","active","level-4"]}\n'
          ;;
        *)
          printf '{"text":"nightlight 1","tooltip":"off","class":["nightlight","inactive","level-1"]}\n'
          ;;
      esac
    '')
    (writeShellScriptBin "nightlight-toggle" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      current="$(${pkgs.hyprshade}/bin/hyprshade current 2>/dev/null || true)"

      case "''${current:-}" in
        nightlight-50)
          next="nightlight-75"
          ;;
        nightlight-75)
          next="nightlight-100"
          ;;
        nightlight-100)
          next="off"
          ;;
        *)
          next="nightlight-50"
          ;;
      esac

      if [ "$next" = "off" ]; then
        ${pkgs.hyprshade}/bin/hyprshade off || exit 0
      else
        ${pkgs.hyprshade}/bin/hyprshade on "$next" || exit 0
      fi
    '')
    (writeShellScriptBin "grab-select-screenshot" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      dir="$HOME/Pictures/Screenshots"
      mkdir -p "$dir"

      region="$(${pkgs.slurp}/bin/slurp)"
      if [ -z "$region" ]; then
        exit 0
      fi

      timestamp="$(${pkgs.coreutils}/bin/date +'%Y-%m-%d_%H-%M-%S')"
      file="$dir/screenshot-$timestamp.png"

      ${pkgs.grim}/bin/grim -g "$region" "$file"

      if command -v notify-send >/dev/null 2>&1; then
        notify-send "Screenshot captured" "$file"
      fi
    '')
  ];

  home.file = {
    ".config/hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
    '';
    ".config/wofi/config".text = ''
      mode=drun
      allow_images=false
      columns=1
      lines=9
      location=center
      width=520
      height=360
      orientation=vertical
      layer=overlay
      gtk_dark=true
      show=drun
      prompt=search
      matching=fuzzy
      sort_order=alphabetical
      allow_markup=false
      filter_lines=true
      dynamic_lines=true
      line_height=32
      border=false
      cache_file=$HOME/.cache/wofi/drun.cache
    '';
    ".config/wofi/style.css".text = ''
      window {
        font-family: "JetBrainsMono Nerd Font", "DejaVu Sans Mono", monospace;
        font-size: 14px;
        background: rgba(30, 30, 34, 0.95);
        color: #e3e3e3;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 12px;
        padding: 18px 22px 12px;
      }

      #input {
        background: rgba(20, 20, 24, 0.85);
        border: 1px solid rgba(255, 255, 255, 0.06);
        border-radius: 8px;
        color: #f8f8f8;
        padding: 10px 14px;
        margin-bottom: 14px;
      }

      #scroll {
        background: transparent;
      }

      #entry {
        padding: 10px 12px;
        border-radius: 6px;
        margin-bottom: 6px;
        border: 1px solid transparent;
      }

      #entry:selected {
        background: rgba(255, 255, 255, 0.08);
        border-color: rgba(255, 255, 255, 0.16);
        color: #ffffff;
      }

      #text {
        color: inherit;
      }

      #img {
        margin-right: 10px;
        opacity: 0.85;
      }
    '';
    ".config/hypr/hyprshade.toml".text = ''
      shades = [
        { name = "nightlight-100", start_time = 00:00:00, end_time = 23:59:00 },
        { name = "nightlight-100", default = true }
      ]
    '';
    ".config/hypr/shaders/nightlight-50.glsl".text = nightlightShader 0.5;
    ".config/hypr/shaders/nightlight-75.glsl".text = nightlightShader 0.75;
    ".config/hypr/shaders/nightlight-100.glsl".text = nightlightShader 1.0;
  };

  home.activation = {
    createWallpapersDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/Wallpapers"
    '';
    ensureWofiCacheDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/.cache/wofi"
    '';
  };

  programs.neovim = {
    enable = true;
    package = (import inputs.nixpkgs-unstable { system = pkgs.system; }).neovim-unwrapped;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
    syntaxHighlighting.enable = true;
    initContent = ''
      export PNPM_HOME="$HOME/.local/share/pnpm"
      export PATH="$PNPM_HOME:$PATH"
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "${./logo.txt}";
        type = "file";
        color = {
          "1" = "#F3A2BB";
          "2" = "#EEAE7B";
          "3" = "#B5C77D";
          "4" = "#6DD3C0";
          "5" = "#80C6F8";
          "6" = "#C7AFF5";
        };
      };
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "display"
        "de"
        "wm"
        "terminal"
        "cpu"
        "gpu"
        "memory"
        "disk"
        "battery"
        "break"
        "colors"
      ];
    };
  };

  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Vague";
      "font-family" = "IosevkaTerm Nerd Font";
      "cursor-style" = "block";
      "background-opacity" = 0.8;
      "shell-integration-features" = "no-cursor";
    };
  };

  programs.git = {
    enable = true;
    userName = "diorisso";
    userEmail = "diogenesmarquesr@gmail.com";
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        margin = "0 0 0 0";
        spacing = 0;
        fixed-center = true;
        modules-left = ["hyprland/workspaces" "hyprland/window"];
        modules-center = ["clock"];
        modules-right = ["custom/nightlight" "custom/audio-output" "pulseaudio" "battery"];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "Ⅰ";
            "2" = "Ⅱ";
            "3" = "Ⅲ";
            "4" = "Ⅳ";
            "5" = "Ⅴ";
          };
          on-click = "activate";
          disable-scroll = true;
          sort-by-number = true;
          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          format = "{title}";
          max-length = 60;
          format-empty = "";
        };

        clock = {
          format = "{:%b %d · %H:%M}";
          tooltip = true;
          tooltip-format = "{:%A, %d %B %Y\\n%H:%M:%S}";
        };

        "custom/nightlight" = {
          return-type = "json";
          exec = "nightlight-status";
          interval = 3;
          on-click = "nightlight-toggle";
        };

        pulseaudio = {
          format = "{volume}%";
          format-muted = "mute";
          tooltip = true;
        };

        battery = {
          format = "{icon} {capacity}%";
          states = {
            warning = 25;
            critical = 10;
          };
          format-icons = ["" "" "" "" ""];
        };

        "custom/audio-output" = {
          format = "{}";
          exec = "audio-output-status";
          interval = 2;
          on-click = "audio-output-cycle";
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "DejaVu Sans Mono", monospace;
        font-size: 12px;
        font-weight: 500;
        color: #e3e3e3;
      }

      window#waybar {
        background: rgba(30, 30, 34, 0.95);
        border-radius: 0;
        border: 1px solid rgba(255, 255, 255, 0.06);
        box-shadow: none;
        padding: 0;
      }

      #workspaces button {
        border: none;
        background: transparent;
        color: #9f9f9f;
        padding: 0 8px;
        margin: 0 1px;
        border-radius: 0;
        min-width: 0;
        transition: color 0.2s ease, border-color 0.2s ease;
      }

      #workspaces button.active {
        color: #ffffff;
        border-bottom: 2px solid #d5d5d5;
      }

      #workspaces button:hover {
        color: #f2f2f2;
      }

      #window,
      #clock,
      #custom-nightlight,
      #custom-audio-output,
      #pulseaudio,
      #battery {
        padding: 0 10px;
      }

      #custom-nightlight {
        letter-spacing: 0.5px;
        color: #b9b9b9;
      }

      #custom-nightlight.active {
        color: #f1d18f;
      }

      #custom-nightlight.inactive {
        color: #6f6f6f;
      }

      #custom-audio-output {
        color: #d6d6d6;
      }

      #window {
        color: #c3c3c3;
        min-width: 220px;
      }

      #clock {
        color: #f8f8f8;
        font-size: 13px;
        font-weight: 600;
      }

      #battery.warning {
        color: #f5d17c;
      }

      #battery.critical {
        color: #ff6b6b;
      }
    '';
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mainMod" = "SUPER";
      exec-once = [
        "random-wallpaper"
        "waybar"
      ];
      monitor = [
        "DP-3,1920x1080@240,auto,1"
      ];
      input = {
        kb_layout = "br";
        kb_variant = "abnt2";
      };
      general = {
        gaps_in = 6;
        gaps_out = 6;
      };
      animations = {
        enabled = true;
        bezier = "snappy,0.25,0.9,0.3,1.0";
        animation = [
          "windows,1,2,snappy"
          "windowsOut,1,2,snappy,slide"
          "border,1,2,snappy"
          "fade,1,1.5,default"
          "workspaces,1,2,snappy"
        ];
      };
      env = [
        "XCURSOR_THEME,Bibata-Modern-Ice"
        "XCURSOR_SIZE,28"
        "HYPRCURSOR_THEME,Bibata-Modern-Ice"
        "HYPRCURSOR_SIZE,28"
      ];
      bind = [
        "$mainMod, RETURN, exec, ghostty"
        "$mainMod, B, exec, zen"
        "$mainMod, R, exec, wofi --show drun"
        "$mainMod, C, killactive"
        "$mainMod, F, fullscreen"
        "$mainMod, H, movefocus, l"
        "$mainMod, J, movefocus, d"
        "$mainMod, K, movefocus, u"
        "$mainMod, L, movefocus, r"
        "$mainMod SHIFT, H, movewindow, l"
        "$mainMod SHIFT, J, movewindow, d"
        "$mainMod SHIFT, K, movewindow, u"
        "$mainMod SHIFT, L, movewindow, r"
        "$mainMod SHIFT CTRL, H, resizeactive, -40 0"
        "$mainMod SHIFT CTRL, J, resizeactive, 0 40"
        "$mainMod SHIFT CTRL, K, resizeactive, 0 -40"
        "$mainMod SHIFT CTRL, L, resizeactive, 40 0"
        "$mainMod SHIFT, S, exec, grab-select-screenshot"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

  programs.home-manager.enable = true;
}
