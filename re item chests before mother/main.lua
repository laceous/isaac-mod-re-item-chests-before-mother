local mod = RegisterMod('Re: Item Chests Before Mother', 1)
local game = Game()

if REPENTOGON then
  mod.rngShiftIdx = 35
  
  function mod:onNewRoom()
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    
    if mod:isHoleRoom() and
       room:IsFirstVisit() and
       room:IsClear()
    then
      local rng = RNG(room:GetSpawnSeed(), mod.rngShiftIdx)
      local chestVariant = level:GetStateFlag(LevelStateFlag.STATE_SATANIC_BIBLE_USED) and PickupVariant.PICKUP_REDCHEST or PickupVariant.PICKUP_LOCKEDCHEST
      
      for _, v in ipairs({ 34, 40, 94, 100 }) do
        for i = 1, v do
          rng:Next() -- skip numbers to better deal with 2 items in PICKUP_MEGACHEST, we could also use different shift indexes
        end
        
        -- game:Spawn w/ seed over Isaac.Spawn for consistency with glowing hourglass
        -- can sometimes spawn PICKUP_ETERNALCHEST/PICKUP_MEGACHEST, or PICKUP_REDCHEST with the left hand trinket
        -- pass ChestSubType.CHEST_CLOSED if you want to force locked chests over red chests
        game:Spawn(EntityType.ENTITY_PICKUP, chestVariant, room:GetGridPosition(v), Vector.Zero, nil, 0, rng:Next())
      end
    end
  end
  
  -- d6 should re-roll into other treasure room items
  function mod:onPreGetCollectible(itemPoolType, decrease, seed)
    if mod:isHoleRoom() and itemPoolType == ItemPoolType.POOL_BOSS then
      local itemPool = game:GetItemPool()
      return itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, decrease, seed, CollectibleType.COLLECTIBLE_NULL)
    end
  end
  
  function mod:onPrePickupGetLootList(pickup, shouldAdvance)
    if mod:isHoleRoom() then
      -- PICKUP_OLDCHEST/PICKUP_WOODENCHEST don't guarantee items in the chest
      if pickup.Variant == PickupVariant.PICKUP_CHEST or
         pickup.Variant == PickupVariant.PICKUP_BOMBCHEST or
         pickup.Variant == PickupVariant.PICKUP_SPIKEDCHEST or
         pickup.Variant == PickupVariant.PICKUP_ETERNALCHEST or
         pickup.Variant == PickupVariant.PICKUP_MIMICCHEST or
         pickup.Variant == PickupVariant.PICKUP_MEGACHEST or
         pickup.Variant == PickupVariant.PICKUP_HAUNTEDCHEST or
         pickup.Variant == PickupVariant.PICKUP_LOCKEDCHEST or
         pickup.Variant == PickupVariant.PICKUP_REDCHEST
      then
        local ll = LootList()
        local rng = RNG(pickup.InitSeed, mod.rngShiftIdx)
        local itemPool = game:GetItemPool()
        local itemPoolType = pickup.Variant == PickupVariant.PICKUP_REDCHEST and ItemPoolType.POOL_DEVIL or ItemPoolType.POOL_TREASURE
        
        for i = 1, pickup.Variant == PickupVariant.PICKUP_MEGACHEST and 2 or 1 do
          local collectible = itemPool:GetCollectible(itemPoolType, shouldAdvance, rng:Next(), CollectibleType.COLLECTIBLE_NULL)
          ll:PushEntry(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectible, nil, nil)
        end
        
        return ll
      end
    end
  end
  
  -- filtered to: PICKUP_COLLECTIBLE
  -- this doesn't work in MC_POST_PICKUP_INIT
  function mod:onPickupUpdate(pickup)
    -- vanilla api: to check for red chest, get sprite overlay frame number when overlay animation == 'Alternates'
    if mod:isHoleRoom() and not pickup:IsShopItem() and pickup:GetAlternatePedestal() == PedestalType.RED_CHEST then
      -- vanilla api: set Price and ShopItemId
      pickup:MakeShopItem(-2) -- devil price
    end
  end
  
  -- support "goto s.boss.6000" which you can do from anywhere
  function mod:isHoleRoom()
    if not game:IsGreedMode() then
      local level = game:GetLevel()
      local room = level:GetCurrentRoom()
      local roomDesc = level:GetCurrentRoomDesc()
      
      if room:GetType() == RoomType.ROOM_BOSS and
         room:GetRoomShape() == RoomShape.ROOMSHAPE_1x1 and
         roomDesc.Data.StageID == StbType.SPECIAL_ROOMS and
         roomDesc.Data.Variant == 6000 -- Name == 'Mother', Subtype == 88
      then
        local gridEntity = room:GetGridEntityFromPos(room:GetCenterPos()) -- 67
        if gridEntity and gridEntity:GetType() == GridEntityType.GRID_TRAPDOOR then -- gfx/grid/trapdoor_corpse_big.anm2
          return true
        end
      end
    end
    
    return false
  end
  
  mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
  mod:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, mod.onPreGetCollectible)
  mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_GET_LOOT_LIST, mod.onPrePickupGetLootList)
  mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.onPickupUpdate, PickupVariant.PICKUP_COLLECTIBLE)
end