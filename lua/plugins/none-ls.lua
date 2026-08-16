-- Customize None-ls sources

-- golangci-lint settings, duplicated from ~/src/carbon/.golangci.yaml
-- (kept in sync manually — not read from that file at lint time)
local golangci_lint_config = [[
version: "2"

linters:
  enable:
    - gosec

  disable:
    - errcheck
    - staticcheck
    - unused

  settings:
    gosec:
      excludes:
        - G104 # Audit errors not checked (same as errcheck above)
        - G115 # Potential integer overflow when converting between integer types (we want it to blow up if this happens)
        - G304 # File path provided as taint input (we do this everywhere, we should probably do better)
]]

local golangci_lint_config_path = vim.fn.stdpath "cache" .. "/golangci-lint.yaml"

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"

    vim.fn.writefile(vim.split(golangci_lint_config, "\n"), golangci_lint_config_path)

    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      null_ls.builtins.diagnostics.golangci_lint.with {
        extra_args = { "--config", golangci_lint_config_path },
      },
    })
  end,
}