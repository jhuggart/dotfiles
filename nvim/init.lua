-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true

-- Tmux integration: fast escape key handling
vim.opt.ttimeoutlen = 10
vim.opt.timeoutlen = 500

-- Enable 24-bit RGB colors in tmux
if vim.env.TMUX then
  vim.opt.termguicolors = true
end

-- Jump list navigation
vim.keymap.set("n", "<C-[>", "<C-o>", { desc = "Jump back" })
vim.keymap.set("n", "<C-]>", "<C-i>", { desc = "Jump forward" })

-- Load plugins
require("lazy").setup("plugins")
