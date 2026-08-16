-- Customize Mason

---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "golangci-lint",
        "lua-language-server",
        "stylua",
        "debugpy",
        "tree-sitter-cli",
      },
    },
  },
}
