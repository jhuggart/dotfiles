return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({ "go", "gomod", "gosum", "lua", "vim", "vimdoc", "markdown" })
  end,
}
