---@class XBigWorldBackpackControl : XControl
---@field private _Model XBigWorldBackpackModel
local XBigWorldBackpackControl = XClass(XControl, "XBigWorldBackpackControl")

function XBigWorldBackpackControl:OnInit()
    -- 初始化内部变量
    self._AllShowItemTypes = nil
end

function XBigWorldBackpackControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldBackpackControl:RemoveAgencyEvent()

end

function XBigWorldBackpackControl:OnRelease()
    self._AllShowItemTypes = nil
    -- XLog.Error("这里执行Control的释放")
end

function XBigWorldBackpackControl:GetTagTypeDescription(tagType)
    return self._Model:GetBackpackTypeDescriptionByType(tagType)
end

function XBigWorldBackpackControl:CheckItemCanUse(itemId)
    return XMVCA.XBigWorldService:GetItemType(itemId) == XItemConfigs.ItemType.Gift
end

function XBigWorldBackpackControl:CheckItemIsRecord(item)
    local data = XMVCA.XBigWorldService:GetItemsShowParams(item)

    return self._Model:CheckItemIsRecord(data.TemplateId)
end

function XBigWorldBackpackControl:CheckTypeHasNotRecord(backpackType)
    local items = self:GetItemListByType(backpackType)

    if XTool.IsTableEmpty(items) then
        return false
    end

    for _, item in pairs(items) do
        if not self:CheckItemIsRecord(item) then
            return true
        end
    end

    return false
end

function XBigWorldBackpackControl:AddRecordItemId(item)
    local data = XMVCA.XBigWorldService:GetItemsShowParams(item)

    self._Model:AddRecordItemId(data.TemplateId)
end

function XBigWorldBackpackControl:GetItemListByType(backpackType)
    return self:_TryGetItemListByType(backpackType)
end

---@return XTableBigWorldBackpackType[]
function XBigWorldBackpackControl:GetAllBackpackType(isSort, isDisplay)
    local configs = self._Model:GetBackpackTypeConfigs()

    if isSort then
        local result = {}

        for _, config in pairs(configs) do
            if isDisplay then
                if not config.IsTabHide then
                    table.insert(result, config)
                end
            else
                table.insert(result, config)
            end

        end
        table.sort(result, function(typeA, typeB)
            return typeA.Priority > typeB.Priority
        end)
        configs = result
    end

    return configs
end

function XBigWorldBackpackControl:_GetAllShowItemTypes()
    if not self._AllShowItemTypes then
        self._AllShowItemTypes = {}

        local backpackTypes = self:GetAllBackpackType()

        if not XTool.IsTableEmpty(backpackTypes) then
            for _, backpackType in pairs(backpackTypes) do
                if backpackType.TagType == XEnumConst.BWBackpack.ItemType.Normal then
                    local itemTypes = backpackType.ItemTypes

                    if not XTool.IsTableEmpty(itemTypes) then
                        for _, itemType in pairs(itemTypes) do
                            table.insert(self._AllShowItemTypes, itemType)
                        end
                    end
                end
            end
        end
    end

    return self._AllShowItemTypes
end

function XBigWorldBackpackControl:_TryGetItemListByType(backpackType)
    local result = {}
    local tagType = self._Model:GetBackpackTypeTagTypeByType(backpackType)

    if tagType == XEnumConst.BWBackpack.ItemType.All then
        local allShowTypes = self:_GetAllShowItemTypes()
        local items = XMVCA.XBigWorldService:GetItemsByItemTypes(allShowTypes)
        local questItems = self:_GetQuestItems()

        result = XTool.MergeArray(items, questItems)
    elseif tagType == XEnumConst.BWBackpack.ItemType.Quest then
        result = self:_GetQuestItems()
    elseif tagType == XEnumConst.BWBackpack.ItemType.SGDorm then
        local itemTypes = self._Model:GetBackpackTypeItemTypesByType(backpackType)
        result = self:_GetSgDormItems(itemTypes)
    else
        local itemTypes = self._Model:GetBackpackTypeItemTypesByType(backpackType)

        result = XMVCA.XBigWorldService:GetItemsByItemTypes(itemTypes)
    end

    return result
end

function XBigWorldBackpackControl:_GetQuestItems()
    local result = {}
    local questItemIds = XMVCA.XBigWorldService:GetAllQuestItemIdList()

    for _, itemId in pairs(questItemIds) do
        local count = XMVCA.XBigWorldService:GetQuestItemCount(itemId)
        if count > 0 then
            table.insert(result, {
                TemplateId = itemId,
                Count = count,
            })
        end
    end

    return result
end

function XBigWorldBackpackControl:_GetSgDormItems(itemTypes)
    return XMVCA.XSkyGardenDorm:GetOwnFurnitureList(itemTypes)
end

return XBigWorldBackpackControl
