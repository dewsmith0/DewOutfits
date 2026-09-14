local DewOutfits = require("DewOutfits")

vanilla_model.PLAYER:setVisible(false)
local page = action_wheel:newPage()
action_wheel:setPage(page)
DewOutfits.addAction(page)
