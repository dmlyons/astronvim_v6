-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null_ls"

    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      null_ls.builtins.diagnostics.golangci_lint.with {
        config_file = "/home/dl/src/carbon/.golangci.yaml",
      },
    })
  end,
}
