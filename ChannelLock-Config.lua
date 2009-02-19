--[[
ChannelLock/ChannelLock-Config.lua

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

if not ChannelLock then return end


function ChannelLock:GetOptions()
	local options = {
		type = 'group',
		name = "ChannelLock",
		args = {
			channels = {
				name = 'Channels',
				type = 'group',
				args = {
				},
			},

			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
		}
	}

	for i = 1,10 do
		local argblock = {
			name = string.format("%d. %s", i, self.db.profile.channels[i].name or ""),
			desc = "Options for channel "..i,
			type = 'group',
			order = 10 + i,
			args = {
				channel = {
					type = 'input',
					name = 'Channel Name',
					desc = "The channel name for this slot",
					validate = function(info,val)
						val = strtrim(val)
						for j = 1,10 do
							if j ~= i and self.db.profile.channels[j].name == val then
								return "You can not set two slots to the same value. Please clear the other one first."
							end	
						end
						return true
					end,
					get = function() return self.db.profile.channels[i].name end,
					set = function(info, val) 
						val = strtrim(val)
						local index = tostring(i)
						if val == "" then 
							self.db.profile.channels[i].name = nil
							self.db.profile.channels[i].frameIndex = nil
							self.db.profile.channels[i].empty = true
						else
							self.db.profile.channels[i].empty = nil
						end

						self.db.profile.channels[i].name = val 
						self.options.args.channels.args[index].name = string.format("%d. %s", i, self.db.profile.channels[i].name or "")
					end,
				},
				chatFrame = {
					type = 'select',
					name = 'chatFrame',
					desc = "chat frame",
					values = {
						["ChatFrame1"] = "ChatFrame1",
						["ChatFrame2"] = "ChatFrame2",
						["ChatFrame3"] = "ChatFrame3",
						["ChatFrame4"] = "ChatFrame4",
						["ChatFrame5"] = "ChatFrame5",
						["ChatFrame6"] = "ChatFrame6",
						["ChatFrame7"] = "ChatFrame7",
						["ChatFrame8"] = "ChatFrame8",
						["ChatFrame9"] = "ChatFrame9",
						["ChatFrame10"] = "ChatFrame10",
					},
					get = function()  return "ChatFrame"..(self.db.profile.channels[i].frameIndex or 1) end,
					set = function(info,val) self.db.profile.channels[i].frameIndex = string.match(val, "ChatFrame(%d+)") end,
				}
			}
		}
		options.args.channels.args[tostring(i)] = argblock
	end

	local rescanButton = {
		type = "execute",
		name = "Apply Changes",
		order = 99,
		desc = "Rescans the current channels, applying any changes made here.",
		func = function() ChannelLock:CheckChannels() end,
	}
	options.args.channels.args["rescanButton"] = rescanButton

	return options
end

function ChannelLock:GetDefaults()
	local defaults = {
		profile = {
			channels = {
				[1] = { name = "General", frameIndex = 1 },
				[2] = { name = "Trade", frameIndex = 1 },
				[3] = { name = "LocalDefense", frameIndex = 1 },
				[4] = { name = "LookingForGroup", frameIndex = 1 },
				[5] = { name = nil, frameIndex = 1 },
				[6] = { name = nil, frameIndex = 1 },
				[7] = { name = nil, frameIndex = 1 },
				[8] = { name = nil, frameIndex = 1 },
				[9] = { name = nil, frameIndex = 1 },
				[10] = { name = nil, frameIndex = 1 },
			}
		}
	}

	return defaults
end

