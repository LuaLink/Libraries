---@class PaginatedGui : Gui
---@field private paginatedItems any[]
---@field private currentPage integer
---@field private itemsPerPage integer
local PaginatedGui = {}
PaginatedGui.__index = PaginatedGui
setmetatable(PaginatedGui, { __index = require("gui.gui") }) -- Inherit from Gui

local Material = java.import("org.bukkit.Material")
local ItemStack = java.import("org.bukkit.inventory.ItemStack")
local MiniMessage = java.import("net.kyori.adventure.text.minimessage.MiniMessage")

---@param title string
---@param size integer
---@return PaginatedGui
function PaginatedGui.new(title, size)
    local self = setmetatable(require("gui.gui").new(title, size), PaginatedGui)
    self.paginatedItems = {}
    self.currentPage = 1
    self.itemsPerPage = (size * 9) - 9 -- Reserve bottom row for navigation
    return self
end

---@param items any[]
---@param handler fun(event: org.bukkit.event.inventory.InventoryClickEvent, item: any)
function PaginatedGui:setPaginatedItems(items, handler)
    self.paginatedItems = items
    self.itemClickHandler = handler
    self:updatePage()
end

function PaginatedGui:updatePage()
    local start = (self.currentPage - 1) * self.itemsPerPage + 1
    local stop = math.min(#self.paginatedItems, start + self.itemsPerPage - 1)

    -- Clear all GUI slots
    for i = 0, self.size * 9 - 1 do
        self.inventory:setItem(i, nil)
    end

    -- Display items
    local index = 0
    for i = start, stop do
        local item = self.paginatedItems[i]
        self:setItem(index, item, function(event)
            self.itemClickHandler(event, item)
        end)
        index = index + 1
    end

    -- Add back the static items
    for slot, item in pairs(self.items) do
        self.inventory:setItem(slot, item.item)
    end

    -- Add back the filler items
    if self.fillerItem then
        for i = 0, self.size * 9 - 1 do
            if self.inventory:getItem(i) == nil then
                self.inventory:setItem(i, self.fillerItem)
            end
        end
    end
end

function PaginatedGui:nextPage()
    local maxPage = math.ceil(#self.paginatedItems / self.itemsPerPage)
    if self.currentPage < maxPage then
        self.currentPage = self.currentPage + 1
        self:updatePage()
    end
end

function PaginatedGui:previousPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:updatePage()
    end
end

function PaginatedGui:getPage()
    return self.currentPage
end

function PaginatedGui:getMaxPage()
    return math.ceil(#self.paginatedItems / self.itemsPerPage)
end

return PaginatedGui
