{pkgs ? import <nixpkgs> {}}:
with pkgs;
  mkShell {
    buildInputs = [
      zig
      sdl3
      sdl3-image
      # raylib
      # libGL
      # alsa-lib
      # libxkbcommon
      # wayland
      # wayland-scanner
      # xorg.libX11
      # xorg.libX11.dev
      # xorg.libXcursor
      # xorg.libXi
      # xorg.libXinerama
      # xorg.libXrandr
    ];
  }
