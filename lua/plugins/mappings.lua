return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          ["<leader>uP"] = {
            function()
              local copilot = require "copilot.suggestion"
              if copilot.is_visible() then copilot.dismiss() end
              vim.cmd "Copilot toggle"
              vim.cmd "Copilot status"
            end,
            desc = "Toggle Copilot",
          },
        },
      },
    },
  },
}
