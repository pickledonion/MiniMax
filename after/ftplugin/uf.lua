-- uf file comment settings and mappings.
vim.bo.commentstring = '// %s'
vim.bo.comments = 's1:/*,mb:*,ex:*/,://'

-- Remove default `gc` mappings (for example from mini.comment) in uf buffers so
-- `gcm` resolves to our custom behavior instead of `gc` operator-pending.
pcall(vim.keymap.del, 'n', 'gc', { buffer = 0 })
pcall(vim.keymap.del, 'x', 'gc', { buffer = 0 })
pcall(vim.keymap.del, 'o', 'gc', { buffer = 0 })
pcall(vim.keymap.del, 'n', 'gcc', { buffer = 0 })

local function toggle_line_comment()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ''
  local indent, body = line:match('^(%s*)(.*)$')
  local uncommented = body:gsub('^//%s?', '', 1)

  if uncommented ~= body then
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { indent .. uncommented })
    return
  end

  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { indent .. '// ' .. body })
end

local function comment_selection_multiline()
  local vpos = vim.fn.getpos('v')
  local cpos = vim.fn.getcurpos()
  local srow, scol = vpos[2], vpos[3] - 1
  local erow, ecol = cpos[2], cpos[3] - 1

  if srow == 0 or erow == 0 then
    return
  end

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local text = vim.api.nvim_buf_get_text(0, srow - 1, scol, erow - 1, ecol + 1, {})
  local selected = table.concat(text, '\n')
  local replacement
  if selected:sub(1, 2) == '/*' and selected:sub(-2) == '*/' then
    replacement = selected:gsub('^/%*%s*', '', 1):gsub('%s*%*/$', '', 1)
  else
    replacement = '/* ' .. selected .. ' */'
  end

  local out = replacement == '' and { '' } or vim.split(replacement, '\n', { plain = true })
  vim.api.nvim_buf_set_text(0, srow - 1, scol, erow - 1, ecol + 1, out)

  local new_end_row = srow + #out - 1
  local new_end_col
  if #out == 1 then
    new_end_col = scol + #out[1] - 1
  else
    new_end_col = #out[#out] - 1
  end

  vim.fn.setpos("'<", { 0, srow, scol + 1, 0 })
  vim.fn.setpos("'>", { 0, new_end_row, new_end_col + 1, 0 })
  vim.cmd('normal! gv')
end

local function uncomment_multiline_at_cursor()
  local pos = vim.api.nvim_win_get_cursor(0)
  local lnum = pos[1]
  local col1 = pos[2] + 1
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ''

  local open_s, open_e
  local idx = 1
  while true do
    local s, e = line:find('/*', idx, true)
    if not s or s > col1 then
      break
    end
    open_s, open_e = s, e
    idx = s + 1
  end

  if not open_s then
    return
  end

  local close_s, close_e = line:find('*/', col1, true)
  if not close_s or open_s >= close_s then
    return
  end

  local before = line:sub(1, open_s - 1)
  local inner = line:sub(open_e + 1, close_s - 1)
  local after = line:sub(close_e + 1)

  if inner:sub(1, 1) == ' ' then
    inner = inner:sub(2)
  end
  if inner:sub(-1) == ' ' then
    inner = inner:sub(1, -2)
  end

  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { before .. inner .. after })
  return
end

local function comment_word_at_cursor()
  local pos = vim.api.nvim_win_get_cursor(0)
  local lnum = pos[1]
  local col0 = pos[2]
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ''

  local left = col0 + 1
  local right = col0 + 1

  while left > 1 and line:sub(left - 1, left - 1):match('[%w_]') do
    left = left - 1
  end
  while right <= #line and line:sub(right, right):match('[%w_]') do
    right = right + 1
  end

  if left == right then
    return
  end

  local token = line:sub(left, right - 1)
  local replacement = '/* ' .. token .. ' */'
  vim.api.nvim_buf_set_text(0, lnum - 1, left - 1, lnum - 1, right - 1, { replacement })
end

local function gcm_normal()
  local pos = vim.api.nvim_win_get_cursor(0)
  local lnum = pos[1]
  local col1 = pos[2] + 1
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ''

  local open_s
  local idx = 1
  while true do
    local s = line:find('/*', idx, true)
    if not s or s > col1 then
      break
    end
    open_s = s
    idx = s + 1
  end

  if open_s then
    local close_s = line:find('*/', col1, true)
    if close_s and open_s < close_s then
      uncomment_multiline_at_cursor()
      return
    end
  end

  comment_word_at_cursor()
end

vim.keymap.set('n', 'gcc', toggle_line_comment, { buffer = true, silent = true, nowait = true, desc = 'Toggle // comment on line' })
vim.keymap.set('x', 'gcm', comment_selection_multiline, { buffer = true, silent = true, nowait = true, desc = 'Comment selection as /* */' })
vim.keymap.set('n', 'gcm', gcm_normal, { buffer = true, silent = true, nowait = true, desc = 'Toggle /* */ at cursor or comment cword' })
