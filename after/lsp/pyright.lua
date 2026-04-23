-- ┌──────────────────────┐
-- │ LSP config: pyright  │
-- └──────────────────────┘
--
-- Pyright is Microsoft's static type checker and language server for Python.
-- Source: https://github.com/microsoft/pyright
--
-- Install: `pip install pyright` or `:MasonInstall pyright`
--
-- See `:h vim.lsp.Config` for all available fields.
return {
  settings = {
    python = {
      analysis = {
        -- 'basic' | 'standard' | 'strict'
        typeCheckingMode = 'basic',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
}
