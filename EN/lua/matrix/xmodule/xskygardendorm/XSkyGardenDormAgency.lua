local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")

---@class XSkyGardenDormAgency : XBigWorldActivityAgency
---@field private _Model XSkyGardenDormModel
---@field private _Manager XDormitory.XDormManager
local XSkyGardenDormAgency = XClass(XBigWorldActivityAgency, "XSkyGardenDormAgency")

---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XSkyGardenDormAgency:OnInit()
    self.XSgDormAreaType = {
        --照片墙
        Wall = 1,
        --手办架
        GiftShelf = 2
    }

    self.XSgFurnitureType = {
        -- 装饰品
        Decoration = 1,

        -- 本地照片
        SystemPhoto = 2,

        -- 底板
        DecorationBoard = 3,

        -- 摆件
        Gift = 4,

        -- 摆件架
        GiftShelf = 5,
        
        --相册照片
        AlbumPhoto = 6,
    }
    
    self.XEventId = {
        -- 宿舍有新的图鉴解锁
        REFRESH_HANDBOOK_NEW_MARK = 1,
        -- 宿舍预设刷新
        EVENT_DORM_LAYOUT_REFRESH = 2,
        -- 宿舍应用新预设
        EVENT_DORM_APPLY_NEW_LAYOUT = 3,
        -- 宿舍家具刷新
        EVENT_DORM_FURNITURE_REFRESH = 4,
    }
    self._EventListener = {}
    self.CameraDuration = 0.5
    -- float -> long
    self.Ratio = 1000000
    
    self._UpdateLocalPhotoDataCb = function(dataList) 
        self._Model:NotifySgPhotoData(dataList)
    end
end

function XSkyGardenDormAgency:InitRpc()
    self:AddRpc("NotifySgDormData", handler(self, self.NotifySgDormData))
    self:AddRpc("NotifySgDormFurnitureAdd", handler(self, self.NotifySgDormFurnitureAdd))
    self:AddRpc("NotifySgDormFashionAdd", handler(self, self.NotifySgDormFashionAdd))
    self:AddRpc("NotifySgDormCurLayout", handler(self, self.NotifySgDormCurLayout))
    self:AddRpc("NotifySgDormLayoutChanged", handler(self, self.NotifySgDormLayoutChanged))
end

function XSkyGardenDormAgency:InitEvent()
end

function XSkyGardenDormAgency:OnRelease()
    self._EventListener = nil
end

function XSkyGardenDormAgency:CheckFunctionOpen()
    return XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.SgDorm)
end

--- 家具墙
---@param wallType number
function XSkyGardenDormAgency:OpenFurnitureWall(wallType)
    if not self:CheckFunctionOpen() then
        return
    end
    if not self._TryRemoveBlackCb then
        self._TryRemoveBlackCb = function()
            XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
        end
    end
    XMVCA.XBigWorldUI:OpenWithCallback("UiSkyGardenDormPhotoWall", self._TryRemoveBlackCb, wallType)
end

function XSkyGardenDormAgency:OpenPhotoWall()
    if not XMVCA.XBigWorldFunction:IsFunctionEventFree() then
        return
    end
    XMVCA.XBigWorldAlbum:InitPhotoDatas(self._UpdateLocalPhotoDataCb)
    --黑屏
    XMVCA.XBigWorldLoading:OpenBlackMaskLoading(function()
        --隐藏指挥官
        XMVCA.XBigWorldGamePlay:SetCurNpcActive(false)
        --推进相机
        XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenDormCameraPhotoWall", self.CameraDuration)
        --修改相机投影方式
        XMVCA.XBigWorldGamePlay:SetCameraProjection(true)
        --打开界面
        XScheduleManager.ScheduleOnce(function()
            self:OpenFurnitureWall(self.XSgDormAreaType.Wall)
        end, self.CameraDuration * 1000 + 20)
    end)
end

function XSkyGardenDormAgency:OpenGiftWall()
    if not XMVCA.XBigWorldFunction:IsFunctionEventFree() then
        return
    end
    --黑屏
    XMVCA.XBigWorldLoading:OpenBlackMaskLoading(function()
        --隐藏指挥官
        XMVCA.XBigWorldGamePlay:SetCurNpcActive(false)
        --推进相机
        XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenDormCameraFrame", self.CameraDuration)
        --修改相机投影方式
        XMVCA.XBigWorldGamePlay:SetCameraProjection(true)
        --打开界面
        XScheduleManager.ScheduleOnce(function()
            self:OpenFurnitureWall(self.XSgDormAreaType.GiftShelf)
        end, self.CameraDuration * 1000 + 20)
    end)
end

function XSkyGardenDormAgency:OpenFashion()
    XMVCA.XBigWorldGamePlay:SetCurNpcActive(false)
    XMVCA.XBigWorldUI:Open("UiSkyGardenDormCoating")
    XMVCA.XBigWorldGamePlay:ActivateVCamera("UiSkyGardenDormCameraChangeSkin", self.CameraDuration)
end

function XSkyGardenDormAgency:OnEnterLevel()
    CS.XDormitory.XDormManager.Init()
    self._Manager = CS.XDormitory.XDormManager.Instance
end

function XSkyGardenDormAgency:OnLeaveLevel()
    self._Manager:Destroy()
    self._Manager = nil
end

function XSkyGardenDormAgency:GetManager()
    if not self._Manager then
        XLog.Warning("管理器已经被回收，请勿调用！！！")
        return
    end
    return self._Manager
end

function XSkyGardenDormAgency:OnFightGetGamePlayData()
    local photos, adorns, gifts = self._Model:GetFightInitData(true, true)
    return {
        DormitorySkinId = self._Model:GetFashionSkinId(self._Model:GetDormData():GetCurFashionId()),
        PhotoWallId = self._Model:GetFurnitureSceneObjId(self._Model:GetLayoutContainer(self.XSgDormAreaType.Wall):GetCfgId()),
        FrameWallId = self._Model:GetFurnitureSceneObjId(self._Model:GetLayoutContainer(self.XSgDormAreaType.GiftShelf):GetCfgId()),
        Photos = photos,
        PhotoAdorns = adorns,
        FrameGoods = gifts
    }
end

function XSkyGardenDormAgency:OnFightPushData(data)
    self._Model:RemoveAllFightFurnitureData()
    self._Model:GetWallFightData():UpdateData(data.PhotoWallData.ActorRef)
    local giftData = data.FrameWallData
    self._Model:GetGiftShelfFightData():UpdateData(giftData.ActorRef, giftData.FrameGridSizeList)
    self._Model:UpdateFightFurnitureData(data.PhotosData)
    self._Model:UpdateFightFurnitureData(data.PhotoAdornsData)
    self._Model:UpdateFightFurnitureData(data.FrameGoodsData)
end

function XSkyGardenDormAgency:NotifySgDormData(data)
    self._Model:NotifySgDormData(data)
    XMVCA.XBigWorldAlbum:InitPhotoDatas(self._UpdateLocalPhotoDataCb)
end

function XSkyGardenDormAgency:NotifySgDormFurnitureAdd(data)
    self._Model:NotifySgDormFurnitureAdd(data)
end

function XSkyGardenDormAgency:NotifySgDormFashionAdd(data)
    self._Model:NotifySgDormFashionAdd(data)
end

function XSkyGardenDormAgency:NotifySgDormCurLayout(data)
    self._Model:NotifySgDormCurLayout(data)
end

function XSkyGardenDormAgency:NotifySgDormLayoutChanged(data)
    self._Model:NotifySgDormLayoutChanged(data)
    local layoutList = data.LayoutList
    if not XTool.IsTableEmpty(layoutList) then
        for _, layout in pairs(layoutList) do
            local areaType, layoutId = layout.AreaType, layout.LayoutId
            local areaTypeLayoutId = self._Model:GetLayoutIdByAreaType(areaType)
            if areaTypeLayoutId == layoutId then
                self:RevertDecoration(areaType, self._Model:GetContainerFurnitureData(areaType))
            end
        end
    end
end

function XSkyGardenDormAgency:Subscribe(eventId, func, caller)
    local eventDict = self._EventListener[eventId]
    if not eventDict then
        eventDict = {}
        self._EventListener[eventId] = eventDict
    end
    local dict = eventDict[caller]
    if not dict then
        dict = {}
        eventDict[caller] = dict
    end
    dict[func] = func
end

function XSkyGardenDormAgency:Unsubscribe(eventId, func, caller)
    local eventDict = self._EventListener[eventId]
    if not eventDict then
        return
    end
    local dict = eventDict[caller]
    if not dict then
        return
    end
    dict[func] = nil
end

function XSkyGardenDormAgency:Notify(eventId, ...)
    local eventDict = self._EventListener[eventId]
    if not eventDict then
        return
    end
    for caller, funcDict in pairs(eventDict) do
        for _, func in pairs(funcDict) do
            func(caller, ...)
        end
    end
end

--- 恢复到服务器的数据
---@param areaType number 区域
---@param serverData XSgContainerFurnitureData 服务端记录的家具
function XSkyGardenDormAgency:RevertDecoration(areaType, serverData)
    if areaType == self.XSgDormAreaType.Wall then
        local photos, adorns = self._Model:GetPhotoWallFightInitData(serverData)
        local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_RESET_PHOTO_WALL, {
            PhotoWallId = self._Model:GetFurnitureSceneObjId(serverData:GetContainer():GetCfgId()),
            Photos = photos,
            PhotoAdorns = adorns,
        })
        self._Model:GetWallFightData():UpdateData(data.PhotoWallData.ActorRef)
        self._Model:UpdateFightFurnitureData(data.PhotosData)
        self._Model:UpdateFightFurnitureData(data.PhotoAdornsData)
    elseif areaType == self.XSgDormAreaType.GiftShelf then
        local gifts = self._Model:GetGiftShelfFightInitData(serverData)
        local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_RESET_FRAME_WALL, {
            FrameWallId = self._Model:GetFurnitureSceneObjId(serverData:GetContainer():GetCfgId()),
            FrameGoods = gifts,
        })
        local giftData = data.FrameWallData
        self._Model:GetGiftShelfFightData():UpdateData(giftData.ActorRef, giftData.FrameGridSizeList)
        self._Model:UpdateFightFurnitureData(data.FrameGoodsData)
    end
end

function XSkyGardenDormAgency:GetDormFurnitureGoodsParams(templateId)
    local t = self._Model:GetFurnitureTemplate(templateId)
    return {
        RewardType = XRewardManager.XRewardType.SgDormFurniture,
        TemplateId = templateId,
        Icon = t.Icon,
        Quality = t.Quality,
        Name = t.Name,
        WorldDesc = t.WorldDesc,
        Description = t.Desc
    }
end

function XSkyGardenDormAgency:GetDormFashionGoodsParams(templateId)
    local t = self._Model:GetFashionTemplate(templateId)
    return {
        RewardType = XRewardManager.XRewardType.SgDormFurniture,
        TemplateId = templateId,
        Icon = t.Icon,
        Quality = t.Quality,
        Name = t.Name,
        WorldDesc = t.WorldDesc,
        Description = t.Desc
    }
end

function XSkyGardenDormAgency:GetFurnitureName(templateId)
    local t = self._Model:GetFurnitureTemplate(templateId)
    return t and t.Name or ""
end

function XSkyGardenDormAgency:GetFurnitureQuality(templateId)
    local t = self._Model:GetFurnitureTemplate(templateId)
    return t and t.Quality or ""
end

function XSkyGardenDormAgency:GetFurnitureIcon(templateId)
    local t = self._Model:GetFurnitureTemplate(templateId)
    return t and t.Icon or ""
end

function XSkyGardenDormAgency:GetFurnitureDescription(templateId)
    local t = self._Model:GetFurnitureTemplate(templateId)
    return t and t.Desc or ""
end

function XSkyGardenDormAgency:GetFurnitureWorldDescription(templateId)
    local t = self._Model:GetFurnitureTemplate(templateId)
    return t and t.WorldDesc or ""
end

function XSkyGardenDormAgency:GetFurnitureCount(templateId)
    return self._Model:GetDormData():GetFurnitureCount(templateId)
end

function XSkyGardenDormAgency:GetOwnFurnitureList(itemTypes)
    local list = {}
    
    if XTool.IsTableEmpty(itemTypes) then
        return list
    end
    local typeDict = {}
    for _, type in pairs(itemTypes) do
        typeDict[type] = true
    end
    
    local dict = {}
    local furnitureDict = self._Model:GetDormData():GetOwnFurnitureDict()
    for _, furniture in pairs(furnitureDict) do
        local templateId = furniture:GetCfgId()
        local typeId = self._Model:GetFurnitureTypeId(templateId)
        if typeDict[typeId] then
            if not dict[templateId] then
                dict[templateId] = 1
                list[#list + 1] = {
                    TemplateId = templateId,
                    Count = 0
                }
            else
                dict[templateId] = dict[templateId] + 1
            end
        end
    end
    for _, item in pairs(list) do
        local templateId = item.TemplateId
        item.Count = dict[templateId] or 0
    end
    if #list > 1 then
        table.sort(list, function(a, b)
            local idA = a.TemplateId
            local idB = b.TemplateId
            local tA = self._Model:GetFurnitureTemplate(idA)
            local tB = self._Model:GetFurnitureTemplate(idB)
            if tA.Priority ~= tB.Priority then
                return tA.Priority < tB.Priority
            end
            return a.TemplateId < b.TemplateId
        end)
    end
    return list
end

function XSkyGardenDormAgency:GetFashionName(templateId)
    local t = self._Model:GetFashionTemplate(templateId)
    return t and t.Name or ""
end

function XSkyGardenDormAgency:GetFashionQuality(templateId)
    local t = self._Model:GetFashionTemplate(templateId)
    return t and t.Quality or ""
end

function XSkyGardenDormAgency:GetFashionIcon(templateId)
    local t = self._Model:GetFashionTemplate(templateId)
    return t and t.Icon or ""
end

function XSkyGardenDormAgency:GetFashionDescription(templateId)
    local t = self._Model:GetFashionTemplate(templateId)
    return t and t.Desc or ""
end

function XSkyGardenDormAgency:GetFashionWorldDescription(templateId)
    local t = self._Model:GetFashionTemplate(templateId)
    return t and t.WorldDesc or ""
end

function XSkyGardenDormAgency:GetFashionCount(templateId)
    local unlock = self._Model:GetDormData():IsFashionUnlock(templateId)
    return unlock and 1 or 0
end

return XSkyGardenDormAgency