{ pkgs, ... }:

{
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
    ];

    userSettings = {
      "editor.formatOnSave" = true;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "[python]"."editor.defaultFormatter" = "ms-python.python";
      "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "rust-analyzer.check.command" = "clippy";
    };
  };
}
