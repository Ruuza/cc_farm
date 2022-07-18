CONFIG = {
    base_x = 0,
    base_y = 0,
    base_z = 0,
    lenght = 10,
    slotsSaplingsReserve = 1,
    compass_slot = 1,
    tool_name = "minecraft:diamond_axe",
    sapling_name = "minecraft:oak_sapling",
    cropChestName = "minecraft:chest",
    fuelChestName = "minecraft:chest",
    GAIN_PER_FUEL = 80,
}

turtle = turtle

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
    local success, data = turtle.inspectUp()

    if success then
        if data.name == CONFIG.fuelChestName then
            return true
        end
    end

    return false
end

function TakeFuelFromChest()
    local fuelInSlot = turtle.getItemCount(2)
    local fuelToTake = 64 - fuelInSlot
    local result = turtle.suckUp(fuelToTake)

    if not result then
        error("TakeFuel unsuccessful - probably MISSING FUEL in FuelChest")
    end
end

function FuelToLimit()
    -- Fuel to max limit or to keep atleast one fuel in inventory slot
    local missingFuel = turtle.getFuelLimit() / 10 - turtle.getFuelLevel()
    local fuelInSlotAvailable = turtle.getItemCount(2)

    local fuelToConsume = math.floor(missingFuel / CONFIG.GAIN_PER_FUEL)

    local result = false

    if fuelToConsume >= fuelInSlotAvailable then
        result = turtle.refuel(fuelInSlotAvailable - 1)

    else
        result = turtle.refuel(fuelToConsume)
    end

    if turtle.getFuelLevel() > (turtle.getFuelLimit() / 10 + 1) then
        error("ERROR: Fuel level is greater than set limit")
    end

    if not result then
        error("Refueling wasn't successful")
    end
end

function Refuel()
    turtle.select(2)

    local result = IsFuelChest()

    if not result then
        error("Fuel chest not detected")
    end

    TakeFuelFromChest()

    FuelToLimit()

    TakeFuelFromChest()

end

function TransferInventory()
    -- Transfer all slots, except the first and reserved for seeds ones, into the crop chest, if there is any
    -- Returns error when no crop chest is ready

    local canDrop = IsCropChest()

    if not canDrop then
        error("ERROR: There is no crop chest bellow me")
    end

    local startSlot = 3 + CONFIG.slotsSaplingsReserve

    for slot = startSlot, 16 do
        turtle.select(slot)
        turtle.dropDown()
    end

    turtle.select(1)
end

function GetPosition()
    return gps.locate()
end

function GetFacingDirection()
    turtle.select(CONFIG.compass_slot)
    local item = turtle.getItemDetail()

    if item.name ~= "minecraft:compass" then
        error("Error: Compass not detected!")
    end

    turtle.equipRight()
    local compass = peripheral.find("compass")
    local direction = compass.getFacing()
    turtle.equipRight()
    return direction
end

function EnsureToolEquipped()
    turtle.select(CONFIG.compass_slot)
    local item = turtle.getItemDetail()

    if item.name == CONFIG.tool_name then
        turtle.equipRight()
        return
    end
end

function SetDirection(newdir)
    local currentdir = GetFacingDirection()
    local directions = {}
    directions["north"] = 1
    directions["east"] = 2
    directions["south"] = 3
    directions["west"] = 4

    while directions[newdir] ~= directions[currentdir] do
        if directions[currentdir] == 1 and directions[newdir] == 4 then
            turtle.turnLeft()

        elseif directions[currentdir] == 4 and directions[newdir] == 1 then
            turtle.turnRight()

        elseif directions[currentdir] > directions[newdir] then
            turtle.turnLeft()

        elseif directions[currentdir] < directions[newdir] then
            turtle.turnRight()
        end
        currentdir = GetFacingDirection()
    end
end

function GetFrontDirection(x)
    if x == CONFIG.base_x or x == CONFIG.base_x + 6 then
        return "south"
    end

    if x == CONFIG.base_x + 3 or x == CONFIG.base_x + 9 then
        return "north"
    end

    error("Illegal position state (function: GetFrontDirection())")
end

function ReplaceSapling(sapling_name)
    -- scans inventory for seeds. If it finds it, it places the seed
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            if item.name == sapling_name then
                turtle.place()
                break
            end
        end
    end
    turtle.select(1)
end

function DestroyLeavesInFront()
    local success, data = turtle.inspect()
    if success then
        if data.name == "minecraft:oak_leaves" then
            turtle.dig()
        else
            error("Illegal block in front")
        end
    end
end

function AfterPlantHandle()
    local facingdirect = GetFacingDirection()
    if facingdirect == "east" then
        SetDirection("west")
        HandlePlant()
    elseif facingdirect == "west" then
        local x, y, z = GetPosition()
        local frontdir = GetFrontDirection(x)
        SetDirection(frontdir)
        DestroyLeavesInFront()
        turtle.forward()
    else
        error("Illegal position state (function: AfterPlantHandle())")
    end
end

function HandlePlant()
    turtle.suck()

    local success, data = turtle.inspect()

    if ~success then
        ReplaceSapling(CONFIG.sapling_name)
    elseif data.name == "minecraft:oak_log" then
        turtle.digUp()
        turtle.up()
        return
    end

    AfterPlantHandle()

end

function MoveInDirection(direction)
    SetDirection(direction)
    DestroyLeavesInFront()
    turtle.suck()
    turtle.forward()
end

while true do

    EnsureToolEquipped()

    local x, y, z = GetPosition()
    local direction = GetFacingDirection()

    if x == CONFIG.base_x and z == CONFIG.base_z then
        TransferInventory()
        Refuel()
        SetDirection("south")
        turtle.suck()
        turtle.forward()

        -- Turtle in the air
    elseif y > CONFIG.base_y then
        -- Turtle not on top of the tree. Go up
        if y < CONFIG.base_y + 6 then
            turtle.digUp()
            turtle.up()
            -- Turtle on top of the tree, now break all the logs
        elseif y == CONFIG.base_y + 6 then
            while y <= CONFIG.base_y do
                turtle.dig()
                turtle.digDown()
                turtle.down()
                x, y, z = GetPosition()
            end
            HandlePlant()
        end

        -- In the tree base section
    elseif z > CONFIG.base_z and z < CONFIG.base_z + CONFIG.lenght - 1 then
        SetDirection("east")
        HandlePlant()

    elseif z == CONFIG.base_z and (direction == "west" or x == CONFIG.base_x + 9) then
        MoveInDirection("west")

    elseif (z == CONFIG.base_z and x == CONFIG.base_x + 3) or
        (z == CONFIG.base_z + CONFIG.lenght - 1 and (x == CONFIG.base_x or x == CONFIG.base_x + 6))
    then
        MoveInDirection("east")

    elseif z == CONFIG.base_z + CONFIG.lenght - 1 and (x == CONFIG.base_x + 3 or x == CONFIG.base_x + 9) then
        MoveInDirection("north")

    elseif z == CONFIG.base_z and x == CONFIG.base_x + 6 then
        MoveInDirection("south")

    elseif z == CONFIG.base_z or z == CONFIG.base_z + CONFIG.lenght then
        DestroyLeavesInFront()
        turtle.suck()
        turtle.forward()

    else
        error("Illegal state (function: main)")

    end


end
