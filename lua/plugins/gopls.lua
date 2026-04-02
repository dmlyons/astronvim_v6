return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    config = {
      -- the key is the server name to configure
      -- the value is the configuration table
      gopls = {
        settings = {
          gopls = {
            analyses = {
              shadow = false,
              -- fieldalignment = true,
              ST1000 = false,
              ST1001 = false,
              ST1003 = false,
              ST1005 = false,
              ST1021 = false,
              ST1022 = false,
            },
            buildFlags = { "-tags=!integration !build" },
            gofumpt = false,
            usePlaceholders = false,
            hints = {
              functionTypeParameters = true,
            },
          },
        },
      },
    },
  },
}
