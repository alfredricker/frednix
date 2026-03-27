{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      nvim-tree-lua
      nvim-web-devicons
      nvim-treesitter.withAllGrammars
      telescope-nvim
      plenary-nvim
      lualine-nvim
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      gitsigns-nvim
      indent-blankline-nvim
    ];

    extraPackages = with pkgs; [
      nil
      lua-language-server
      pyright
      rust-analyzer
      nodePackages.typescript-language-server
    ];
  };

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
