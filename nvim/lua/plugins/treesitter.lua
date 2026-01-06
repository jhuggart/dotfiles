return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({ "go", "gomod", "gosum", "lua", "vim", "vimdoc", "markdown" })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
