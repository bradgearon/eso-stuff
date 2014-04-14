BankStuffer = {}

local STUFF_NAME = "Bank Stuffer"

local function stackItem(fromBag, fromSlot, toBag, toSlot, quantity, name)
    d("stacking")
    local result = true
    -- just in case
    ClearCursor()
    -- must call secure protected (pickup the item via cursor)
    result = CallSecureProtected("PickupInventoryItem", fromBag, fromSlot, quantity)
    d("called secure protected")
    if (result) then
        -- must call secure protected (drop the item on the cursor)
        result = CallSecureProtected("PlaceInInventory", toBag, toSlot)
    end
    -- clear the cursor to avoid issues
    ClearCursor()
    return result
end

local function insertItem(itemTable, bag, slot, stack)
    local item = {}
    item.bag = bag
    item.slot = slot
    item.stack = stack
    table.insert(itemTable, item)
end


local function moveItem(fromItem, toItem, maxStack, itemName)
    -- d(key .. inspect(item))
    -- the most we can move
    local quantity = math.min(maxStack - toItem.stack, fromItem.stack)
    -- if we can move any
    if (quantity > 0) then
        d(" moving " .. quantity .. " " .. itemName .. " from bag: " .. fromItem.bag .. " slot: " .. fromItem.slot .. " to bag: " .. toItem.bag .. " slot: " .. toItem.slot .. " with: " .. toItem.stack)
        -- move them
        result = stackItem(fromItem.bag, fromItem.slot, toItem.bag, toItem.slot, quantity, itemName)
        if (result) then
            fromItem.stack = fromItem.stack - quantity
            toItem.stack = toItem.stack + quantity
            d("moved " .. quantity .. " " .. itemName .. " from bag: " .. fromItem.bag .. " slot: " .. fromItem.slot .. " to bag: " .. toItem.bag .. " slot: " .. toItem.slot .. " with: " .. toItem.stack)
        end
    end
end

local function sortStack (first, second)
    return first.stack > second.stack
end

local function reverseStack (first, second)
    return first.stack < second.stack
end

local function loopItems(fromItems, toItems, maxStack, itemName)
    table.sort(toItems, sortStack)
    table.sort(fromItems, reverseStack)

    for fromIndex, fromItem in ipairs(fromItems) do
        if (fromItem.stack > 0 and fromItem.stack < maxStack) then
            for toIndex, toItem in ipairs(toItems) do
                if(toItem.stack > 0 and toItem.stack < maxStack) then
                    local sameBag = fromItem.bag == toItem.bag
                    local sameSlot = fromItem.slot == toItem.slot
                    if (not (sameBag and sameSlot)) then
                        moveItem(fromItem, toItem, maxStack, itemName)
                        table.sort(toItems, sortStack)
                        table.sort(fromItems, reverseStack)
                    end
                end
            end
        end
    end
end

local function moveItems(bags, fromBag, toBag)
    for itemName, bagItem in pairs(bags) do
        local fromItems = bagItem[fromBag]
        local toItems = bagItem[toBag]
        loopItems(fromItems, toItems, bagItem.maxStack, itemName)
    end
end


function BankStuffer.HandleOpenBank(eventCode, addOnName, isManual)
    local maxBags = GetMaxBags()
    local bags = {}

    if (not isManual) then
        ClearCursor()
    end

    for bag = 1, maxBags do
        bagIcon, bagSlots = GetBagInfo(bag)
        for slot = 1, bagSlots do
            stack, maxStack = GetSlotStackSize(bag, slot)
            itemName = GetItemName(bag, slot)

            if (stack > 0 and itemName ~= nil) then
                -- right now this only works with the bank
                -- will add support for ui based guild bank deposit / join
                bagItem = bags[itemName] or {}

                bagItem[BAG_BANK] = bagItem[BAG_BANK] or {}
                bagItem[BAG_BACKPACK] = bagItem[BAG_BACKPACK] or {}

                bagItem.maxStack = maxStack
                bagItem.name = itemName

                local itemTable = bagItem[bag]

                -- insert the slot item in the appropriate table
                insertItem(itemTable, bag, slot, stack)
                bags[itemName] = bagItem
            end
        end
    end

    if (not isManual) then
        -- consolidate source
        moveItems(bags, BAG_BACKPACK, BAG_BACKPACK)
        -- consolidate destination
        moveItems(bags, BAG_BANK, BAG_BANK)
        -- move to bank
        moveItems(bags, BAG_BACKPACK, BAG_BANK)
    end
end


function BankStuffer.HandleAddOnLoaded(eventCode, addOnName)
    d("loading " .. eventCode .. " " .. addOnName)
    if addOnName ~= STUFF_NAME then return
    end
    BankStuffer.Defaults = {}

    BankStuffer.Saved = ZO_SavedVars:New(STUFF_NAME, 5, nil, Stuff.Defaults, nil)

    if BankStuffer.Saved ~= nil then
    end

    d(STUFF_NAME .. " loaded")

    BankStuffer.HandleOpenBank(eventCode, addOnName, true)
end

d("testing")

EVENT_MANAGER:RegisterForEvent(STUFF_NAME, EVENT_OPEN_BANK, BankStuffer.HandleOpenBank)
EVENT_MANAGER:RegisterForEvent(STUFF_NAME, EVENT_ADD_ON_LOADED, BankStuffer.HandleAddOnLoaded)