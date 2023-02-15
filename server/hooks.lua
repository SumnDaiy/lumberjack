local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
    return false
end, {
    itemFilter = {
        log = true,
    },
    inventoryFilter = {
        '^glove[%w]+',
        '^trunk[%w]+',
    }
})

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    exports.ox_inventory:removeHooks(hookId)
  end)