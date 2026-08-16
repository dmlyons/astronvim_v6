# Repository Guidelines

## Project Overview

Personal Neovim configuration (`~/.config/nvim`) built on [AstroNvim](https://github.com/AstroNvim/AstroNvim) v6, bootstrapped from the [AstroNvim Template](https://github.com/AstroNvim/template). It is not an application with its own runtime code — it *is* the editor configuration: Lua tables ("specs") declaring which plugins to install and how to configure them, loaded by the `lazy.nvim` plugin manager. Primary customization focus visible in the tree: Go development (`go.nvim` + `gopls`) and GitHub Copilot completion.

## Architecture & Data Flow

Startup chain: `init.lua` → `lua/lazy_setup.lua` → `lua/polish.lua`.

1. **`init.lua`** — bootstraps `lazy.nvim` itself: resolves `lazypath` from `$LAZY` or `stdpath("data").."/lazy/lazy.nvim"`, `git clone`s it if missing, prepends to `&rtp`, `pcall`-requires it (prints error + quits on failure). Then `require "lazy_setup"` then `require "polish"`. Comment warns: "BE CAUTIOUS editing this file."
2. **`lua/lazy_setup.lua`** — calls `require("lazy").setup(spec, config)`. The `spec` array order defines a **layering/override chain** (later entries override earlier ones when lazy.nvim merges specs sharing a plugin name):
   - `{ "AstroNvim/AstroNvim", version = "^6", import = "astronvim.plugins", opts = {...} }` — AstroNvim core framework and its default plugin specs (astrocore, astrolsp, astroui, mason, treesitter, none-ls, …). Leader keys (`mapleader = " "`, `maplocalleader = ","`) and framework toggles live in this `opts` table because they must exist before `lazy.setup` runs.
   - `{ import = "community" }` → `lua/community.lua`, which imports `astrocommunity.pack.*` specs. Imported *before* user plugins so community defaults can be overridden below.
   - `{ import = "plugins" }` → every file in `lua/plugins/*.lua` (auto-imported directory), the final and highest-priority layer.
   - `lazy.setup`'s second argument (`LazyConfig`, not a spec) sets `install.colorscheme = { "astrotheme", "habamax" }`, `ui.backdrop = 100`, `performance.rtp.disabled_plugins = { "gzip", "netrwPlugin", "tarPlugin", "tohtml", "zipPlugin" }`.
3. **`lua/polish.lua`** — pure imperative Lua, runs last, outside the lazy spec tree entirely. Currently sets `shiftwidth`/`tabstop = 4` and forces a black `Normal` highlight, bypassing opts-table merging.

**Layering summary**: AstroNvim core defaults < astrocommunity packs (`community.lua`) < user plugins (`lua/plugins/*.lua`) < `polish.lua` imperative overrides.

**Plugin-file activation convention**: every file under `lua/plugins/` starts (or historically starts) with a guard line `-- if true then return {} end` / `-- if true then return end`. **Commented out** = file is active and its spec is merged in; **uncommented** = file is inert boilerplate and contributes an empty `{}` spec. Check this line first when reading any `lua/plugins/*.lua` file — an uncommented guard means everything below it is dead code kept for reference only.

Currently active: `astrocore.lua`, `mappings.lua`, `go.nvim.lua`, `gopls.lua`, `community.lua`, `polish.lua`.
Currently inert (guard active, template boilerplate): `astrolsp.lua`, `astroui.lua`, `mason.lua`, `none-ls.lua`, `treesitter.lua`, `user.lua`.

Multiple files can configure the *same* plugin — lazy.nvim merges spec tables by plugin name. Example: `gopls.lua` sets `opts.config.gopls.settings.gopls` on plugin `"AstroNvim/astrolsp"` and **is live** even though `astrolsp.lua` itself is disabled, because they're separate spec entries for the same plugin name.

## Key Directories

- `lua/` — all configuration Lua code.
  - `lua/lazy_setup.lua`, `lua/community.lua`, `lua/polish.lua` — top-level setup files (see Architecture above).
  - `lua/plugins/` — one file per plugin/feature area; each returns a `LazySpec` table (or empty `{}` when disabled). Add new plugins here, one file per plugin/feature.
- `init.lua` — bootstrap only; avoid editing unless changing how `lazy.nvim` itself is installed.

There is no `src/`, `test/`, `scripts/`, or `docs/` directory — this repo has none of those.

## Development Commands

No build step, no test runner, no CI (`.github/` does not exist). Actionable commands:

- **Run/launch**: `nvim` — plugins install automatically on first launch via `lazy.nvim`.
- **Format Lua**: `stylua .` (check-only: `stylua --check .`) — config in `.stylua.toml`.
- **Lint Lua**: `selene .` — config in `selene.toml` (uses Neovim stdlib defs from `neovim.yml`).
- **Plugin management** (in-editor Ex commands): `:Lazy` (UI), `:Lazy update`/`:Lazy sync` (update + rewrite `lazy-lock.json`), `:Lazy restore` (reinstall pinned commits from `lazy-lock.json`).
- **Verify a change**: launch `nvim` (or `nvim --headless -c 'qa'` for a load-only smoke test) and confirm no startup errors; there is no automated test suite to run instead.

## Code Conventions & Common Patterns

- **Guard-line toggle pattern**: new/optional plugin files start with `-- if true then return {} end`; uncomment to activate. Preserve this pattern for new plugin files intended to be easily toggled.
- **`---@type LazySpec` / `---@type AstroCoreOpts` / `---@type AstroLSPOpts` annotations**: every active plugin file annotates its returned table for `lua_ls` type-checking. Use the matching annotation for the plugin/opts shape you're returning.
- **Formatting**: enforced by `stylua` only — `lua_ls`'s own formatter is explicitly disabled in both `.luarc.json` (`"format.enable": false`) and `.neoconf.json` (`lspconfig.lua_ls."Lua.format.enable" = false`) to avoid conflicting formatters. Never rely on LSP-driven formatting in this repo.
- **Style specifics** (from `.stylua.toml`): 2-space indent, 120-col width, Unix line endings, double-quote-preferred strings, parens omitted on single-arg calls (`require "foo"` not `require("foo")`), simple one-line statements collapsed.
- **Additive opts pattern**: when overriding a list-like opts field (e.g. formatter/linter sources), use `require("astrocore").list_insert_unique(opts.sources, {...})` (see disabled `none-ls.lua`) rather than clobbering the table, so AstroNvim/community defaults are preserved.
- **Calling through to AstroNvim's default plugin config**: when overriding a plugin AstroNvim core already configures, call its base config function then extend, e.g. `require("astronvim.plugins.configs.nvim-autopairs")(plugin, opts)` before adding custom rules (see disabled `user.lua`).
- **Custom keymaps**: declared under a plugin's `opts.mappings.n` (normal mode) table, e.g. `astrocore.lua`'s `]b`/`[b` buffer nav and `mappings.lua`'s `<leader>uP` Copilot toggle. Prefer adding keymaps this way (merged via AstroCore) over raw `vim.keymap.set` calls, to stay consistent with existing files.
- **No dependency injection / no app state** in the traditional sense — "state" is entirely plugin configuration tables merged by `lazy.nvim`; "DI" equivalent is the spec-merging/override-by-plugin-name mechanism described above.

## Important Files

| File | Role |
|---|---|
| `init.lua` | lazy.nvim bootstrap; edit rarely |
| `lua/lazy_setup.lua` | top-level `lazy.setup()` call; leader keys, import order, `LazyConfig` |
| `lua/community.lua` | astrocommunity pack imports (Lua, Go, Docker, JSON, YAML, Markdown, etc. packs) |
| `lua/polish.lua` | last-run imperative overrides (currently: indent width, forced black background) |
| `lua/plugins/astrocore.lua` | AstroCore opts: diagnostics, buffer keymaps, editor options |
| `lua/plugins/mappings.lua` | extra AstroCore keymaps (Copilot toggle) |
| `lua/plugins/go.nvim.lua` | `ray-x/go.nvim` setup, Go/gomod filetypes |
| `lua/plugins/gopls.lua` | live gopls LSP settings (staticcheck analyses, buildFlags, hints) |
| `lazy-lock.json` | plugin version lockfile, autogenerated, gitignored (55 pinned plugins) |
| `.stylua.toml` / `selene.toml` / `neovim.yml` | formatter / linter / lint-stdlib config |
| `.luarc.json` / `.neoconf.json` | `lua_ls` project settings (formatter disabled, neodev library enabled) |

## Runtime/Tooling Preferences

- **Runtime**: Neovim (AstroNvim v6, requires the modern `vim.uv`/`vim.loop` API). No Node/Bun/Python runtime is part of this repo itself, though installed language tooling (gopls, lua-language-server, debugpy, tree-sitter-cli) is managed by Mason.
- **Plugin manager**: `lazy.nvim` (bootstrapped by `init.lua`, not a system package).
- **Lua formatter**: `stylua` — single source of truth; `lua_ls` formatting explicitly disabled.
- **Lua linter**: `selene` (`std = "neovim"`).
- **Lua dialect**: Lua 5.1 baseline (`neovim.yml`: `base: lua51`), matching Neovim's embedded LuaJIT.
- `lazy-lock.json` is gitignored — plugin commit pins are machine-local, not shared via git; don't hand-edit it.

## Testing & QA

No automated test framework, test files, or CI exists in this repository (confirmed: no `test`/`spec` directories, no `*_test.lua`/`*_spec.lua` files, no `describe`/`it`/`busted`/`luassert` usage, no `.github/`, no Makefile/justfile).

QA in practice:
- Format: `stylua --check .`
- Lint: `selene .`
- Behavioral verification: launch `nvim` and manually exercise the changed keymap/plugin/option; watch for startup errors (`:messages`, `:checkhealth`) after editing `lua/plugins/*.lua`.
</content>
