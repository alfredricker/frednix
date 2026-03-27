local lsp = require("lspconfig")
local caps = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(_, bufnr)
  local map = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = bufnr, silent = true, desc = desc })
  end
  map("gd",          vim.lsp.buf.definition,   "go to definition")
  map("gr",          vim.lsp.buf.references,    "references")
  map("K",           vim.lsp.buf.hover,         "hover docs")
  map("<leader>rn",  vim.lsp.buf.rename,        "rename")
  map("<leader>ca",  vim.lsp.buf.code_action,   "code action")
  map("<leader>d",   vim.diagnostic.open_float, "diagnostics")
  map("[d",          vim.diagnostic.goto_prev,  "prev diagnostic")
  map("]d",          vim.diagnostic.goto_next,  "next diagnostic")
end

lsp.nil_ls.setup({ capabilities = caps, on_attach = on_attach })
lsp.lua_ls.setup({ capabilities = caps, on_attach = on_attach })
lsp.pyright.setup({ capabilities = caps, on_attach = on_attach })
lsp.rust_analyzer.setup({ capabilities = caps, on_attach = on_attach })
lsp.ts_ls.setup({ capabilities = caps, on_attach = on_attach })
