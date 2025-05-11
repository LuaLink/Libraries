---@class Gui
---@field title string
---@field size integer
---@field items table<integer, { item: org.bukkit.inventory.ItemStack, slot: integer, handler: fun(event: org.bukkit.event.inventory.InventoryClickEvent)? }>
---@field inventory org.bukkit.inventory.Inventory
---@field preventMove boolean
---@field onCloseHandler? fun(player: org.bukkit.entity.Player)
---@field preClickPredicate? fun(event: org.bukkit.event.inventory.InventoryClickEvent): boolean
---@field fillerItem? org.bukkit.inventory.ItemStack
---@field private _holderTable table
---@field private holder org.bukkit.inventory.InventoryHolder
local Gui = {}
Gui.__index = Gui

local Bukkit = java.import("org.bukkit.Bukkit")
local MiniMessage = java.import("net.kyori.adventure.text.minimessage.MiniMessage")
local MM = MiniMessage:miniMessage()
local ArrayList = java.import("java.util.ArrayList")

---@type table<table, Gui> -- Weak key map: Lua holder table → Gui instance
local holderToGui = setmetatable({}, { __mode = "k" })

---Create a new GUI
---@param title string
---@param size integer
---@return Gui
function Gui.new(title, size)
    local self = setmetatable({}, Gui)
    self.title = title
    self.size = size
    self.items = {}
    self.preventMove = false

    -- Create Lua backing table for proxy
    self._holderTable = {}

    function self._holderTable:getInventory()
        return self.inventory
    end

    self.holder = java.proxy("org.bukkit.inventory.InventoryHolder", self._holderTable)
    holderToGui[self._holderTable] = self

    self.inventory = Bukkit:createInventory(self.holder, size * 9, title)

    return self
end

---@return org.bukkit.inventory.Inventory
function Gui:getInventory()
    return self.inventory
end

---@return org.bukkit.inventory.InventoryHolder
function Gui:getHolder()
    return self.holder
end

---@param slot integer
---@param item org.bukkit.inventory.ItemStack
---@param handler fun(event: org.bukkit.event.inventory.InventoryClickEvent)?
function Gui:setItem(slot, item, handler)
    self.items[slot] = { item = item, slot = slot, handler = handler }
    self.inventory:setItem(slot, item)
end

---@param item org.bukkit.inventory.ItemStack
function Gui:setFiller(item)
    for i = 0, self.size * 9 - 1 do
        if self.inventory:getItem(i) == nil then
            self.inventory:setItem(i, item)
        end
    end
    self.fillerItem = item
end

---@param slot integer
---@param item org.bukkit.inventory.ItemStack
---@param options string[]
---@param defaultIndex integer?
---@param onChange fun(event: org.bukkit.event.inventory.InventoryClickEvent, selected: string, index: integer)?
function Gui:addListItem(slot, item, options, defaultIndex, onChange)
    assert(#options > 0, "Options list cannot be empty")

    local index = defaultIndex or 1

    local originalMeta = item:getItemMeta()
    local baseLore
    if originalMeta:hasLore() then
        baseLore = originalMeta:lore()
    else
        baseLore = ArrayList()
    end

    ---@param currentIndex integer
    local function buildLore(currentIndex)
        local newLore = ArrayList()

        -- Add original lore first
        for i = 0, baseLore:size() - 1 do
            newLore:add(baseLore:get(i))
        end

        newLore:add(MM:deserialize("<gray><italic>Selection:"))

        local maxVisible = 5
        local startIdx = 1

        if #options > maxVisible then
            startIdx = math.max(1, math.min(currentIndex - 2, #options - maxVisible + 1))
        end

        for i = startIdx, math.min(#options, startIdx + maxVisible - 1) do
            if i == currentIndex then
                newLore:add(MM:deserialize("<bold><green>➤ " .. options[i]))
            else
                newLore:add(MM:deserialize("<gray>  " .. options[i]))
            end
        end

        return newLore
    end

    local function updateItem()
        local meta = item:getItemMeta()
        meta:lore(buildLore(index))
        item:setItemMeta(meta)
        self.inventory:setItem(slot, item) -- force GUI update
    end

    updateItem()

    self:setItem(slot, item, function(event)
        index = index + 1
        if index > #options then index = 1 end

        updateItem()

        if onChange then
            onChange(event, options[index], index)
        end
    end)
end

--- Add a simple toggle (enabled/disabled) item to the GUI
---@param slot integer
---@param item org.bukkit.inventory.ItemStack
---@param defaultState boolean? -- true = Enabled, false = Disabled
---@param onToggle fun(event: org.bukkit.event.inventory.InventoryClickEvent, enabled: boolean)?
function Gui:addToggle(slot, item, defaultState, onToggle)
    local options = { "Disabled", "Enabled" }
    local defaultIndex = defaultState and 2 or 1

    self:addListItem(slot, item, options, defaultIndex, function(event, selected, index)
        if onToggle then
            onToggle(event, selected == "Enabled")
        end
    end)
end

---@param value boolean
function Gui:preventItemMovement(value)
    self.preventMove = value
end

---@param predicate fun(event: org.bukkit.event.inventory.InventoryClickEvent): boolean
function Gui:setPreClickPredicate(predicate)
    self.preClickPredicate = predicate
end

---@param player org.bukkit.entity.Player
function Gui:open(player)
    player:openInventory(self.inventory)
end

---@param handler fun(player: org.bukkit.entity.Player)
function Gui:onClose(handler)
    self.onCloseHandler = handler
end

-- Event handlers

---@param event org.bukkit.event.inventory.InventoryClickEvent
local function onInventoryClick(event)
    local inventory = event:getInventory()
    local rawHolder = inventory:getHolder()
    local holderTable = java.unwrap(rawHolder)
    ---@type Gui
    local gui = holderToGui[holderTable]
    if not gui then return end

    if gui.preventMove then
        event:setCancelled(true)
    end

    if gui.preClickPredicate and not gui.preClickPredicate(event) then
        return
    end

    local slot = event:getRawSlot()
    local itemData = gui.items[slot]
    if itemData and itemData.handler then
        itemData.handler(event)
    end
end

---@param event org.bukkit.event.inventory.InventoryDragEvent
local function onInventoryDrag(event)
    local inventory = event:getInventory()
    local rawHolder = inventory:getHolder()
    local holderTable = java.unwrap(rawHolder)
    ---@type Gui
    local gui = holderToGui[holderTable]
    if gui and gui.preventMove then
        event:setCancelled(true)
    end
end

---@param event org.bukkit.event.inventory.InventoryCloseEvent
local function onInventoryClose(event)
    local inventory = event:getInventory()
    local rawHolder = inventory:getHolder()
    local holderTable = java.unwrap(rawHolder)
    ---@type Gui
    local gui = holderToGui[holderTable]
    if gui and gui.onCloseHandler then
        gui.onCloseHandler(event:getPlayer())
    end
end

script:registerListener("org.bukkit.event.inventory.InventoryClickEvent", onInventoryClick)
script:registerListener("org.bukkit.event.inventory.InventoryDragEvent", onInventoryDrag)
script:registerListener("org.bukkit.event.inventory.InventoryCloseEvent", onInventoryClose)

return Gui
