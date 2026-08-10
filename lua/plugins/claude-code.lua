---@type LazySpec
return {
  "greggh/claude-code.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("claude-code").setup({
      window = {
        position = "botright", -- bottom split
      },
      keymaps = {
        toggle = {
          normal = "<leader>ac",
          terminal = "<leader>ac",
        },
      },
    })
  end,
}
