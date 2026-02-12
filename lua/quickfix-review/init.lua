-- Code Review System using Quickfix + Signs
-- Supports regular files and diff buffers (diffview, fugitive, codediff)
local M = {}

local config = require('quickfix-review.config')
local utils = require('quickfix-review.utils')
local storage = require('quickfix-review.storage')
local export = require('quickfix-review.export')

-- Add comment to quickfix and place sign
-- Optional range parameter: { start_line, end_line } for multiline comments
function M.add_comment(comment_type, range)
  local file = utils.get_real_filepath()
  local start_line, end_line

  if range then
    start_line = range[1]
    end_line = range[2]
  else
    start_line = vim.fn.line('.')
    end_line = start_line
  end

  local prompt = comment_type .. ' comment'
  if start_line ~= end_line then
    prompt = prompt .. ' (L' .. start_line .. '-' .. end_line .. ')'
  end
  local text = vim.fn.input(prompt .. ': ')

  if text ~= '' then
    local qf_list = vim.fn.getqflist()

    -- Format text with line range if multiline
    local comment_text
    if start_line ~= end_line then
      comment_text = string.format('[%s:L%d-%d] %s', comment_type:upper(), start_line, end_line, text)
    else
      comment_text = string.format('[%s] %s', comment_type:upper(), text)
    end

    table.insert(qf_list, {
      filename = file,
      lnum = start_line,
      end_lnum = end_line,
      col = 1,
      text = comment_text,
      type = comment_type:sub(1, 1):upper()
    })
    vim.fn.setqflist(qf_list, 'r')
    vim.fn.setqflist({}, 'a', { title = 'Code Review Comments' })

    if not utils.is_special_buffer() then
      utils.place_comment_signs(vim.fn.bufnr(), comment_type, start_line, end_line)
    end

    local display_file = vim.fn.fnamemodify(file, ':.')
    if start_line ~= end_line then
      print(comment_type:upper() .. ' added to ' .. display_file .. ':' .. start_line .. '-' .. end_line)
    else
      print(comment_type:upper() .. ' added to ' .. display_file .. ':' .. start_line)
    end
  end
end

-- Add comment from visual selection
function M.add_comment_visual(comment_type)
  -- Exit visual mode first to set the '< and '> marks
  vim.cmd('normal! \27')  -- ESC to exit visual mode

  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  -- Ensure start_line is less than or equal to end_line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  M.add_comment(comment_type, { start_line, end_line })
end

-- Jump to real file from diff buffer
function M.goto_real_file()
  if not utils.is_special_buffer() then
    print('Already in a regular file')
    return
  end

  local real_file = utils.get_real_filepath()
  local line = vim.fn.line('.')

  if real_file:match('^diffview://') or real_file:match('^fugitive://') or real_file:match('^codediff://') then
    print('Error: Cannot determine real file from buffer')
    return
  end

  vim.cmd('edit +' .. line .. ' ' .. vim.fn.fnameescape(real_file))
  print('Jumped to ' .. vim.fn.fnamemodify(real_file, ':.') .. ':' .. line)
end

-- Export to markdown
function M.export_review()
  local qf_list = vim.fn.getqflist()

  if #qf_list == 0 then
    print('No comments to export')
    return
  end

  local content, err = export.to_markdown(qf_list, config.options)
  if not content then
    print(err or 'Export failed')
    return
  end

  local success, message = export.to_clipboard_and_file(content, config.options.export_file)
  if success then
    print(message .. ' (' .. #qf_list .. ' comments)')
  else
    print(message)
  end
end

-- Clear all review comments
function M.clear_review()
  vim.fn.setqflist({})
  -- Clear extmarks from all buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, utils.get_ns_id(), 0, -1)
    end
  end
  print('Review cleared')
end

-- Save current review to file
function M.save_review()
  local qf_list = vim.fn.getqflist()
  local success, message = storage.save(qf_list, config.options.storage_file)
  print(message)
end

-- Load review from file
function M.load_review()
  local qf_list, message = storage.load(config.options.storage_file)

  if not qf_list then
    print(message)
    return
  end

  vim.fn.setqflist(qf_list, 'r')
  vim.fn.setqflist({}, 'a', { title = 'Code Review Comments' })

  -- Restore signs for loaded comments
  for _, item in ipairs(qf_list) do
    local comment_type = utils.parse_comment_type(item.text)
    local filename = item.filename
    if filename and type(filename) == 'string' and filename ~= '' then
      local bufnr = vim.fn.bufnr(filename)
      if bufnr ~= -1 then
        utils.place_comment_signs(bufnr, comment_type, item.lnum, item.end_lnum or item.lnum)
      end
    end
  end

  print(message)
end

-- Show comment(s) at current line
function M.view_comment()
  local file = utils.get_real_filepath()
  local line = vim.fn.line('.')
  local qf_list = vim.fn.getqflist()

  local comments = {}
  for _, item in ipairs(qf_list) do
    local item_file = item.filename or vim.fn.bufname(item.bufnr)
    if item.lnum == line and utils.files_match(item_file, file) then
      table.insert(comments, item.text)
    end
  end

  if #comments == 0 then
    print('No comment on this line')
  elseif #comments == 1 then
    print(comments[1])
  else
    print(string.format('%d comments on this line:', #comments))
    for i, comment in ipairs(comments) do
      print(string.format('  %d. %s', i, comment))
    end
  end
end

-- Show summary of current review
function M.summary()
  local qf_list = vim.fn.getqflist()

  if #qf_list == 0 then
    print('No review comments')
    return
  end

  local counts = { ISSUE = 0, SUGGESTION = 0, NOTE = 0, PRAISE = 0 }
  for _, item in ipairs(qf_list) do
    local comment_type = utils.parse_comment_type(item.text)
    if counts[comment_type] then
      counts[comment_type] = counts[comment_type] + 1
    end
  end

  print(string.format('Review: %d total (%d issues, %d suggestions, %d notes, %d praise)',
    #qf_list, counts.ISSUE, counts.SUGGESTION, counts.NOTE, counts.PRAISE))
end

-- Delete comment(s) at current line or selected range
function M.delete_comment(range)
  local file = utils.get_real_filepath()
  local start_line, end_line
  
  if range then
    start_line = range[1]
    end_line = range[2]
  else
    start_line = vim.fn.line('.')
    end_line = start_line
  end
  
  local qf_list = vim.fn.getqflist()
  local new_qf_list = {}
  local comments_deleted = 0
  
  -- Filter out comments in the specified range
  for _, item in ipairs(qf_list) do
    local item_file = item.filename or vim.fn.bufname(item.bufnr)
    local item_end = item.end_lnum or item.lnum

    -- Check if this comment overlaps with the target range and file
    local is_in_range = utils.files_match(item_file, file) and
                        item.lnum <= end_line and item_end >= start_line

    if not is_in_range then
      table.insert(new_qf_list, item)
    else
      comments_deleted = comments_deleted + 1
    end
  end
  
  if comments_deleted > 0 then
    vim.fn.setqflist(new_qf_list, 'r')
    vim.fn.setqflist({}, 'a', { title = 'Code Review Comments' })
    
    -- Remove and re-add signs for proper visualization
    if not utils.is_special_buffer() then
      local bufnr = vim.fn.bufnr()
      -- Clear extmarks for this buffer
      vim.api.nvim_buf_clear_namespace(bufnr, utils.get_ns_id(), 0, -1)

      -- Re-add signs for remaining comments in this file
      for _, item in ipairs(new_qf_list) do
        local item_file = item.filename or vim.fn.bufname(item.bufnr)
        if utils.files_match(item_file, file) then
          local comment_type = utils.parse_comment_type(item.text)
          utils.place_comment_signs(bufnr, comment_type, item.lnum, item.end_lnum or item.lnum)
        end
      end
    end
    
    local display_file = vim.fn.fnamemodify(file, ':.')
    if start_line ~= end_line then
      print(string.format('Deleted %d comment(s) from %s:%d-%d', comments_deleted, display_file, start_line, end_line))
    else
      print(string.format('Deleted %d comment(s) from %s:%d', comments_deleted, display_file, start_line))
    end
  else
    local display_file = vim.fn.fnamemodify(file, ':.')
    if start_line ~= end_line then
      print(string.format('No comments found in %s:%d-%d', display_file, start_line, end_line))
    else
      print(string.format('No comments found in %s:%d', display_file, start_line))
    end
  end
end

-- Delete comment from visual selection
function M.delete_comment_visual()
  -- Exit visual mode first to set the '< and '> marks
  vim.cmd('normal! \27')  -- ESC to exit visual mode

  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  -- Ensure start_line is less than or equal to end_line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  M.delete_comment({ start_line, end_line })
end

-- Setup keymaps based on configuration
local function setup_keymaps()
  local keymaps = config.options.keymaps

  if keymaps.add_issue then
    vim.keymap.set('n', keymaps.add_issue, function() M.add_comment('ISSUE') end,
      { desc = 'Add ISSUE comment' })
    vim.keymap.set('v', keymaps.add_issue, function() M.add_comment_visual('ISSUE') end,
      { desc = 'Add ISSUE comment for selection' })
  end
  if keymaps.add_suggestion then
    vim.keymap.set('n', keymaps.add_suggestion, function() M.add_comment('SUGGESTION') end,
      { desc = 'Add SUGGESTION comment' })
    vim.keymap.set('v', keymaps.add_suggestion, function() M.add_comment_visual('SUGGESTION') end,
      { desc = 'Add SUGGESTION comment for selection' })
  end
  if keymaps.add_note then
    vim.keymap.set('n', keymaps.add_note, function() M.add_comment('NOTE') end,
      { desc = 'Add NOTE comment' })
    vim.keymap.set('v', keymaps.add_note, function() M.add_comment_visual('NOTE') end,
      { desc = 'Add NOTE comment for selection' })
  end
  if keymaps.add_praise then
    vim.keymap.set('n', keymaps.add_praise, function() M.add_comment('PRAISE') end,
      { desc = 'Add PRAISE comment' })
    vim.keymap.set('v', keymaps.add_praise, function() M.add_comment_visual('PRAISE') end,
      { desc = 'Add PRAISE comment for selection' })
  end
  if keymaps.add_question then
    vim.keymap.set('n', keymaps.add_question, function() M.add_comment('QUESTION') end,
      { desc = 'Add QUESTION comment' })
    vim.keymap.set('v', keymaps.add_question, function() M.add_comment_visual('QUESTION') end,
      { desc = 'Add QUESTION comment for selection' })
  end
  if keymaps.add_insight then
    vim.keymap.set('n', keymaps.add_insight, function() M.add_comment('INSIGHT') end,
      { desc = 'Add INSIGHT comment' })
    vim.keymap.set('v', keymaps.add_insight, function() M.add_comment_visual('INSIGHT') end,
      { desc = 'Add INSIGHT comment for selection' })
  end
  
  -- Add keymaps for comment deletion
  if keymaps.delete_comment then
    vim.keymap.set('n', keymaps.delete_comment, function() M.delete_comment() end,
      { desc = 'Delete comment at current line' })
    vim.keymap.set('v', keymaps.delete_comment, M.delete_comment_visual,
      { desc = 'Delete comments in selection' })
  end

  if keymaps.export then
    vim.keymap.set('n', keymaps.export, M.export_review,
      { desc = 'Export review to markdown' })
  end
  if keymaps.clear then
    vim.keymap.set('n', keymaps.clear, M.clear_review,
      { desc = 'Clear all review comments' })
  end
  if keymaps.summary then
    vim.keymap.set('n', keymaps.summary, M.summary,
      { desc = 'Show review summary' })
  end

  if keymaps.save then
    vim.keymap.set('n', keymaps.save, M.save_review,
      { desc = 'Save review to disk' })
  end
  if keymaps.load then
    vim.keymap.set('n', keymaps.load, M.load_review,
      { desc = 'Load review from disk' })
  end

  if keymaps.open_list then
    vim.keymap.set('n', keymaps.open_list, ':copen<CR>',
      { desc = 'Open review comments list' })
  end
  if keymaps.next_comment then
    vim.keymap.set('n', keymaps.next_comment, ':cnext<CR>',
      { desc = 'Next review comment' })
  end
  if keymaps.prev_comment then
    vim.keymap.set('n', keymaps.prev_comment, ':cprev<CR>',
      { desc = 'Previous review comment' })
  end

  if keymaps.goto_real_file then
    vim.keymap.set('n', keymaps.goto_real_file, M.goto_real_file,
      { desc = 'Go to real file from diff' })
  end

  if keymaps.view then
    vim.keymap.set('n', keymaps.view, M.view_comment,
      { desc = 'View comment on current line' })
  end
end

-- Delete comment from quickfix window
function M.delete_comment_from_qf()
  local qf_list = vim.fn.getqflist()
  local current_idx = vim.fn.line('.')
  
  if current_idx < 1 or current_idx > #qf_list then
    print('No comment selected in quickfix list')
    return
  end
  
  local item = qf_list[current_idx]
  local file = item.filename
  local start_line = item.lnum
  local end_line = item.end_lnum or start_line
  
  -- Delete the comment
  M.delete_comment({ start_line, end_line })
  
  -- Refresh quickfix window
  vim.cmd('copen')
end

-- Setup the plugin
function M.setup(opts)
  config.setup(opts)
  utils.init_signs(config.options)
  setup_keymaps()

  -- Prompt to clear comments when file is reloaded from disk
  if config.options.prompt_on_file_change then
    vim.api.nvim_create_autocmd('FileChangedShellPost', {
      callback = function()
        local file = utils.get_real_filepath()
        local qf_list = vim.fn.getqflist()
        local has_comments = false
        for _, item in ipairs(qf_list) do
          local item_file = item.filename or vim.fn.bufname(item.bufnr)
          if utils.files_match(item_file, file) then
            has_comments = true
            break
          end
        end
        if has_comments then
          local choice = vim.fn.confirm('File changed on disk. Clear review comments for this file?', '&Yes\n&No', 2)
          if choice == 1 then
            M.clear_review()
          end
        end
      end
    })
  end

  -- Set up quickfix window configuration and keymaps
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
      -- Configure quickfix window for better display of multiline comments
      vim.opt_local.wrap = false
      vim.opt_local.number = true
      vim.opt_local.relativenumber = false

      -- Add keymaps for comment deletion
      vim.keymap.set('n', 'dd', M.delete_comment_from_qf, {
        buffer = true,
        desc = 'Delete comment from quickfix list'
      })
      vim.keymap.set('n', '<leader>cd', M.delete_comment_from_qf, {
        buffer = true,
        desc = 'Delete comment from quickfix list'
      })
      
      -- Add keymap to refresh quickfix display
      vim.keymap.set('n', '<leader>cr', function()
        vim.cmd('copen')
        print('Quickfix list refreshed')
      end, {
        buffer = true,
        desc = 'Refresh quickfix list'
      })
    end
  })
end

return M
