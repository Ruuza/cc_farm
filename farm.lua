CONFIG = {
    lenght = 16,
    width = 16,
    base_x = 0,
    base_z = 0,
    slotsSeedsReserve = 1,
    compass_slot = 1,
    tool_name = "minecraft:diamond_hoe",
    seed_name = "minecraft:carrot",
    cropChestName = "minecraft:chest",
    fuelChestName = "minecraft:chest",
    GAIN_PER_FUEL = 80,
}

function ReplaceCrop(cropname)
    -- scans inventory for seeds. If it finds it, it places the seed
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
    local missingFuel = turtle.getFuelLimit() / 2 - turtle.getFuelLevel()
    local fuelInSlotAvailable = turtle.getItemCount(2)

    local fuelToConsume = math.floor(missingFuel / CONFIG.GAIN_PER_FUEL)

    local result = false

    if fuelToConsume >= fuelInSlotAvailable then
        result = turtle.refuel(fuelInSlotAvailable - 1)

    else
        result = turtle.refuel(fuelToConsume)
    end

    if turtle.getFuelLevel() > (turtle.getFuelLimit() / 2 + 1) then
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

    local startSlot = 3 + CONFIG.slotsSeedsReserve

    for slot = startSlot, 16 do
        turtle.select(slot)
        turtle.dropDown()
    end

    turtle.select(1)
end

function CheckCrop(cropName)

    local success, item = turtle.inspectDown()

    if success then

        -- If grown
        if item.state.age == 7 then
            turtle.digDown()
            ReplaceCrop(cropName)
        end


    else
        ReplaceCrop(cropName)
    end
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

    turtle.equipRight()

    if item.name == CONFIG.tool_name then
        turtle.equipRight()
        return
    end

    error("Error: No " + CONFIG.tool_name + "detected!")
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
        end
        if directions[currentdir] == 4 and directions[newdir] == 1 then
            turtle.turnRight()
        end
        if directions[currentdir] > directions[newdir] then
            turtle.turnLeft()
        end
        if directions[currentdir] < directions[newdir] then
            turtle.turnRight()
        end
    end
end

if CONFIG.width % 2 ~= 0 then
    error("Width of the field has to be even number!")
end

while true do

    EnsureToolEquipped()

    local x, y, z = GetPosition()
    local direction = GetFacingDirection()

    if x < CONFIG.base_x or x > (CONFIG.base_x + CONFIG.lenght) or z < CONFIG.base_z or
        z > (CONFIG.base_z + CONFIG.width) then
        error("ERROR: Error in program - Turtle is out of field")


    elseif x == CONFIG.base_x and z == CONFIG.base_z then
        TransferInventory()
        Refuel()
        SetDirection("south")
        turtle.forward()


    elseif z > CONFIG.base_z and z < (CONFIG.base_z + CONFIG.lenght) then
        CheckCrop(CONFIG.seed_name)
        turtle.forward()


        -- Going to the base
    elseif z == CONFIG.base_z and direction == "west" then
        turtle.forward()


        -- On the last block - now face to return home
    elseif z == CONFIG.base_z and x == CONFIG.base_x + CONFIG.width then
        SetDirection("west")
        turtle.forward()


        -- on the northtest row, go to next column
    elseif z == CONFIG.base_z then
        CheckCrop(CONFIG.seed_name)
        SetDirection("east")
        turtle.forward()
        CheckCrop(CONFIG.seed_name)
        SetDirection("south")
        turtle.forward()


        -- In the final south corner - need to turn north
    elseif z == CONFIG.base_z + CONFIG.lenght and x == CONFIG.base_x + CONFIG.width then
        CheckCrop(CONFIG.seed_name)
        SetDirection("north")
        turtle.forward()


        -- On the southtest row, go to next column
    elseif z == CONFIG.base_z + CONFIG.lenght then
        CheckCrop(CONFIG.seed_name)
        SetDirection("east")
        turtle.forward()
        CheckCrop(CONFIG.seed_name)
        SetDirection("north")
        turtle.forward()
    end

    os.sleep(20)

end
