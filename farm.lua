CONFIG = {
    lenght = 9,
    width = 12,
    slotsSeedsReserve = 1,
    seed_name = "minecraft:wheat_seeds",
    cropChestName = "ironchests:copper_chest",
    fuelChestName = "minecraft:chest",
    MAX_FUEL = 64,
    GAIN_PER_FUEL = 80,
}

turtle = turtle

function ReplaceCrop(cropname)
    -- scans inventory for seeds if it finds it it places the seed
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            if item.name == cropname then
                turtle.placeDown()
                break
            end
        end
    end
    turtle.select(1)
end

function IsCropChest()
    local success, data = turtle.inspectDown()

    if success then
        if data.name == CONFIG.cropChestName then
            return true
        end
    end

    return false
end

function IsFuelChest()
    local success, data = turtle.inspect()

    if success then
        if data.name == CONFIG.fuelChestName then
            return true
        end
    end

    return false
end

function TakeFuelFromChest()
    local fuelInSlot = turtle.getItemCount(1)
    local fuelToTake = CONFIG.MAX_FUEL - fuelInSlot
    local result = turtle.suck(fuelToTake)

    if not result then
        error("TakeFuel unsuccessful - probably MISSING FUEL in FuelChest")
    end
end

function FuelToLimit()
    -- Fuel to max limit or to keep atleast one fuel in inventory slot
    local missingFuel = turtle.getFuelLimit() - turtle.getFuelLevel()
    local fuelInSlotAvailable = turtle.getItemCount(1)

    local fuelToConsume = math.floor(missingFuel / CONFIG.GAIN_PER_FUEL)

    local result = false

    if fuelToConsume >= fuelInSlotAvailable then
        result = turtle.refuel(fuelInSlotAvailable - 1)

    else
        result = turtle.refuel(fuelToConsume)
    end

    if not result then
        error("Refueling wasn't successful")
    end
end

function Refuel()
    turtle.select(1)

    turtle.turnRight()
    turtle.turnRight()

    local result = IsFuelChest()

    if not result then
        error("Fuel chest not detected")
    end

    TakeFuelFromChest()

    FuelToLimit()

    TakeFuelFromChest()

    turtle.turnRight()
    turtle.turnRight()

end

function TransferInventory()
    -- Transfer all slots, except the first and reserved for seeds ones, into the crop chest, if there is any
    -- Returns error when no crop chest is ready

    local canDrop = IsCropChest()

    if not canDrop then
        error("ERROR: There is no crop chest bellow me")
    end

    local startSlot = 2 + CONFIG.slotsSeedsReserve

    for slot = startSlot, 16 do
        turtle.select(slot)
        turtle.dropDown()
    end

    turtle.select(1)
end

function CheckCrop(cropName)

    local success, item = turtle.inspectDown()

    if success then

        -- If grown or if it is Immersive Weathering weed, remove it
        if item.state.age == 7 or item.name == "immersive_weathering:weeds" then
            turtle.digDown()
            ReplaceCrop(cropName)
        end


    else
        ReplaceCrop(cropName)
    end
end

while true do

    TransferInventory()
    Refuel()
    -- Move turtle on the field
    turtle.forward()

    for i = 1, CONFIG.width do


        for j = 1, CONFIG.lenght do

            CheckCrop(CONFIG.seed_name)
            turtle.forward()

        end

        if i < CONFIG.width then
            if i % 2 == 0 then
                turtle.turnRight()
                turtle.forward()
                turtle.turnRight()
                turtle.forward()
            else
                turtle.turnLeft()
                turtle.forward()
                turtle.turnLeft()
                turtle.forward()
            end
        end

    end

    -- On the opossite side, return back
    if CONFIG.width % 2 > 0 then
        turtle.turnLeft()
        turtle.turnLeft()
        for i = 1, CONFIG.lenght do
            turtle.forward()
        end
    end

    turtle.turnLeft()
    for i = 1, CONFIG.width - 1 do
        turtle.forward()
    end

    turtle.turnLeft()

    os.sleep(20)

end
