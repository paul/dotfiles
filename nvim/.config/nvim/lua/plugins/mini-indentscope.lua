return {
  {
    "echasnovski/mini.indentscope",
    opts = {
      delay = 10,
      -- disable the distracting animation of the bar
      draw = { animation = require("mini.indentscope").gen_animation.none() },
    },
  },
}
