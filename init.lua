------------------------------------------------------------------------
--Formspec restock button
------------------------------------------------------------------------
local fs_restocker_button = [[
button[3.75,0.1;1,1;refresh_button;]
image[3.75,0.1;1,1;vrestocker_refresh_button.png]

]]

local fs_restocker_button_off = [[
button[3.75,0.1;1,1;refresh_button;]
image[3.75,0.1;1,1;vrestocker_refresh_button.png]
image[3.75,0.1;1,1;mobs_mc_trading_formspec_disabled.png]

]]

------------------------------------------------------------------------
-- Copied Formspec values (Had to sorry...)
------------------------------------------------------------------------

local fs_header_template = [[
formspec_version[6]
size[15.2,9.3]
position[0.5,0.5]

label[7.5,0.3;%s]
style_type[label;textcolor=white]

background[6.3,0.55;5.9,0.2;mcl_inventory_bar.png]
background[6.3,0.55;%s,0.2;mcl_inventory_bar_fill.png]

scrollbaroptions[min=1;max=%i;thumbsize=1]
scrollbar[3.3,0.05;0.4,9.1;vertical;trade_scroller;1]
scroll_container[0.1,0.1;3.2,9.5;trade_scroller;vertical]

]]

local fs_header_no_bar_template = [[
formspec_version[6]
size[15.2,9.3]
position[0.5,0.5]

label[7.5,0.3;%s]
style_type[label;textcolor=white]

scrollbaroptions[min=1;max=%i;thumbsize=1]
scrollbar[3.3,0.05;0.4,9.1;vertical;trade_scroller;1]
scroll_container[0.1,0.1;3.2,9.5;trade_scroller;vertical]

]]

local fs_level_template = [[
style_type[label;textcolor=#323232]
label[0.1,%f2;%s]
style_type[label;textcolor=white]

]]

local fs_trade_start_template = [[
container[0.1,%f2]
	button[0.0,0.0;3.05,0.6;trade_%i;]

	item_image[0.02,0.03;0.5,0.5;%s]
	tooltip[0.1,0.0;0.5,0.5;%s]
	label[0.3,0.35;%s]

]]

local fs_trade_wants2_template = [[

	item_image[0.6,0.03;0.5,0.5;%s]
	tooltip[0.6,0.1;0.5,0.5;%s]
	label[0.8,0.35;%s]

]]

local fs_trade_pushed_template = [[
	style_type[button;border=false;bgimg=mcl_inventory_button9_pressed.png;bgimg_pressed=mcl_inventory_button9_pressed.png;bgimg_middle=2,2]

]]

local fs_trade_unpush_template = [[
	style_type[button;border=false;bgimg=mcl_inventory_button9.png;bgimg_pressed=mcl_inventory_button9_pressed.png;bgimg_middle=2,2]

]]

local fs_trade_arrow_template = [[
	image[1.8,0.15;0.5,0.32;gui_crafting_arrow.png]

]]

local fs_trade_disabled_template = [[
	image[1.8,0.15;0.5,0.32;mobs_mc_trading_formspec_disabled.png]

]]

local fs_trade_end_template = [[
	item_image[2.5,0.03;0.5,0.5;%s]
	tooltip[2.5,0.0;0.5,0.5;%s]
	label[2.8,0.35;%s]

container_end[]

]]

local fs_footer_template = [[

scroll_container_end[]

image[9.5,1.0;1.0,0.5;gui_crafting_arrow.png]
image[9.5,2.25;1.0,0.5;gui_crafting_arrow.png]

]] ..
mcl_formspec.get_itemslot_bg_v4(6.4,2.0,2,1)
..
mcl_formspec.get_itemslot_bg_v4(11.1,2.0,1,1)
..
mcl_formspec.get_itemslot_bg_v4(3.97,3.98,9,3)
..
mcl_formspec.get_itemslot_bg_v4(3.97,7.98,9,1)
 ..
[[

 list[current_player;main;3.97,3.98;9,3;9]
 list[current_player;main;3.97,7.98;9,1;]

]]

local fs_wants_template = [[

	item_image[6.4,0.75;1.0,1.0;%s]
	tooltip[6.4,0.75;1.0,1.0;%s]
	label[7.20,1.7;%s]

]]

local fs_wants2_template = [[

	item_image[7.6,0.75;1.0,1.0;%s]
	tooltip[7.6,0.75;1.0,1.0;%s]
	label[8.5,1.7;%s]

]]

local fs_offered_template = [[

	item_image[11.1,0.75;1.0,1.0;%s]
	tooltip[11.1,0.75;1.0,1.0;%s]
	label[11.95,1.7;%s]

]]

local fs_footer_template2 = [[

list[%s;input;6.4,2.0;2,1;]
list[%s;output;11.1,2.0;1,1;]
listring[%s;output]
listring[current_player;main]
listring[%s;input]
listring[current_player;main]
]]

local button_buffer = 0.65

local function count_string (count)
	if count == 1 then
		count = ""
	end
	return tostring (count)
end

------------------------------------------------------------------------
-- Copies Var and new trading_players
------------------------------------------------------------------------

local path = core.registered_entities["mobs_mc:villager"]
local is_valid = mcl_util.is_valid_objectref
local F = core.formspec_escape
local trading_players = {}

------------------------------------------------------------------------
-- New show_trade_formspec
------------------------------------------------------------------------

function path:show_trade_formspec (player, tradenum)
	local current = trading_players[player]
	if current and is_valid (current) and current ~= self.object then
		return false
	end

	if not self._trades then
		return false
	elseif not tradenum then
		tradenum = 0
	end

	local playername = player:get_player_name ()
	local trade_inv_name = "vrestocker:trade_" .. playername
	local formspec_name = F ("detached:" .. trade_inv_name)
	local inv = core.get_inventory ({
		type = "detached",
		name = trade_inv_name,
	})
	if not inv then
		return false
	end

	trading_players[player] = self

	local formspec = {
		false,
	}
	local best_tier = 0
	local h = 0.0
	local trade_str = {}
	local str

	local trades = self._trades
	for i, trade in ipairs (trades) do
		local wanted1 = trade:get_wanted1 ()
		local wanted2 = trade:get_wanted2 ()
		local offered = trade:get_offered ()

		if best_tier ~= trade.tier then
			best_tier = trade.tier

			h = h + 0.3
			local name = self:get_tier_name (best_tier)
			str = string.format (fs_level_template, h, name)
			table.insert (formspec, str)
			h = h + 0.2
		end

		if i == tradenum then
			table.insert (formspec, fs_trade_pushed_template)
			str = string.format (fs_wants_template, wanted1:get_name (),
                F (wanted1:get_description ()),
                count_string (wanted1:get_count ()))
			table.insert (trade_str, str)
			if not wanted2:is_empty () then
				str = string.format (fs_wants2_template, wanted2:get_name (),
                    F (wanted2:get_description ()),
                    count_string (wanted2:get_count ()))
				table.insert (trade_str, str)
			end
			str = string.format (fs_offered_template, offered:get_name (),
                F (offered:get_description ()),
                count_string (offered:get_count ()))
			table.insert (trade_str, str)
		end

		str = string.format (fs_trade_start_template, h, i,
            wanted1:get_name (),
            F (wanted1:get_description ()),
            count_string (wanted1:get_count ()))
		table.insert (formspec, str)

		if not wanted2:is_empty () then
			str = string.format (fs_trade_wants2_template,
                wanted2:get_name (),
                F (wanted2:get_description ()),
                count_string (wanted2:get_count ()))
			table.insert (formspec, str)
		end

		if trade:is_locked () then
			table.insert (formspec, fs_trade_disabled_template)
		else
			table.insert (formspec, fs_trade_arrow_template)
		end

		str = string.format (fs_trade_end_template,
            offered:get_name (),
            F (offered:get_description ()),
            count_string (offered:get_count ()))
		table.insert (formspec, str)

		if i == tradenum then
			table.insert (formspec, fs_trade_unpush_template)
		end
		h = h + button_buffer
	end

	local header
	local title = self:get_dialog_label ()
	local label = core.colorize ("#313131", title)
	if self:show_trade_progress_bar () then
		local progress = self:tier_progress ()
		header = string.format (fs_header_template,
					F (label), progress * 5.9,
					h * 10)
	else
		header = string.format (fs_header_no_bar_template,
					F (label), h * 10)
	end
	formspec[1] = header
	table.insert (formspec, fs_footer_template)
	if #trade_str > 0 then
		local tradestr = table.concat (trade_str)
		table.insert (formspec, tradestr)
		str = string.format (fs_footer_template2,
            formspec_name, formspec_name,
            formspec_name, formspec_name)
		table.insert (formspec, str)
	end

	if self._xp == 0 then
    	table.insert (formspec, fs_restocker_button)
	else
		table.insert (formspec, fs_trade_pushed_template)
		table.insert (formspec, fs_restocker_button_off)
		table.insert (formspec, fs_trade_unpush_template)
	end

	core.sound_play ("mobs_mc_villager_trade", {
		to_player = playername,
		object = self.object,
	}, true)
	str = table.concat (formspec)
	core.show_formspec (playername, "vrestocker:trading_formspec", str)
	trading_players[player] = self.object
	self._trading_with[player] = tradenum
	return true
end

------------------------------------------------------------------------
-- Local functions unobtainable and needed to be pasted in
------------------------------------------------------------------------

local function get_trading_inventory (player)
	local trade_inv_name = "vrestocker:trade_" .. player:get_player_name ()
	return core.get_inventory ({
		type = "detached",
		name = trade_inv_name,
	})
end

local function return_item (itemstack, dropper, pos, inv_p)
	if dropper:is_player () then
		-- Return to main inventory
		if inv_p:room_for_item ("main", itemstack) then
			inv_p:add_item ("main", itemstack)
		else
			-- Drop item on the ground
			local v = dropper:get_look_dir ()
			local p = {
				x = pos.x,
				y = pos.y + 1.2,
				z = pos.z,
			}
			p.x = p.x + (math.random (1,3) * 0.2)
			p.z = p.z + (math.random (1,3) * 0.2)
			local obj = core.add_item (p, itemstack)
			if obj then
				v.x = v.x * 4
				v.y = v.y * 4 + 2
				v.z = v.z * 4
				obj:set_velocity (v)
				obj:get_luaentity ()._insta_collect = false
			end
		end
	else
		-- Fallback for unexpected cases.
		core.add_item (pos, itemstack)
	end
	return itemstack
end

local function return_fields (player)
	local inv_t = get_trading_inventory (player)
	local inv_p = player:get_inventory ()
	if not inv_t or not inv_p then
		return
	end
	for i = 1, inv_t:get_size ("input") do
		local stack = inv_t:get_stack ("input", i)
		return_item (stack, player, player:get_pos (), inv_p)
		stack:clear ()
		inv_t:set_stack ("input", i, stack)
	end
	inv_t:set_stack ("output", 1, "")
end

------------------------------------------------------------------------
-- Reloading trades function below
------------------------------------------------------------------------

local pr = PcgRandom (os.time () - 472)

function path:reload_trades_inmenu (entity, player)
	return_fields(player)
	if not entity._profession or entity._profession == "nitwit" then
		entity:update_trades ({})
		return
	end

	local trades = mobs_mc.villager_trades[entity._profession]
	assert (trades)
	local villager_trades = {}
	for tier, trade_list in ipairs (trades) do
		if tier > entity._tier then
			break
		end

		for _, trade in ipairs (trade_list) do
			local trade_object
				= mobs_mc.trade_from_table (pr, trade, true)
			trade_object.tier = tier
			table.insert (villager_trades, trade_object)
		end
	end
	entity:update_trades (villager_trades)
end


------------------------------------------------------------------------
-- inv_class copied and pasted here.
------------------------------------------------------------------------

local inv_class = {}

function inv_class:allow_take (listname, index, stack, player)
	if listname == "input" then
		return stack:get_count ()
	elseif listname == "output" then
		-- Whom is this player trading with?
		local merchant = trading_players[player]
		if not merchant or not is_valid (merchant) then
			return 0
		end
		-- What is being bartered?
		local entity = merchant:get_luaentity ()
		local trade_id = entity._trading_with[player]
		if not trade_id or not entity._trades[trade_id] then
			return 0
		end

		-- Don't permit taking less than the entire offer.
		local count = stack:get_count ()
		local offer = self:get_stack ("output", index)
		if count ~= offer:get_count () then
			return 0
		end

		return entity:validate_transaction (self, player, trade_id)
	else
		return 0
	end
end

function inv_class:allow_move (from_list, from_index, to_list, to_index, count, player)
	return from_list == "input" and to_list == "input" and count or 0
end

function inv_class:allow_put (listname, _, stack, player)
	if listname == "input" then
		local merchant = trading_players[player]
		if not merchant or not is_valid (merchant) then
			return 0
		end
		-- Is there anything that is being bartered?
		local entity = merchant:get_luaentity ()
		local trade_id = entity._trading_with[player]
		if not trade_id or not entity._trades[trade_id] then
			return 0
		end
		return stack:get_count ()
	end

	return 0
end

function inv_class:on_put (listname, index, stack, player)
	local merchant = trading_players[player]
	if not merchant or not is_valid (merchant) then
		return
	end
	-- Is there anything that is being bartered?
	local entity = merchant:get_luaentity ()
	local trade_id = entity._trading_with[player]
	if not trade_id or not entity._trades[trade_id] then
		return
	end
	entity:update_offer (self, player, trade_id, true)
end

function inv_class:on_take (listname, index, stack, player)
	if listname == "input" or listname == "output" then
		local merchant = trading_players[player]
		if not merchant or not is_valid (merchant) then
			return
		end
		-- Is there anything that is being bartered?
		local entity = merchant:get_luaentity ()
		local trade_id = entity._trading_with[player]
		if not trade_id or not entity._trades[trade_id] then
			return
		end
		if listname == "output" then
			core.sound_play ("mobs_mc_villager_accept", {
				to_player = player:get_player_name (),
				object = self.object,
			}, true)
			entity:complete_transaction (self, player, trade_id)
			entity:update_offer (self, player, trade_id, false)
			entity:show_trade_formspec (player, trade_id)
		else
			entity:update_offer (self, player, trade_id, false)
			core.sound_play ("mobs_mc_villager_deny", {
				to_player = player:get_player_name (),
				object = self.object,
			}, true)
		end
		return
	end
end

------------------------------------------------------------------------
-- Activating fields
------------------------------------------------------------------------

core.register_on_player_receive_fields (function (player, formname, fields)
	if formname == "vrestocker:trading_formspec" then
		if fields.quit then
			return_fields (player)
			local trader = trading_players[player]
			if trader and is_valid (trader) then
				local entity = trader:get_luaentity ()
				entity._trading_with[player] = nil
				entity:trading_stopped (player)
			end
			trading_players[player] = nil
		else
			local trader = trading_players[player]
			if not trader or not is_valid (trader) then
				return
			end
			local entity = trader:get_luaentity ()
			local inv = get_trading_inventory (player)
			if not inv then
				return
			end

			if fields.refresh_button and entity._xp == 0 then
				entity:reload_trades_inmenu (entity, player)
				entity:show_trade_formspec (player, 0)
			end

			for i, _ in pairs (entity._trades) do
				if fields["trade_" .. i] then
					entity:set_trade (player, inv, i)
					entity:update_offer (inv, player, i, false)
					entity:show_trade_formspec (player, i)
					break
				end
			end
		end
	end
end)

core.register_on_joinplayer (function (player)
	local playername = player:get_player_name ()
	local inv_name = "vrestocker:trade_" .. playername
	local inv = core.get_inventory ({
		type = "detached",
		name = inv_name,
	})
	if not inv then
		inv = core.create_detached_inventory (inv_name, inv_class,
							  playername)
	end
	inv:set_size ("input", 2)
	inv:set_size ("output", 1)
	inv:set_size ("wanted", 2)
	inv:set_size ("offered", 1)
end)

core.register_on_leaveplayer (function (player)
	local trading = trading_players[player]
	if trading and is_valid (trading) then
		local entity = trading:get_luaentity ()
		entity._trading_with[player] = nil
		mobs_mc.return_trading_fields(player)
		entity:trading_stopped (player)
	end
	trading_players[player] = nil
end)
