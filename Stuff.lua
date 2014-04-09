Stuff = {}
Stuff.def = {}

local STUFF_NAME = "Stuff"

function stackItem(fromBag, fromSlot, toBag, toSlot, quantity, name)
    local result = true
    -- just in case
    ClearCursor()
    -- must call secure protected (pickup the item via cursor)
    result = CallSecureProtected("PickupInventoryItem", fromBag, fromSlot, quantity)
    if (result) then
        -- must call secure protected (drop the item on the cursor)
        result = CallSecureProtected("PlaceInInventory", toBag, toSlot)
    end
    -- clear the cursor to avoid issues
    ClearCursor()
    return result
end


function insertItem(itemTable, bag, slot, stack)
    local item = {}
    item.bag = bag
    item.slot = slot
    item.stack = stack
    table.insert(itemTable, item)
end

function HandleOpenBank(eventCode, addOnName, isManual)
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
                -- right now this only works with the bank (will add support for ui based
                -- guild bank deposit / join
                local isBank = BAG_BANK == bag
                bagItem = bags[itemName] or {}
                bagItem.bank = bagItem.bank or {}
                bagItem.item = bagItem.item or {}

                bagItem.maxStack = maxStack
                bagItem.name = itemName

                local itemTable = isBank and bagItem.bank or bagItem.item

                -- insert the slot item in the appropriate table
                insertItem(itemTable, bag, slot, stack)

                bags[itemName] = bagItem

                if (not isManual and isBank) then
                    for key, item in pairs(bagItem.item) do
                        -- the most we can move
                        local quantity = math.min(maxStack - stack, item.stack)
                        -- if we can move any
                        if (quantity > 0) then
                            d("moving " .. quantity .. " " .. itemName .. " to bagId: " .. bag)
                            -- move them
                            result = stackItem(item.bag, item.slot, bag, slot, quantity, itemName)
                            if(result) then
                                item.stack = item.stack - quantity
                                d("moved " .. quantity .. " " .. itemName .. " to bagId: " .. bag)
                            end
                        end
                    end
                end
            end
        end
    end
end

function HandleAddOnLoaded(eventCode, addOnName)
    if addOnName ~= STUFF_NAME then return end
    Stuff.Defaults = {}

    Stuff.Saved = ZO_SavedVars:New(STUFF_NAME, 5, nil, Stuff.Defaults, nil)

    if Stuff.Saved ~= nil then
    end

    d(STUFF_NAME .. " loaded")

    HandleOpenBank(eventCode, addOnName, true)
end

EVENT_MANAGER:RegisterForEvent(STUFF_NAME, EVENT_OPEN_BANK, HandleOpenBank)
EVENT_MANAGER:RegisterForEvent(STUFF_NAME, EVENT_ADD_ON_LOADED, HandleAddOnLoaded)