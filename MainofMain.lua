local Players = game:GetService("Players")
local MarketPlaceService = game:GetService("MarketplaceService")
_G.KaitunMode = true
local SupportedGames = {
    [84515722934860] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Anime-Expedition.lua",
        Kaitun = ""
    },
    [4442272183] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Throw-A-Coin.lua",
        Kaitun = ""
    },
    [137233438285284] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Chicken-Farm.lua",
        Kaitun = "" -- Leave empty if no Kaitun script exists for this game
    },
    [122391683154858] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Make-HotSauce.lua"
    },
    [94735232265626] = {
        Main = "https://raw.githubusercontent.com/loffy327/LoffyHUB/refs/heads/main/Merge-A-Nuke.lua"
    }
}

local UniversalScript = "none"

local function ExecuteScript(url, scriptName)
    print(string.format("[Hub Loader] Loading %s...", scriptName or "Script"))
    
    local cleanUrl = url .. "?nocache=" .. os.time()
    local success, response = pcall(function()
        return game:HttpGet(cleanUrl)
    end)

    if success then
        local loadedFunc, err = loadstring(response)
        if loadedFunc then
            task.spawn(loadedFunc)
            print("[Hub Loader] Script executed successfully!")
        else
            warn("[Hub Loader] Syntax Error: " .. tostring(err))
        end
    else
        warn("[Hub Loader] Connection Failed: " .. tostring(response))
    end
end

local currentPlaceId = game.PlaceId
local gameData = SupportedGames[currentPlaceId]

if gameData then
    local gameInfo
    pcall(function()
        gameInfo = MarketPlaceService:GetProductInfo(currentPlaceId)
    end)
    local gameName = gameInfo and gameInfo.Name or "Game ID: " .. tostring(currentPlaceId)
    
    local targetUrl = gameData.Main
    
    if _G.KaitunMode and gameData.Kaitun and gameData.Kaitun ~= "" then
        targetUrl = gameData.Kaitun
        gameName = gameName .. " (Kaitun Mode)"
    end

    ExecuteScript(targetUrl, gameName)
else
    warn("[Hub Loader] Current Game (" .. tostring(currentPlaceId) .. ") is not configured.")
    if UniversalScript and UniversalScript ~= "" then
        ExecuteScript(UniversalScript, "Universal Script")
    end
end
