{ pkgs, ... }:

let
  shadesOfPurple = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "shades-of-purple";
    publisher = "ahmadawais";
    version = "7.3.6";
    sha256 = "11bxs2hgf2mmlvi1zkz77yxwl0imjfax9fgqc1w0imdhcz074rnv";
  };
in
{
  home.packages = [ pkgs.mononoki ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode; # Microsoft binary required for GitHub Copilot

    extensions = with pkgs.vscode-extensions; [
      # Python
      ms-python.python
      ms-python.debugpy

      # Rust
      rust-lang.rust-analyzer

      # TypeScript/React tooling (TS support is built into VS Code)
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode

      # GitHub Copilot
      github.copilot
      github.copilot-chat

      # Theme
      shadesOfPurple
    ];

    userSettings = {
      "workbench.colorTheme" = "Shades of Purple (Super Dark)";
      "editor.fontFamily" = "'mononoki', monospace";
      "editor.fontSize" = 14;
      "editor.formatOnSave" = true;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "[python]"."editor.defaultFormatter" = "ms-python.python";
      "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "rust-analyzer.check.command" = "clippy";
    };
  };
}
