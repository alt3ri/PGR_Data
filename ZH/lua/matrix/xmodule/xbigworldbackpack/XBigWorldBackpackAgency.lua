---@class XBigWorldBackpackAgency : XAgency
---@field private _Model XBigWorldBackpackModel
local XBigWorldBackpackAgency = XClass(XAgency, "XBigWorldBackpackAgency")

function XBigWorldBackpackAgency:OnInit()
    -- 初始化一些变量
end

function XBigWorldBackpackAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldBackpackAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldBackpackAgency:CheckHasNotRecord()
    local configs = self._Model:GetBackpackTypeConfigs()

    if XTool.IsTableEmpty(configs) then
        return false
    end

    for _, config in pairs(configs) do
        if not config.IsTabHide then
            if config.TagType == XEnumConst.BWBackpack.ItemType.Quest then
                local questItemIds = XMVCA.XBigWorldService:GetAllQuestItemIdList()

                if not XTool.IsTableEmpty(questItemIds) then
                    for _, itemId in pairs(questItemIds) do
                        if not self._Model:CheckItemIsRecord(itemId) then
                            return true
                        end
                    end
                end
            elseif config.TagType == XEnumConst.BWBackpack.ItemType.SGDorm then
                local itemTypes = config.ItemTypes
                local furnitureList =  XMVCA.XSkyGardenDorm:GetOwnFurnitureList(itemTypes)

                if not XTool.IsTableEmpty(furnitureList) then
                    for _, item in pairs(furnitureList) do
                        if not self._Model:CheckItemIsRecord(item.TemplateId) then
                            return true
                        end
                    end
                end
            elseif config.TagType == XEnumConst.BWBackpack.ItemType.Normal then
                local itemTypes = config.ItemTypes
                local itemList = XMVCA.XBigWorldService:GetItemsByItemTypes(itemTypes)

                if not XTool.IsTableEmpty(itemList) then
                    for _, item in pairs(itemList) do
                        if not self._Model:CheckItemIsRecord(item.Id) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

return XBigWorldBackpackAgency
