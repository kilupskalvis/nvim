return {
  {
    "folke/flash.nvim",
    opts = {
      -- Flash ships history/register off, so an `s` jump left nothing for `n`
      -- to repeat -- the pattern was thrown away after the jump. Feeding both

      -- so `n` means "next match of whatever I last searched for" regardless of
      -- which key started it.
      --
      -- Cost: `s` overwrites the unnamed search register, so `n` no longer
      -- repeats an older `/` pattern once you have used `s`.
      --
      -- nohlsearch stays false so the matches keep their 'hlsearch'
      -- highlighting after the jump. Flash's backdrop disappears once you pick
      -- a label, and without the highlight there is nothing on screen telling
      -- you `n` still has somewhere to go.
      jump = {
        history = true,
        register = true,
        nohlsearch = false,
      },
    },
  },
}
