{ pkgs, ... }:

let
  hermes = pkgs.writeShellApplication {
    name = "hermes";
    runtimeInputs = with pkgs; [
      coreutils # cat, touch, mkdir, rm
      gnugrep # grep -qxF for the known-dirs check
      xdg-utils # xdg-open for `hermes dashboard`
      # docker (with the compose plugin) is provided system-wide and stays on
      # PATH; it is intentionally not pinned here to match the running daemon.
    ];
    text = builtins.readFile ./hermes.sh;
  };
in
{
  home.packages = [ hermes ];
}
