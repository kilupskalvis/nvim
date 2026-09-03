return {
  "sphamba/smear-cursor.nvim",
  opts = {
    smear_between_buffers = true,
    smear_between_neighbor_lines = true,
    smear_to_cmd = true,
    -- Screen space: in buffer space every wheel tick drew a trail across the
    -- viewport and kept animating through the scroll.
    scroll_buffer_space = false,
    -- hide_target_hack was on without never_draw_over_target, which the
    -- plugin's config warns against: the cell under the cursor flickered.
    hide_target_hack = false,
    -- Fast head, lagging tail: snappy cursor, long trail. Defaults were
    -- 0.6 / 0.45 / 0.85 / 0.1 / 17.
    stiffness = 0.8,
    trailing_stiffness = 0.35,
    damping = 0.9,
    distance_stop_animating = 0.3,
    time_interval = 7,
  },
}
