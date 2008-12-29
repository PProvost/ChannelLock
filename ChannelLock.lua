--[[
ChannelLock/ChannelLock.lua

Copyright 2008 Quaiche

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

ChannelLock = LibStub("AceAddon-3.0"):NewAddon("ChannelLock", "AceConsole-3.0", "AceTimer-3.0")
ChannelLock.revision = tonumber(("$Revision$"):match("%d+"))
ChannelLock.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")

local TRADE_CHANNEL_NAME = "Trade - City"
local debugf = tekDebug and tekDebug:GetFrame("ChannelLock")

local knownTradeZones = {
	['Orgrimmar'] = 1,
	['Thunder Bluff'] = 1,
	['Undercity'] = 1,
	['Stormwind City'] = 1,
	['Darnassus'] = 1,
	['Ironforge'] = 1,
	['Shattrath City'] = 1,
	['Silvermoon City'] = 1,
	['The Exodar'] = 1,
	['Dalaran'] = 1,
}

function ChannelLock:OnInitialize()
	self.channelUpdates = {}
	self.stubs = {}

	self.defaults = self:GetDefaults()
	self.db = LibStub("AceDB-3.0"):New("ChannelLockDB", self.defaults, "Default")

	self.options = self:GetOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ChannelLock", self.options )
	LibStub("tekKonfig-AboutPanel").new(nil, "ChannelLock")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Channels", "ChannelLock", "channels")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Profiles", "ChannelLock", "profiles")
end

function ChannelLock:OnEnable()
	self:Debug(1, "Enable - Scheduling channel check")
	self:ScheduleTimer("CheckChannels", 2)
end

function ChannelLock:Debug(level, ...)
	if debugf then
		self:Print(debugf, ...)
	end
end

function ChannelLock:DebugF(level, ...)
	if debugf then
		self:Print(debugf, string.format(...))
	end
end

-- TODO: We really need to compare slot, name and frameIndex to build the right command queue
function ChannelLock:CheckChannels()
	local myChannels = self.db.profile.channels
	for i = 1,10 do
		self:DebugF(1, "CheckChannels - Checking channel %d", i)
		local id, name = GetChannelName(i)
		name = self:CleanChannelName(name)
		if myChannels[i] and myChannels[i].name then
			self:Debug(1, "CheckChannels - We have a configured channel for this slot")
			if myChannels[i].name ~= name then
				-- The wrong channel is in this slot, remove it before adding the correct one
				self:DebugF(1, "CheckChannels - Wrong channel in slot %d. Current=%s, Expected=%s", i, tostring(name), myChannels[i].name)
				if name then
					self:DebugF(1, "CheckChannels - Scheduling removal of channel=%s id=%d", name, id)
					table.insert(self.channelUpdates, { action="remove", id = i, name=name })
				end
				self:DebugF(1, "CheckChannels - Scheduling add of channel=%s id=%d frameIndex=%d", myChannels[i].name, i, myChannels[i].frameIndex)
				table.insert(self.channelUpdates, { action="add", id = i, name = myChannels[i].name, frameIndex = myChannels[i].frameIndex })
			else
				-- The right channel is in this slot, move on
				self:DebugF(1, "CheckChannels - %s is the correct channel for slot %d", name, i)
			end
		else
			-- There should be nothing in this slot, remove it, add a stub and schedule the stub removal
			if id > 0 and name then
				self:DebugF(1, "CheckChannels - Slot %d (%s) should be empty. Scheduling removal of current channel.", i, name)
				table.insert(self.channelUpdates, { action = "remove", id = i, name=name })
			end

			self:DebugF(1, "CheckChannels - Slot %d should be empty. Adding a stub for later removal", i)
			table.insert(self.channelUpdates, { action = "add", id = i, name = "QCHANNEL"..i, frameIndex=1 })
			table.insert(self.stubs, { action = "remove", id = i, name = "QCHANNEL"..i } )
		end
	end

	self.processingTimer = self:ScheduleRepeatingTimer("ProcessUpdatesQueue", 1)
end

function ChannelLock:ProcessUpdatesQueue()
	local item = table.remove(self.channelUpdates, 1)
	if not item then
		if self.stubs then
			self.channelUpdates = self.stubs
			self.stubs = nil
			item = table.remove(self.channelUpdates, 1)
		else
			self:Debug(1, "ProcessUpdatesQueue - Done processing update queue")
			self:CancelTimer(self.processingTimer)
			return
		end
	end

	self:DebugF(1, "ProcessUpdatesQueue - item.action=%s item.name=%s item.frameIndex=%d", item.action, tostring(item.name), item.frameIndex or 0)
	if item.action == "add" then
		self:JoinChannel(item.name, item.frameIndex)
	elseif item.action == "remove" then
		self:LeaveChannel(item.name, item.frameIndex)
	else
		self:DebugF(1, "Unknown action: %s", item.action)
	end
end

-- this reduces server zone channels (general, trade, etc to their base parts with no zone info)
function ChannelLock:CleanChannelName(channel)
	if (channel == nil) then return nil; end
	local spaceFound = string.find(channel, " ");
	if (spaceFound) then
		channel = string.sub(channel, 1, spaceFound - 1);
	end
	return channel;
end

local function NoopFilter() return true end

function ChannelLock:JoinChannel(channel, frameIndex)
	self:Debug(1, "JoinChannel - channel="..channel.." frameIndex="..frameIndex)
	local frame = "ChatFrame"..tostring(frameIndex)

	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
	if channel == "LookingForGroup" then SetLookingForGroup(3,5,3) end

	JoinPermanentChannel(channel, nil, frameIndex, nil)
	ChatFrame_AddChannel(_G[frame], channel)

	if channel == "LookingForGroup" then ClearLookingForGroup() end
	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
end

function ChannelLock:LeaveChannel(channel, frameIndex)
	if not channel then return end
	if not frameIndex then frameIndex = 1 end

	self:DebugF(1, "LeaveChannel - %s", channel)
	local frame = "ChatFrame"..tostring(frameIndex)

	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
	if channel == "LookingForGroup" then SetLookingForGroup(3, 5, 3) end
	if channel == TRADE_CHANNEL_NAME and not knownTradeZones(GetZoneText) then
		-- TODO: Schedule this for the next zone change
		self:Debug(1, "LeaveChannel - Unable to drop the Trade channel because you are not in a trade zone.")
	end

	-- ChatFrame_RemoveChannel(frame, channel)
	LeaveChannelByName(channel);

	if channel == "LookingForGroup" then ClearLookingForGroup() end
	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
end

