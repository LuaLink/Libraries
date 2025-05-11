# GUI
A simple easy-to-use GUI library made in pure Lua.

# Docs
TODO - Just read the script and the LuaLS annotations/docs for now or look at the example script

# Features
* Basic Chest GUI
* Basic Items with callbacks (buttons)
* List Items
* Toggle Item
* Paginated GUIs
* Filler Items
* Preclick Predicate
* Uses custom [InventoryHolder's](https://docs.papermc.io/paper/dev/custom-inventory-holder/)

# Example script
<details>
  <summary>Demo Video</summary>

https://github.com/user-attachments/assets/582eebc3-92c7-451e-bd82-5265a0d0d7c4
</details>

```lua
--- Test GUI combining all features

---@type Gui
local GUI = require("gui.gui")
---@type PaginatedGui
local PaginatedGui = require("gui.paginated_gui")

local Material = java.import("org.bukkit.Material")
local ItemStack = java.import("org.bukkit.inventory.ItemStack")
local MiniMessage = java.import("net.kyori.adventure.text.minimessage.MiniMessage")
local ArrayList = java.import("java.util.ArrayList")

local mm = MiniMessage:miniMessage()

---@param material org.bukkit.Material
---@param display string
---@return org.bukkit.inventory.ItemStack
local function namedItem(material, display)
    local item = ItemStack:of(material, 1)
    local meta = item:getItemMeta()
    meta:displayName(mm:deserialize(display))
    item:setItemMeta(meta)
    return item
end

local function createFiller()
    return namedItem(Material.GRAY_STAINED_GLASS_PANE, "<gray>Filler")
end

---@param player org.bukkit.entity.Player
local function openCombinedTestGUI(player)
    local gui = GUI.new("Test GUI", 3)

    gui:setItem(10, namedItem(Material.DIAMOND, "<blue>Click Me"), function(event)
        player:sendRichMessage("<blue>You clicked the diamond!")
    end)

    gui:setItem(12, namedItem(Material.GOLD_INGOT, "<yellow>Paginated Menu"), function(event)
        local paginated = PaginatedGui.new("Paginated Example", 5)
        local items = {}
        for _, material in ipairs(java.luaify(Material:values())) do
            if not material:isItem() then goto continue end
            table.insert(items, ItemStack:of(material, 1))
            ::continue::
        end
        paginated:setPaginatedItems(items, function(ev, item)
            ev:getWhoClicked():sendRichMessage("<green>You clicked: <white>" .. item:getType():name())
        end)
        paginated:setItem(40, namedItem(Material.BARRIER, "<red>Back"), function()
            openCombinedTestGUI(player)
        end)

        paginated:setItem(36, namedItem(Material.ARROW, "<yellow><< Prev"), function()
            paginated:previousPage()
        end)
        paginated:setItem(44, namedItem(Material.ARROW, "<yellow>Next >>"), function()
            paginated:nextPage()
        end)      
          
        paginated:setFiller(createFiller())
        paginated:preventItemMovement(true)
        paginated:open(player)
    end)

    gui:setItem(14, namedItem(Material.GLOWSTONE_DUST, "<light_purple>Color Picker"), function(event)
        local colorGui = GUI.new("Pick a Color", 3)
        local wool = ItemStack:of(Material.WHITE_WOOL, 1)
        local meta = wool:getItemMeta()
        meta:displayName(mm:deserialize("<yellow>Favorite Color"))
        wool:setItemMeta(meta)

        local colorOptions = { "Red", "Green", "Blue", "Yellow", "Purple", "Orange", "Black", "White" }

        colorGui:addListItem(13, wool, colorOptions, 1, function(_, selected)
            player:sendRichMessage("<aqua>You picked <bold>" .. selected .. "</bold>!")
        end)

        colorGui:setItem(22, namedItem(Material.BARRIER, "<red>Back"), function()
            openCombinedTestGUI(player)
        end)
        colorGui:setFiller(createFiller())
        colorGui:preventItemMovement(true)
        colorGui:open(player)
    end)

    gui:setItem(16, namedItem(Material.REDSTONE_TORCH, "<yellow>Toggle Feature"), function(event)
        local toggleGui = GUI.new("Toggle Example", 3)
        local toggleItem = ItemStack:of(Material.REDSTONE_TORCH, 1)
        local toggleMeta = toggleItem:getItemMeta()
        toggleMeta:displayName(mm:deserialize("<yellow>Toggle Feature"))
        local lore = ArrayList()
        lore:add(mm:deserialize("<gray>Click to enable or disable"))
        toggleMeta:lore(lore)
        toggleItem:setItemMeta(toggleMeta)

        toggleGui:addToggle(13, toggleItem, false, function(ev, enabled)
            ev:getWhoClicked():sendRichMessage(enabled and "<green>Feature Enabled!" or "<red>Feature Disabled!")
        end)

        toggleGui:setItem(22, namedItem(Material.BARRIER, "<red>Back"), function()
            openCombinedTestGUI(player)
        end)
        toggleGui:setFiller(createFiller())
        toggleGui:preventItemMovement(true)
        toggleGui:open(player)
    end)

    gui:setItem(4, namedItem(Material.BARRIER, "<red>Blocked Submenu"), function (event)
        local blockedGui = GUI.new("Blocked Click Submenu", 3)

        -- Predicate function to block every other click
        local clickCount = 0
        blockedGui:setPreClickPredicate(function(event)
            clickCount = clickCount + 1
            -- Block every other click
            if clickCount % 2 == 0 then
                -- Send player a message that the click was blocked
                event:getWhoClicked():sendRichMessage("<red>Your click was blocked!")
                event:setCancelled(true)  -- Cancel the click
                return false  -- Block the handler from being called
            end
            return true  -- Allow the click to proceed
        end)
    
        -- Adding items to the menu
        blockedGui:setItem(10, namedItem(Material.DIAMOND, "<blue>Click Me"), function(event)
            player:sendRichMessage("<blue>You clicked the diamond!")
        end)
    
        blockedGui:setItem(12, namedItem(Material.EMERALD, "<green>Click Me"), function(event)
            player:sendRichMessage("<green>You clicked the emerald!")
        end)
    
        blockedGui:setItem(14, namedItem(Material.REDSTONE_TORCH, "<red>Click Me"), function(event)
            player:sendRichMessage("<red>You clicked the redstone torch!")
        end)
    
        blockedGui:setItem(22, namedItem(Material.BARRIER, "<red>Back"), function()
            openCombinedTestGUI(player)
        end)
    
        blockedGui:setFiller(namedItem(Material.GRAY_STAINED_GLASS_PANE, "<gray>Filler"))
        blockedGui:preventItemMovement(true)
        blockedGui:open(player)
    end)

    gui:setItem(22, namedItem(Material.EMERALD, "<green>Open Submenu"), function(event)
        local function openSecond()
            local g = GUI.new("Second Submenu", 3)
            g:setItem(22, namedItem(Material.BARRIER, "<red>Back"), function() openFirst() end)
            g:setFiller(createFiller())
            g:preventItemMovement(true)
            g:open(player)
        end

        function openFirst()
            local g = GUI.new("First Submenu", 3)
            g:setItem(13, namedItem(Material.GOLD_INGOT, "<yellow>Go Deeper"), function() openSecond() end)
            g:setItem(22, namedItem(Material.BARRIER, "<red>Back"), function() openCombinedTestGUI(player) end)
            g:setFiller(createFiller())
            g:preventItemMovement(true)
            g:open(player)
        end

        openFirst()
    end)

    gui:setFiller(createFiller())
    gui:preventItemMovement(true)
    gui:open(player)
end

script:registerCommand(function(sender, args)
    ---@cast sender org.bukkit.entity.Player
    openCombinedTestGUI(sender)
end, {
    name = "testgui"
})
```
