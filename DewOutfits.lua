--=== DewOutfits by Dewsmith ===--
-- Version: 1.0.1
-- License: CC-BY-NC-SA 4.0 
-- Exception: FiguraMC Verified Creators may use this script in paid avatars or commissions sold through the official FiguraMC Discord.
--            Please do tell me if you do use it like that. 
-- GitHub: https://github.com/dewsmith0/DewOutfits
-- getNextScrollOption() and getScrollTitle() by Dyrris__, used with permission.

-- =========================== CONFIG ===========================
-- You may change your model root here
local modelRoot = models.model.root
local cfg = {
    parts = {
        -- Specify model parts the outfit should use

    modelRoot.Body.OutfitShirt,

    modelRoot.LeftArm.OutfitLeftSleeve, modelRoot.LeftArm.OutfitLeftSleeveLayer2,
    modelRoot.RightArm.OutfitRightSleeve, modelRoot.RightArm.OutfitRightSleeveLayer2,

    modelRoot.LeftLeg.OutfitLeftPants, modelRoot.LeftLeg.OutfitLeftPantsLayer2,
    modelRoot.RightLeg.OutfitRightPants, modelRoot.RightLeg.OutfitRightPantsLayer2,
    },
    -- How many texture (base64) bytes to send per ping (twice per second).
    -- Don't increase this too much. The higher this is, the more likely you are to hit the ping limit,
    -- but the faster outfits will be sent. Pings actually have about 7 more bytes, for the outfit and chunk IDs.
    -- If you're a supporter, you may be able to double this. The most I've successfully tested it with was 1000 bytes with supporter.
    -- You can also decrease it, if you're having problems with ping warnings.
    -- Default: 400 | Type: Integer
    chunkSize = 400,
    -- How often (in ticks) to reping outfits, so people who didn't get them fully the first time can receive them.
    -- Default: 800 | Type: Integer
    repingTime = 800,
    -- The name of the folder in data to search for outfits. If it does not exist, it will be created.
    -- Default: "DewOutfits/" | Type: String
    outfitDir = "DewOutfits/",
}
--=========================== VIEWER CODE ===========================
local outfitBuffer = {} -- stores partially loaded outfits
local expectedSizes = {} -- stores buffer sizes of outfits
local outfitCache = {} -- stores fully loaded outfits
local outfitIdMap = {} 
local isPinging = false


local function applyOutfit(texture)
    if not texture then 
        for i = 1, #cfg.parts do
            cfg.parts[i]:setVisible(false)
        end
        return
    end
    for i = 1, #cfg.parts do
        cfg.parts[i]:setPrimaryTexture("CUSTOM", texture):setVisible(true)
    end
end


local function equipOutfit(id)
    if not id then
        applyOutfit(nil)
        return
    end
    if type(outfitCache[id]) == "Texture" then applyOutfit(outfitCache[id]) end
    local bufferEntry = outfitBuffer[id]
    if not bufferEntry then --[[print("[DewOutfits] buffer is nil")]] return end
    if #bufferEntry ~= expectedSizes[id] then --[[print("[DewOutfits] size mismatch", #bufferEntry, expectedSizes[id])]] return end
    local parsedTexture = table.concat(bufferEntry, "", 1, #bufferEntry)
    local success, result = pcall(textures.read, textures, id, parsedTexture)
    if not success then print("outfit error:", result); return end 
    outfitCache[id] = result
    applyOutfit(result)
end

local function tryLoadCachedOutfit(name) 
    if type(outfitCache[name]) == "Texture" then equipOutfit(name) end
end

function pings.outfitHeader(name, id, size)
    tryLoadCachedOutfit(name)
    expectedSizes[name] = size 
    outfitBuffer[name] = {}
    outfitIdMap[id] = name
end

function pings.outfitData(id, num, chunk)
    local name = outfitIdMap[id]  
    if not name then return end
    outfitBuffer[name][num] = chunk
    if #outfitBuffer[name] == expectedSizes[name] then 
        equipOutfit(name)
    end
end

-- error prevention so calling newAction() on nonhost doesn't error
local lib = {}
lib.addAction = function () end

--=========================== HOST ONLY PART ===========================
if not host:isHost() then return lib end

local hoveredIndex = 1 -- index of the scrolled outfit option in the menu
local selectedIndex = 1 -- menu index of the selected outfit 
local outfitNames = { "<None>" } -- "<None>" is a special value that unequips the current outfit, do not change
local nextOutfit = nil -- name of the outfit currently being pinged
local reping = false -- whether we are repinging the outfit
local pingBuffer = {} -- stores the outfit that is currently being pinged, used in the ping event
local pingIndex = 1 -- count of pinged chunks for the current outfit

if not file:exists(cfg.outfitDir) then 
    file:mkdir(cfg.outfitDir)
    print("[DewOutfits] The outfits directory has been created at: ", cfg.outfitDir, ". You can change this path in the config.")
end
local outfitCount = 1 -- so the iterator doesn't break on non-png files
for i, fileName in ipairs(file:list(cfg.outfitDir)) do 
    local name, ext = fileName:match("^([^.]+)%.?(.*)")
    if ext == "png" and file:isFile(cfg.outfitDir..fileName) then
        outfitCount = outfitCount + 1
        outfitNames[outfitCount] = fileName
    end
    
end

local function splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = text:sub(i,i+chunkSize - 1)
    end
    return s
end

local function startPinging(textureName)
    if textureName == "<None>" then 
        equipOutfit(nil)
        return
    end
    nextOutfit = textureName
    pingBuffer = {}
    local texturefile = cfg.outfitDir..textureName
    local textureBuffer = data:createBuffer(1024000)
    local success, result = pcall(file.openReadStream, file, texturefile)
    if not success then print("[DewOutfits] Failed to open read stream:", result) return end
    local stream = result
    textureBuffer:readFromStream(stream)
    local bufferLen = textureBuffer:getLength()
    textureBuffer:setPosition(0)
    local base64 = textureBuffer:readBase64(bufferLen)
    local b64Len = string.len(base64)
    expectedSizes[textureName] = math.ceil(b64Len / cfg.chunkSize)

    pings.outfitHeader(textureName, selectedIndex, math.ceil(b64Len / cfg.chunkSize))
    pingBuffer = splitByChunk(base64, cfg.chunkSize)
    isPinging = true
    textureBuffer:close()
    stream:close()
end

local function getNextScrollOption(currentlySelected, selectionTable, scrollDir) -- by Dyrris__
    return (currentlySelected + -scrollDir - 1) % #selectionTable + 1
end

local function getScrollTitle(currentlySelected, selectionTable, mainTitle) -- by Dyrris__
    local tbl = {}
    tbl[#tbl+1] = { text = mainTitle, color = "#FFFFFF" }
    for index, title in ipairs(selectionTable) do
        if index == currentlySelected then
            tbl[#tbl+1] = { text = "\n> "..title, color = "#F3C738" }
        else
            tbl[#tbl+1] = { text = "\n  "..title, color = "#797979" }
        end
    end
    return toJson(tbl)
end

local outfitAction = action_wheel:newAction()
    :title(getScrollTitle(hoveredIndex, outfitNames, "Select Outfit | Equipped: <None>"))
    :item("leather_chestplate")
    :color(vectors.hexToRGB("#ff7c00"))

function outfitAction.leftClick() 
    if isPinging then 
        log("Please wait for the current ping to finish.")
        return
    end
    selectedIndex = hoveredIndex
    reping = false
    outfitAction:setTitle(getScrollTitle(hoveredIndex,outfitNames, "Select Outfit | Equipped: "..outfitNames[selectedIndex]))
    startPinging(outfitNames[selectedIndex])
end

function outfitAction.scroll(dir)
    hoveredIndex = getNextScrollOption(hoveredIndex, outfitNames, dir)
    outfitAction:setTitle(getScrollTitle(hoveredIndex,outfitNames, "Select Outfit | Equipped: "..outfitNames[selectedIndex]))
end

events.TICK:register(function ()
    if not isPinging then
        if world.getTime() % cfg.repingTime == 0 then
            reping = true
            startPinging(outfitNames[selectedIndex])
            return 
        end
        return
    end
    host:actionbar(toJson({
        color="#1ecafd",
        text=((reping and "Repinging: " or "Pinging: ").. outfitNames[selectedIndex] .. " " .. tostring(pingIndex).. "/" .. expectedSizes[outfitNames[selectedIndex]] .." chunks"), 
    }))
    if world.getTime() % 10 == 0 then 
        pings.outfitData(selectedIndex, pingIndex, pingBuffer[pingIndex])
        if expectedSizes[nextOutfit] and pingIndex >= expectedSizes[nextOutfit] then
            isPinging = false
            pingIndex = 1
        else
            pingIndex = pingIndex + 1
        end
    end

end)
---@param page Page The action wheel page to add the outfits menu to.
function lib.addAction(page) page:setAction(-1, outfitAction) end
return lib