--- Startup sequence.

local GB = GuildBeacon
local Internal = GB.Internal
local API = GB.API
local L = GB.Locale

local Bootstrap = {}
Internal.Bootstrap = Bootstrap

local bootFrame
local initialized = false
local playerLoggedIn = false

function Bootstrap:Start(addonName)
    if bootFrame then
        return
    end
    bootFrame = CreateFrame("Frame")
    bootFrame:RegisterEvent("ADDON_LOADED")
    bootFrame:RegisterEvent("PLAYER_LOGIN")
    bootFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" then
            local loaded = ...
            if loaded ~= addonName then
                return
            end
            Bootstrap:OnAddonLoaded()
        elseif event == "PLAYER_LOGIN" then
            Bootstrap:OnPlayerLogin()
        end
    end)
end

function Bootstrap:OnAddonLoaded()
    if initialized then
        return
    end
    Internal.ProfileManager:Initialize()
    Internal.Logger:Initialize()
    Internal.EventBus:Initialize()
    Internal.ModuleManager:Initialize()
    if GB.UI and GB.UI.Dashboard then
        GB.UI.Dashboard:Initialize()
    end
    if GB.UI and GB.UI.SlashCommands then
        GB.UI.SlashCommands:Initialize()
    end
    initialized = true
end

function Bootstrap:OnPlayerLogin()
    if playerLoggedIn then
        return
    end
    playerLoggedIn = true
    Internal.ProfileManager:EnsureProfileForPlayer()
    API:Print(L["ADDON_LOADED"], GB.Version)
    API:Print(L["TYPE_HELP"])
end
