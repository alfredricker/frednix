local map = vim.keymap.set

-- file tree
map("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })

-- telescope
local tel = require("telescope.builtin")
map("n", "<leader>ff", tel.find_files,  { desc = "find files" })
map("n", "<leader>fg", tel.live_grep,   { desc = "live grep" })
map("n", "<leader>fb", tel.buffers,     { desc = "buffers" })
map("n", "<leader>fh", tel.help_tags,   { desc = "help tags" })

-- window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")

-- buffer
map("n", "<leader>q", ":bd<CR>", { silent = true, desc = "close buffer" })

-- clear search highlight
map("n", "<Esc>", ":noh<CR>", { silent = true })
