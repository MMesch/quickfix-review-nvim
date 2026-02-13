# quickfix-review.nvim

A lightweight code review system for Neovim using the built-in quickfix list and signs. You can use it to annotate files or git diffs in neovim with comments of varying type and export them for an AI agent (see screencast below).

## Comparison to other tools

This tool was inspired by:

- [tuicr](https://github.com/agavra/tuicr/), in particular the different comment types and report structure. Many thanks for that. It has a great interface but I wanted something integrated into my editor (keeping LSPs etc), and also a solution that allows me to review entire files and not diffs.
- [Review.nvim](https://github.com/georgeguimaraes/review.nvim), a nice nvim version of tuicr. I wanted a lighter weight solution that also works for reviewing non-diff files.I therefore decided to use the quickfix mechanics and the sign column for this plugin.

## Screencast

[Screencast From 2026-02-13 17-53-29.webm](https://github.com/user-attachments/assets/4e22c039-0efe-4e6f-856c-ac8cc03a5c11)


## Features

- **Six default comment types**: ISSUE, SUGGESTION, NOTE, PRAISE, QUESTION, INSIGHT
- **Customizable comment types**: Add your own or replace defaults entirely
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
2. Press `<leader>ci` to add an ISSUE comment (or `cs`/`cn`/`cp`/`cq`/`ck` for other types)
3. Enter your comment text
4. Use `]r` and `[r` to navigate between comments
5. Press `<leader>ce` to export the review to markdown

### Comment Type Cycling

For faster workflow, use the cycling feature:
1. Press `+` to cycle through comment types (or `-` to go backwards)
2. Press `<leader>ca` to add a comment with the current type

The current comment type is shown in the status message.

### Running Tests

To run the test suite:

```bash
nvim --headless -c 'lua dofile("test/run.lua")' -c 'qa!'
```

The tests will:
- Verify all comment types work correctly
- Check sign placement and parsing
- Test add/delete functionality
- Validate persistence (save/load)

**Note**: The test output includes a "Plugin version check" line confirming the current plugin version is being tested.

## Configuration

All options are optional. Here's the full configuration with defaults:

```lua
require('quickfix-review').setup({
  -- Storage file for saving/loading reviews
  storage_file = vim.fn.stdpath('data') .. '/quickfix-review.json',

  -- Export filename (nil = clipboard only)
  export_file = nil,

  -- Prompt to clear comments when file changes on disk
  prompt_on_file_change = false,

  -- Comment types: replaces all defaults if provided (see Custom comment types)
  -- comment_types = { ... },

  -- Additional comment types: merged with defaults
  -- additional_comment_types = { ... },

  -- Keymaps (set to false to disable)
  -- Default type keymaps: add_issue, add_suggestion, add_note,
  --   add_praise, add_question, add_insight (all <leader>c + first letter)
  keymaps = {
    -- Comment type cycling
    add_comment_cycle = '<leader>ca',  -- Add comment with current cycle type
    cycle_next = '+',                  -- Cycle to next type
    cycle_previous = '-',              -- Cycle to previous type

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

### Multiple signs per line

To display multiple comment signs side by side (when a line has multiple comments), configure your signcolumn:

```lua
vim.opt.signcolumn = "yes:2"  -- Reserve 2 columns for signs
```

### Custom comment types

To **add** types while keeping defaults, use `additional_comment_types`:

```lua
require('quickfix-review').setup({
  additional_comment_types = {
    security = { sign = '🔒', highlight = 'DiagnosticError', description = 'Security concern' },
    perf = { sign = '⚡', highlight = 'DiagnosticWarn', description = 'Performance issue' },
  },
  keymaps = {
    add_security = '<leader>cx',
    add_perf = '<leader>cf',
  },
})
```

To **replace** defaults entirely, use `comment_types`:

```lua
require('quickfix-review').setup({
  comment_types = {
    bug = { sign = '🐛', highlight = 'DiagnosticError', description = 'Bug' },
    idea = { sign = '💡', highlight = 'DiagnosticInfo', description = 'Idea' },
  },
  keymaps = {
    add_bug = '<leader>cb',
    add_idea = '<leader>ci',
  },
})
```

Signs and continuation signs are auto-generated. The `description` field is shown during type cycling and in the export legend.

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
