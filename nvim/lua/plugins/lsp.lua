return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    -- Shared keybindings for all LSP servers
    local on_attach = function(_, bufnr)
      local opts = { buffer = bufnr }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end

    -- Get capabilities from nvim-cmp for autocompletion
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Shared config for all LSP servers
    vim.lsp.config("*", {
      on_attach = on_attach,
      capabilities = capabilities,
    })

    -- Ruby: launch ruby-lsp in the project's mise-managed Ruby context
    -- so it resolves the right Ruby version and bundler environment.
    vim.lsp.config("ruby_lsp", {
      cmd = { "mise", "x", "--", "ruby-lsp" },
    })

    -- Enable LSP servers (configs provided by nvim-lspconfig)
    vim.lsp.enable({ "gopls", "ts_ls", "ruby_lsp" })

    -- Format Ruby files on save via ruby-lsp (RuboCop/syntax_tree).
    -- Gated on the `ruby` filetype so it also covers Gemfile/Rakefile/*.rake/*.gemspec.
    -- No-op when the project has no formatter configured, so it is safe by default.
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function()
        if vim.bo.filetype == "ruby" then
          vim.lsp.buf.format()
        end
      end,
    })
  end,
}
