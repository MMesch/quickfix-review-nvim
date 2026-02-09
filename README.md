# quickfix-review.nvim

A lightweight code review system for Neovim using the built-in quickfix list and signs. You can use it to annotate files or git diffs in neovim with comments of varying type and export them for an AI agent (see screencast below).

## Comparison to other tools

This tool was inspired by:

- [tuicr](https://github.com/agavra/tuicr/), in particular the different comment types and report structure. Many thanks for that. It has a great interface but I wanted something integrated into my editor (keeping LSPs etc), and also a solution that allows me to review entire files and not diffs.
- [Review.nvim](https://github.com/georgeguimaraes/review.nvim), a nice nvim version of tuicr. I wanted a lighter weight solution that also works for reviewing non-diff files.I therefore decided to use the quickfix mechanics and the sign column for this plugin.

## Screencast

[Screencast From 2026-02-09 17-45-58.webm](https://github.com/user-attachments/assets/2c79fa02-737e-4971-9282-f62b8b596a58)

## Features

- **Four comment types**: ISSUE, SUGGESTION, NOTE, PRAISE - each with distinct signs
- **Visual gutter signs**: See review comments at a glance
- **Diff buffer support**: Works also on diffbuffers
- **Export to markdown**: Share reviews with formatted output
- **Persistent storage**: Save and load reviews between sessions
- **Quickfix integration**: Navigate comments with familiar commands

## Installation

### lazy.nvim

```lua
{
  'your-username/quickfix-review.nvim',
  config = function()
    require('quickfix-review').setup()
  end,
}
```

### packer.nvim

```lua
use {
  'your-username/quickfix-review.nvim',
  config = function()
    require('quickfix-review').setup()
  end,
}
```

## Quick Start

1. Open a file to review
2. Press `<leader>ci` to add an ISSUE comment (or `cs`/`cn`/`cp` for other types)
3. Enter your comment text
4. Use `]r` and `[r` to navigate between comments
5. Press `<leader>ce` to export the review to markdown

## Configuration

All options are optional. Here's the full configuration with defaults:

```lua
require('quickfix-review').setup({
  -- Storage file for saving/loading reviews
  storage_file = vim.fn.stdpath('data') .. '/quickfix-review.json',

  -- Export filename
  export_file = 'quickfix-review.md',

  -- Prompt to clear comments when file changes on disk
  prompt_on_file_change = false,

  -- Sign definitions
  signs = {
    issue = { text = '⚠', texthl = 'DiagnosticError' },
    suggestion = { text = '💡', texthl = 'DiagnosticWarn' },
    note = { text = '📝', texthl = 'DiagnosticInfo' },
    praise = { text = '✨', texthl = 'DiagnosticHint' },
  },

  -- Keymaps (set to false to disable)
  keymaps = {
    add_issue = '<leader>ci',
    add_suggestion = '<leader>cs',
    add_note = '<leader>cn',
    add_praise = '<leader>cp',
    delete_comment = '<leader>cd',
    view = '<leader>cv',
    export = '<leader>ce',
    clear = '<leader>cc',
    summary = '<leader>cS',
    save = '<leader>cw',
    load = '<leader>cr',
    open_list = '<leader>co',
    next_comment = ']r',
    prev_comment = '[r',
    goto_real_file = '<leader>cg',
  },
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:ReviewAddIssue` | Add an ISSUE comment |
| `:ReviewAddSuggestion` | Add a SUGGESTION comment |
| `:ReviewAddNote` | Add a NOTE comment |
| `:ReviewAddPraise` | Add a PRAISE comment |
| `:ReviewDelete` | Delete comment at cursor |
| `:ReviewView` | View comment at cursor |
| `:ReviewExport` | Export to markdown and clipboard |
| `:ReviewClear` | Clear all comments |
| `:ReviewSave` | Save review to disk |
| `:ReviewLoad` | Load review from disk |
| `:ReviewSummary` | Show comment summary |
| `:ReviewGoto` | Jump to real file from diff |

## Documentation

See `:help quickfix-review` for full documentation.

## License

MIT
