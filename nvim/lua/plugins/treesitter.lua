return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({ "go", "gomod", "gosum", "lua", "vim", "vimdoc", "markdown", "ruby", "embedded_template" })
    -- ERB files use the `eruby` filetype; point it at the embedded_template parser
    vim.treesitter.language.register("embedded_template", "eruby")
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
