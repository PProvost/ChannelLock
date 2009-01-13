-- 
-- This file is meant to be run from a wowlua interactive shell
--

require("WowStubs")
require("TocLoader")

LoadToc("ChannelLock.toc")

local TestFixture = {}

local function PlayerLogin()
	WowStubs.isLoggedIn = true
	FireEvent("ADDON_LOADED", "ChannelLock")
	FireEvent("PLAYER_LOGIN")
end
table.insert(TestFixture, PlayerLogin)

for i,v in ipairs(TestFixture) do
	pcall(v)
end
