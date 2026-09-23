-- Point omp (or any coding agent) at what you are looking at.
-- Yanks `path:line-line` references to the system clipboard; omp's `read`
-- tool consumes that selector syntax directly.

local M = {}

--- Project-relative path for the current buffer, plus the resolved range.
---@return string? ref
local function build_ref(l1, l2)
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("buffer has no file", vim.log.levels.WARN, { title = "omp" })
    return nil
  end
  local root = vim.fs.root(0, { ".git", "package.json", "go.mod", "Cargo.toml", "pyproject.toml" })
    or assert(vim.uv.cwd())
  local path = vim.fs.relpath(root, file) or file
  if l1 == l2 then return ("%s:%d"):format(path, l1) end
  return ("%s:%d-%d"):format(path, l1, l2)
end

local function yank(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify(vim.split(text, "\n")[1], vim.log.levels.INFO, { title = "omp: copied" })
end

--- Current line, or the visual selection when called from visual mode.
local function range()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local a, b = vim.fn.line "v", vim.fn.line "."
    if a > b then a, b = b, a end
    return a, b
  end
  local l = vim.fn.line "."
  return l, l
end

--- Just the reference: `src/foo.ts:50-200`.
function M.ref(l1, l2)
  if not l1 then l1, l2 = range() end
  local ref = build_ref(l1, l2)
  if ref then yank(ref) end
end

--- Reference plus the code itself in a fenced block.
function M.block(l1, l2)
  if not l1 then l1, l2 = range() end
  local ref = build_ref(l1, l2)
  if not ref then return end
  local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
  local ft = vim.bo.filetype
  yank(table.concat({ ref, "```" .. ft, table.concat(lines, "\n"), "```" }, "\n"))
end

--- Reference plus every diagnostic on those lines.
function M.diagnostics(l1, l2)
  if not l1 then l1, l2 = range() end
  local ref = build_ref(l1, l2)
  if not ref then return end
  local sev = vim.diagnostic.severity
  local out = { ref }
  for _, d in ipairs(vim.diagnostic.get(0)) do
    if d.lnum >= l1 - 1 and d.lnum <= l2 - 1 then
      out[#out + 1] = ("%s line %d [%s] %s"):format(
        sev[d.severity]:lower(),
        d.lnum + 1,
        d.source or "lsp",
        (d.message:gsub("%s+$", ""))
      )
    end
  end
  if #out == 1 then
    vim.notify("no diagnostics in range", vim.log.levels.WARN, { title = "omp" })
    return
  end
  yank(table.concat(out, "\n"))
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    commands = {
      OmpRef = { function(o) M.ref(o.line1, o.line2) end, range = true, desc = "Copy omp file reference" },
      OmpBlock = { function(o) M.block(o.line1, o.line2) end, range = true, desc = "Copy omp reference + code" },
      OmpDiagnostics = {
        function(o) M.diagnostics(o.line1, o.line2) end,
        range = true,
        desc = "Copy omp reference + diagnostics",
      },
    },
    mappings = {
      n = {
        ["<Leader>o"] = { desc = "omp" },
        ["<Leader>oy"] = { function() M.ref() end, desc = "Yank reference" },
        ["<Leader>oc"] = { function() M.block() end, desc = "Yank reference + code" },
        ["<Leader>od"] = { function() M.diagnostics() end, desc = "Yank reference + diagnostics" },
      },
      x = {
        ["<Leader>o"] = { desc = "omp" },
        ["<Leader>oy"] = { function() M.ref() end, desc = "Yank reference" },
        ["<Leader>oc"] = { function() M.block() end, desc = "Yank reference + code" },
        ["<Leader>od"] = { function() M.diagnostics() end, desc = "Yank reference + diagnostics" },
      },
    },
  },
}
