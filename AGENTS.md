# Repository Guidelines

## Project Overview

Personal Neovim configuration (`~/.config/nvim`) built on [AstroNvim](https://github.com/AstroNvim/AstroNvim) v6, bootstrapped from the [AstroNvim Template](https://github.com/AstroNvim/template) (`README.md` is still the unmodified upstream template readme). This repo has no runtime code of its own — it *is* the editor configuration: Lua tables ("specs") declaring which plugins to install and how to configure them, loaded by the `lazy.nvim` plugin manager. Customization focus in the tree: Go development (`go.nvim`, `gopls` analyses, `golangci-lint` via none-ls), GitHub Copilot completion, and Claude Code IDE integration (`claudecode.nvim`).

## Architecture & Data Flow

Startup chain: `init.lua` → `lua/lazy_setup.lua` → `lua/polish.lua`.

1. **`init.lua`** — bootstraps `lazy.nvim` itself: resolves `lazypath` from `$LAZY` or `stdpath("data").."/lazy/lazy.nvim"`, `git clone --branch=stable`s it if missing, prepends to `&rtp`, `pcall`-requires it (echoes error + quits on failure). Then `require "lazy_setup"`, then `require "polish"`. Header comment warns: "BE CAUTIOUS editing this file."
2. **`lua/lazy_setup.lua`** — calls `require("lazy").setup(spec, config)`. The `spec` array order defines a **layering/override chain** (later entries win when lazy.nvim merges specs sharing a plugin name):
   - `{ "AstroNvim/AstroNvim", version = "^6", import = "astronvim.plugins", opts = {...} }` — core framework + its default plugin specs (astrocore, astrolsp, astroui, mason, treesitter, none-ls, …). Leader keys (`mapleader = " "`, `maplocalleader = ","`), `icons_enabled`, `pin_plugins`, `update_notifications` live in this `opts` table because they must exist before `lazy.setup` runs.
   - `{ import = "community" }` → `lua/community.lua`, importing `astrocommunity.pack.*` specs. Imported *before* user plugins so community defaults can be overridden below.
   - `{ import = "plugins" }` → every file in `lua/plugins/*.lua` (auto-imported directory); final, highest-priority spec layer.
   - Second argument (`LazyConfig`, not a spec): `install.colorscheme = { "astrotheme", "habamax" }`, `ui.backdrop = 100`, `performance.rtp.disabled_plugins = { "gzip", "netrwPlugin", "tarPlugin", "tohtml", "zipPlugin" }`.
3. **`lua/polish.lua`** — pure imperative Lua, runs last, outside the lazy spec tree. Sets `shiftwidth`/`tabstop = 4` and forces `Normal` background black, re-applying it from a `ColorScheme` autocmd so theme switches can't undo it.

**Layering summary**: AstroNvim core defaults < astrocommunity packs (`community.lua`) < user plugins (`lua/plugins/*.lua`) < `polish.lua` imperative overrides.

**Guard-line activation convention**: template files ship with a first line `if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE`. **Commented out** (`-- if true then …`) or absent = file is active. **Uncommented** = the file returns `{}` and everything below it is dead reference boilerplate. Check line 1 first when reading any file under `lua/`.

- Active: `lua/community.lua`, `lua/polish.lua`, `lua/plugins/astrocore.lua`, `mappings.lua`, `go.nvim.lua`, `gopls.lua`, `mason.lua`, `none-ls.lua`, `claudecode.lua`.
- Inert (guard on, upstream boilerplate kept for reference): `lua/plugins/astrolsp.lua`, `astroui.lua`, `treesitter.lua`, `user.lua`.

Several files may configure the *same* plugin — lazy.nvim merges spec tables by plugin name. `gopls.lua` sets `opts.config.gopls.settings.gopls` on plugin `"AstroNvim/astrolsp"` and **is live** even though `astrolsp.lua` is guarded off; they are separate spec entries for one plugin name. Likewise `mappings.lua` and `astrocore.lua` both extend `"AstroNvim/astrocore"` opts.

## Key Directories

- `lua/` — all configuration code.
  - `lua/lazy_setup.lua`, `lua/community.lua`, `lua/polish.lua` — top-level setup (see above).
  - `lua/plugins/` — one file per plugin/feature area, each returning a `LazySpec`. New plugins go here.
- `init.lua` — bootstrap only.

No `src/`, `test/`, `scripts/`, `docs/`, or `.github/` directories exist.

## Development Commands

No build step, no test runner, no CI. Actionable commands:

- **Run/launch**: `nvim` — plugins install automatically on first launch via `lazy.nvim`.
- **Load-only smoke test**: `nvim --headless -c 'qa'` (exits clean, prints nothing, when the config loads without errors).
- **Format Lua**: `stylua .` (check-only `stylua --check .`) — config `.stylua.toml`.
- **Lint Lua**: `selene .` — config `selene.toml` + `neovim.yml`. Note: `selene` is *not* installed on this machine; `stylua` is (`~/.local/bin/stylua`).
- **Plugin management** (Ex commands): `:Lazy`, `:Lazy update`/`:Lazy sync` (rewrites `lazy-lock.json`), `:Lazy restore`, `:Mason`.
- **Post-change checks in-editor**: `:messages`, `:checkhealth`, `:LspInfo`.

## Code Conventions & Common Patterns

- **Guard-line toggle**: new/optional plugin files start with `-- if true then return {} end`; preserve the pattern for files meant to be easily toggled. Files written from scratch for this config (`go.nvim.lua`, `gopls.lua`, `mappings.lua`, `mason.lua`, `none-ls.lua`, `claudecode.lua`) omit it and simply `return`.
- **Type annotations**: annotate returned tables — `---@type LazySpec`, `---@type AstroCoreOpts`, `---@type AstroLSPOpts` — for `lua_ls` checking.
- **Formatting**: `stylua` is the single source of truth; `lua_ls` formatting is explicitly disabled in `.luarc.json` (`"format.enable": false`) and `.neoconf.json` (`lspconfig.lua_ls."Lua.format.enable" = false`). Never rely on LSP formatting here.
- **Style** (`.stylua.toml`): 2-space indent, 120 columns, Unix endings, `AutoPreferDouble` quotes, `call_parentheses = "None"` (`require "foo"`, not `require("foo")`), `collapse_simple_statement = "Always"` (one-line `function() … end` bodies are normal).
- **Additive opts**: when extending list-like opts (none-ls `sources`, mason `ensure_installed`), use `require("astrocore").list_insert_unique(opts.sources, {...})` inside an `opts = function(_, opts)` rather than clobbering the table — see `none-ls.lua`.
- **Call through to AstroNvim defaults** when overriding a plugin core already configures: `require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts)` before adding rules (see guarded `user.lua`).
- **Keymaps**: declare under a plugin's `opts.mappings.<mode>` merged by AstroCore (`astrocore.lua`: `]b`/`[b`/`<Leader>bd`; `mappings.lua`: `<leader>uP` Copilot toggle; `claudecode.lua`: `<Leader>A*` Claude Code group). Prefer this over raw `vim.keymap.set`.
- **One LSP owner per server**: `go.nvim` is configured with `lsp_cfg = false` so AstroLSP/Mason exclusively owns `gopls`; do not reintroduce a second `lspconfig.gopls.setup()` path.
- **Go tooling specifics**: `gopls.lua` disables `shadow` and the `ST10xx` stylecheck analyses, sets `buildFlags = { "-tags=!integration !build" }`, `gofumpt = false`, `usePlaceholders = false`. `none-ls.lua` writes an inlined `golangci-lint` YAML config to `stdpath("cache").."/golangci-lint.yaml"` at load and passes it via `extra_args`; that YAML mirrors `~/src/carbon/.golangci.yaml` and is kept in sync **by hand**.
- No dependency injection, no application state: "state" is plugin opts tables; the "DI" equivalent is lazy.nvim's merge-by-plugin-name override mechanism.

## Important Files

|File|Role|
|---|---|
|`init.lua`|lazy.nvim bootstrap; edit rarely|
|`lua/lazy_setup.lua`|`lazy.setup()` call; leader keys, import order, `LazyConfig`|
|`lua/community.lua`|astrocommunity imports: `pack.lua`, `completion.copilot-lua-cmp`, `pack.bash`, `docker`, `go`, `helm`, `html-css`, `json`, `markdown`, `proto`, `typescript`, `yaml` (rust, sql, copilotchat commented out)|
|`lua/polish.lua`|last-run imperative overrides: indent width 4, forced black `Normal` bg + `ColorScheme` autocmd|
|`lua/plugins/astrocore.lua`|AstroCore opts: features, diagnostics, vim options, buffer keymaps (still contains the template's `fooscript` filetype examples)|
|`lua/plugins/mappings.lua`|extra AstroCore keymap: `<leader>uP` Copilot toggle|
|`lua/plugins/go.nvim.lua`|`ray-x/go.nvim`, `lsp_cfg = false`, inlay hints off, `ft = { go, gomod }`|
|`lua/plugins/gopls.lua`|live gopls settings via the `astrolsp` spec|
|`lua/plugins/mason.lua`|`mason-tool-installer` `ensure_installed`: golangci-lint, lua-language-server, stylua, debugpy, tree-sitter-cli|
|`lua/plugins/none-ls.lua`|golangci-lint diagnostics source + generated config file|
|`lua/plugins/claudecode.lua`|`coder/claudecode.nvim` (snacks terminal), lazy-loaded on `:ClaudeCode*` commands, `<Leader>A` keymap group + `Claude` astroui icon. **Vendored** from unmerged astrocommunity PR #1799 — once merged, delete this file and add `{ import = "astrocommunity.ai.claudecode-nvim" }` to `lua/community.lua`|
|`lazy-lock.json`|plugin lockfile (54 pins), autogenerated, **gitignored** — machine-local, never hand-edit|
|`.stylua.toml` / `selene.toml` / `neovim.yml`|formatter / linter / lint stdlib config|
|`.luarc.json` / `.neoconf.json`|`lua_ls` project settings (formatting off, neodev library on)|

## Runtime/Tooling Preferences

- **Runtime**: Neovim (AstroNvim v6; requires modern `vim.uv`/`vim.loop`). No Node/Bun/Python runtime belongs to this repo; language servers and tools (gopls, lua-language-server, golangci-lint, debugpy, tree-sitter-cli) are Mason-managed.
- **Plugin manager**: `lazy.nvim`, bootstrapped by `init.lua`.
- **Lua dialect**: Lua 5.1 baseline (`neovim.yml`: `base: lua51`), matching Neovim's LuaJIT.
- **Formatter**: `stylua`. **Linter**: `selene` (`std = "neovim"`, with `global_usage`, `mixed_table`, `multiple_statements` and friends allowed).

## Testing & QA

No test framework, test files, or CI exist (no `*_spec.lua`/`*_test.lua`, no busted/luassert, no `.github/`, no Makefile/justfile). QA in practice:

1. `stylua --check .`
2. `selene .` (when installed)
3. `nvim --headless -c 'qa'` for a load-only smoke test.
4. Launch `nvim`, open a file of the affected filetype (e.g. a `.go` file inside a real module so `gopls`/`golangci-lint` resolve a root), exercise the changed keymap/plugin/option, and check `:messages` and `:checkhealth` for errors.
