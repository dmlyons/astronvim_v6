-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

local function set_black_bg() vim.cmd "highlight Normal ctermbg=black guibg=black" end
set_black_bg()
vim.api.nvim_create_autocmd(
  "ColorScheme",
  { desc = "Keep Normal background black across colorscheme changes", callback = set_black_bg }
)
