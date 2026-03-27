{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # ── options ──────────────────────────────────────────────────────────
    opts = {
      number         = true;
      relativenumber = true;
      expandtab      = true;
      shiftwidth     = 2;
      tabstop        = 2;
      scrolloff      = 8;
      signcolumn     = "yes";
      termguicolors  = true;
      splitright     = true;
      splitbelow     = true;
      wrap           = false;
      ignorecase     = true;
      smartcase      = true;
      cursorline     = true;
      undofile       = true;
    };

    globals = {
      mapleader      = " ";
      maplocalleader = ",";
    };

    # ── keymaps ──────────────────────────────────────────────────────────
    keymaps = [
      { mode = "n"; key = "<leader>e";  action = ":NvimTreeToggle<CR>"; options.silent = true; }
      { mode = "n"; key = "<leader>q";  action = ":bd<CR>";             options.silent = true; }
      { mode = "n"; key = "<Esc>";      action = ":noh<CR>";            options.silent = true; }
      { mode = "n"; key = "<C-h>";      action = "<C-w>h"; }
      { mode = "n"; key = "<C-l>";      action = "<C-w>l"; }
      { mode = "n"; key = "<C-j>";      action = "<C-w>j"; }
      { mode = "n"; key = "<C-k>";      action = "<C-w>k"; }
    ];

    # ── plugins ──────────────────────────────────────────────────────────
    plugins = {

      # file tree
      nvim-tree = {
        enable = true;
        view.width = 30;
        renderer.groupEmpty = true;
      };

      # syntax highlighting
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      # fuzzy finder
      telescope = {
        enable = true;
        settings.defaults = {
          layout_config.prompt_position = "top";
          sorting_strategy = "ascending";
        };
        keymaps = {
          "<leader>ff" = { action = "find_files"; options.desc = "find files"; };
          "<leader>fg" = { action = "live_grep";  options.desc = "live grep"; };
          "<leader>fb" = { action = "buffers";    options.desc = "buffers"; };
          "<leader>fh" = { action = "help_tags";  options.desc = "help tags"; };
        };
      };

      # status line
      lualine = {
        enable = true;
        settings.options = {
          theme = "auto";
          component_separators = "|";
          section_separators = "";
        };
      };

      # git signs in gutter
      gitsigns = {
        enable = true;
        settings.signs = {
          add.text    = "+";
          change.text = "~";
          delete.text = "_";
        };
      };

      # LSP
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable    = true;
          lua_ls.enable    = true;
          pyright.enable   = true;
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc  = false;
          };
          ts_ls.enable     = true;
        };
        keymaps = {
          diagnostic = {
            "<leader>d" = "open_float";
            "[d"        = "goto_prev";
            "]d"        = "goto_next";
          };
          lspBuf = {
            "gd"          = "definition";
            "gr"          = "references";
            "K"           = "hover";
            "<leader>rn"  = "rename";
            "<leader>ca"  = "code_action";
          };
        };
      };

      # completion
      cmp = {
        enable = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>"      = "cmp.mapping.confirm({ select = true })";
            "<Tab>"     = ''
              cmp.mapping(function(fallback)
                if cmp.visible() then cmp.select_next_item()
                elseif require('luasnip').expand_or_jumpable() then require('luasnip').expand_or_jump()
                else fallback() end
              end, { "i", "s" })
            '';
            "<S-Tab>"   = ''
              cmp.mapping(function(fallback)
                if cmp.visible() then cmp.select_prev_item()
                else fallback() end
              end, { "i", "s" })
            '';
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "buffer"; }
            { name = "path"; }
          ];
        };
      };

      luasnip.enable    = true;
      cmp-nvim-lsp.enable = true;
      cmp_luasnip.enable  = true;
      cmp-buffer.enable   = true;
      cmp-path.enable     = true;

      # indent guides
      indent-blankline.enable = true;

      # web devicons (required by nvim-tree + others)
      web-devicons.enable = true;
    };
  };
}
