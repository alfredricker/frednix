{ pkgs, lib, ... }:

let
  shadesOfPurple = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "shades-of-purple";
    publisher = "ahmadawais";
    version = "7.3.6";
    sha256 = "11bxs2hgf2mmlvi1zkz77yxwl0imjfax9fgqc1w0imdhcz074rnv";
  };

  playwrightMcpRelay = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "playwright-mcp-relay";
    publisher = "vijaynirmal";
    version = "1.0.0";
    sha256 = "sha256-CB3RFKm/3EIQ2ObCg+lllOi9EM+LCc75s2+EFcHOpEQ=";
  };
in
{
  home.packages = [ pkgs.mononoki ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      # Python
      ms-python.python
      ms-python.debugpy

      # Rust
      rust-lang.rust-analyzer

      # TypeScript/React tooling (TS support is built into VS Code)
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode

      # Next.js / Tailwind
      bradlc.vscode-tailwindcss

      # Go
      golang.go

      # Svelte
      svelte.svelte-vscode

      # nix
      jnoortheen.nix-ide

      # Theme
      shadesOfPurple

      # rainbow csv
      mechatroner.rainbow-csv
    ];

    profiles.default.userSettings = {
      "chat.disableAIFeatures" = true; # disable built-in Copilot/chat
      "workbench.colorTheme" = "Shades of Purple (Super Dark)";
      "editor.fontFamily" = "'mononoki', monospace";
      "editor.fontSize" = 14;
      "editor.formatOnSave" = false;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "[python]"."editor.defaultFormatter" = "ms-python.python";
      "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "[go]"."editor.defaultFormatter" = "golang.go";
      "[svelte]"."editor.defaultFormatter" = "svelte.svelte-vscode";
      "rust-analyzer.check.command" = "clippy";
    };
  };
}
