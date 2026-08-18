-- Applies dotfiles/.config/nvim/lua/custom/wallbash-colors.lua, generated
-- by wallbash from the active HyDE theme (see
-- dotfiles/.config/hyde/wallbash/theme/nvim.dcol) — colors follow whatever
-- theme is active system-wide, not a fixed colorscheme plugin. pcall guards
-- a fresh clone before the first `hydectl theme set` has ever generated it.
local ok, err = pcall(require, 'custom.wallbash-colors')
if not ok then
  vim.notify('wallbash-colors not generated yet — run `hydectl theme set` once: ' .. err, vim.log.levels.WARN)
end
