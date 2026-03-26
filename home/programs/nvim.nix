{ pkgs, lib, ... }:

{
  home.activation.cloneNvChad = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.config/nvim/.git" ]; then
      ${pkgs.git}/bin/git clone https://github.com/NvChad/starter "$HOME/.config/nvim"
    fi
  '';
}
