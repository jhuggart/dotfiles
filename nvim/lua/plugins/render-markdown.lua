return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- New nvim-treesitter 1.0 API
      vim.treesitter.language.register("markdown", "markdown")
      -- Auto-install parsers when opening files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          pcall(function()
            vim.treesitter.start()
          end)
        end,
      })
    end,
  },
}
