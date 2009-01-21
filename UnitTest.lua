-- 
-- This file is meant to be run from a wowlua interactive shell
--

require("WowStubs")
require("TocLoader")
require("Utils")
require("Libs/LuaUnit/LuaUnit")

ChannelLockTests = {}

-- Bogus SV setup for tests
ChannelLockDB = {
	["profileKeys"] = {
		["Quaiche - Dragonblight"] = "Default",
	},
	["profiles"] = {
		["Default"] = {
			["channels"] = {
				[3] = {
					["name"] = "Pissoff",
					["frameIndex"] = "3",
				},
				[5] = {
					["name"] = "DBAOF",
					["frameIndex"] = "3",
				},
				[6] = {
					["name"] = "BTRL09",
					["frameIndex"] = "4",
				},
			},
		},
	},
}

function ChannelLockTests:setUp()
	-- Only do this once
	if not self.addonLoaded then
		LoadToc("ChannelLock.toc")
		WowStubs.isLoggedIn = true
		WowStubs:RaiseEvent("PLAYER_LOGIN")
		WowStubs:RaiseEvent("VARIABLES_LOADED")
		WowStubs:RaiseEvent("ADDON_LOADED", "ChannelLock")
		self.addonLoaded = true
	end
end

local channels = {}

_G["GetChannelName"] = function(id)
	if channels[id] then
		return unpack(channels[id])
	else
		return 0, nil
	end
end

function ChannelLockTests:test_DBStuff()
	channels = {
		[1] = { 1, "General" },
		[2] = { 2, "Trade" },
		[3] = { 3, "Somecrap" },
	}

	ChannelLock:CheckChannels()

	print( table.to_string(ChannelLock.channelUpdates) )
	print( table.to_string(ChannelLock.stubs) )
end

LuaUnit:run('ChannelLockTests')

