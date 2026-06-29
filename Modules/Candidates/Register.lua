local GB = GuildBeacon
local M = GB.Modules.Candidates
if M and M.Module and GB.Internal.ModuleManager then
    GB.Internal.ModuleManager:Register(M.Module:GetMeta())
end
