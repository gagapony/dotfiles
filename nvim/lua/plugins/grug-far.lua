return {
  "MagicDuck/grug-far.nvim",
  opts = function(_, opts)
    opts = opts or {}
    opts.startInInsertMode = false
    -- grug-far hardcodes border = 'rounded' for these three; winborder does not apply
    opts.helpWindow = { border = "none" }
    opts.historyWindow = { border = "none" }
    opts.previewWindow = { border = "none" }
    return opts
  end
}
