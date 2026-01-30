local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiArenaNewPrepare = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewPrepare")
local XUiArenaNewLeft = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewLeft")
local XUiArenaNewRight = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewRight")
local XUiArenaScene = require("XUi/XUiArenaNew/XUiArenaScene")

---@class XUiArenaNew : XLuaUi
---@field PanelPrepare UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field PanelAsset UnityEngine.RectTransform
---@field BtnHelp XUiComponent.XUiButton
---@field PanelLeft UnityEngine.RectTransform
---@field PanelRight UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaNew = XLuaUiManager.Register(XLuaUi, "UiArenaNew")

local CameraState = {
    Main = 1,
    Chapter = 2,
    Tips = 3,
}

-- region 生命周期

function XUiArenaNew:OnAwake()
    ---@type XUiArenaNewPrepare
    self._PanelPrepareUi = nil
    ---@type XUiArenaNewLeft
    self._PanelLeftUi = nil
    ---@type XUiArenaNewRight
    self._PanelRightUi = nil
    ---@type XUiArenaScene
    self._Scene = XUiArenaScene.New(self.UiModelGo)
    self._CurrentState = CameraState.Main
    self._CurrentChapterIndex = 1
    self._Animation = nil
    self._EnterTimer = nil

    self:_InitAnimation()
    self:_RegisterButtonClicks()
end

---@param groupData XArenaGroupDataBase
function XUiArenaNew:OnStart(groupData)
    self._PanelPrepareUi = XUiArenaNewPrepare.New(self.PanelPrepare, self, groupData)
    self._PanelLeftUi = XUiArenaNewLeft.New(self.PanelLeft, self, groupData)
    self._PanelRightUi = XUiArenaNewRight.New(self.PanelRight, self, self._Scene)

    self._Scene:ChangeCamera("ChapterCamera")
    self._PanelRightUi:Close()
    self._PanelPrepareUi:Close()
    self._Scene:PlayStartAnimation()
    self._AssetUi = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:_ShowEnterEffect()
end

function XUiArenaNew:OnEnable()
    if not self._Control:CheckOpenNewActivityResultUi() then
        self._Control:CheckOpenActivityResultUi()
    end

    self:_RefreshCamera()
    self:_RegisterListeners()
end

function XUiArenaNew:OnDisable()
    self:_RemoveListeners()
    self:_RemoveEnterTimer()
end

function XUiArenaNew:OnDestroy()
    self._Scene:Destroy()
end

-- endregion

function XUiArenaNew:OnShowChapter(index)
    self._PanelLeftUi:Close()
    self._AssetUi:Close()
    self._PanelRightUi:Close()
    self._Scene:ChangeCamera("StageCamera" .. index)
    self:_SetExitPanelActive(false)
    self._CurrentChapterIndex = index
    self._CurrentState = CameraState.Chapter
end

function XUiArenaNew:OnShowTips()
    self._PanelLeftUi:Close()
    self._AssetUi:Close()
    self._PanelRightUi:Close()
    self._PanelPrepareUi:Close()
    self._Scene:SetZoneActive(false)
    self._Scene:ChangeCamera("TipsCamera")
    self:_SetExitPanelActive(false)
    self._CurrentState = CameraState.Tips
end

function XUiArenaNew:OnShowMainUi(isNotPlayAnimation)
    self:_Refresh()
    self._AssetUi:Open()
    self._Scene:SetZoneActive(true)
    self._Scene:CancelSelectZone()
    self._Scene:ChangeCamera("ChapterCamera")
    self:_SetExitPanelActive(true)
    self._CurrentState = CameraState.Main

    if not isNotPlayAnimation then
        self:_PlayBeginAnimation()
    end
end

-- region 私有方法

function XUiArenaNew:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "Arena")
end

function XUiArenaNew:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_ARENA_RESHOW_MAIN_UI, self.OnShowMainUi, self)
end

function XUiArenaNew:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENA_RESHOW_MAIN_UI, self.OnShowMainUi, self)
end

function XUiArenaNew:_RefreshCamera()
    if self._CurrentState == CameraState.Tips then
        self:OnShowTips()
    elseif self._CurrentState == CameraState.Chapter then
        self._CurrentChapterIndex = self._Scene:GetCurrentSelectIndex()
        self:OnShowChapter(self._CurrentChapterIndex)
    else
        self:OnShowMainUi(true)
    end
end

function XUiArenaNew:_Refresh()
    self._PanelLeftUi:Open()
    if self._Control:GetIsRefreshMainPage() then
        if self._Control:IsInActivityFightStatus() then
            self._Control:GroupMemberRequest(Handler(self, self._RefreshLeftPanel))
        else
            self._Control:ScoreQueryRequest(Handler(self, self._RefreshLeftPanel))
        end
    end
    if self._Control:IsInActivityFightStatus() then
        self._Control:AreaDataRequest(function(areaData)
            self._PanelRightUi:Open()
            self._PanelRightUi:Refresh(areaData)
            self._PanelRightUi:CheckTaskRedDot()
            -- zone 更新完成后，检查是否需要弹出新纪录弹窗
            self:_CheckAndShowNewRecordPopup()
        end)
        self._PanelPrepareUi:Close()
    else
        self._PanelPrepareUi:Open()
        self._PanelRightUi:Close()
    end
end

function XUiArenaNew:_RefreshLeftPanel(groupData)
    if groupData then
        self._PanelLeftUi:Refresh(groupData)
        self._Control:SetIsRefreshMainPage(false)
    end
end

function XUiArenaNew:_SetExitPanelActive(isActive)
    self.BtnBack.gameObject:SetActiveEx(isActive)
    self.BtnMainUi.gameObject:SetActiveEx(isActive)
    self.BtnHelp.gameObject:SetActiveEx(isActive)
end

function XUiArenaNew:_InitAnimation()
    if self.Transform then
        local animation = self.Transform:FindTransform("UiArenaNewJumpEnable")

        if animation then
            self._Animation = animation
        end
    end
end

function XUiArenaNew:_PlayBeginAnimation()
    if self._Animation then
        self._Animation.gameObject:PlayTimelineAnimation()
    end
end

function XUiArenaNew:_ShowEnterEffect()
    self:_RemoveEnterTimer()
    self._EnterTimer = XScheduleManager.ScheduleOnce(function()
        if self._Scene then
            self._Scene:ShowEnterEffect()
            self._Scene:ShowChangeEffect()
        end
        self._EnterTimer = nil
    end, XScheduleManager.SECOND)
end

function XUiArenaNew:_RemoveEnterTimer()
    if self._EnterTimer then
        XScheduleManager.UnSchedule(self._EnterTimer)
        self._EnterTimer = nil
    end
end

--- 检查并显示新纪录弹窗
function XUiArenaNew:_CheckAndShowNewRecordPopup()
    local areaData = self._Control:GetArenaAreaData()
    if not areaData or areaData:IsClear() then
        return
    end
    
    -- 遍历所有区域，检查是否有新纪录
    local areaShowList = areaData:GetArenaShowList()
    if not areaShowList or XTool.IsTableEmpty(areaShowList) then
        return
    end
    
    for zoneIndex, areaShowData in ipairs(areaShowList) do
        if areaShowData and not areaShowData:IsClear() then
            local areaId = areaShowData:GetAreaId()
            local currentPoint = areaShowData:GetPoint() or 0
            
            -- 获取该区域的 DistributeType 数组
            local distributeTypeList = self._Control:GetAreaStageDistributeTypeByAreaId(areaId)
            if distributeTypeList and not XTool.IsTableEmpty(distributeTypeList) then
                -- 遍历所有 DistributeType，检查是否有新纪录
                for index, distributeType in ipairs(distributeTypeList) do
                    -- 使用结算时保存的数据（Point 和 OldPoint）
                    local settleData = self._Control:GetSettlePointByDistributeType(distributeType)
                    
                    if settleData and settleData.Point and settleData.OldPoint then
                        local point = settleData.Point
                        local oldPoint = settleData.OldPoint
                        
                        -- 如果当前分数超过历史最高分，则发现新纪录（和结算界面一样：Point > OldPoint）
                        if point > oldPoint and point > 0 then
                            -- 清除已使用的结算数据（弹窗需要，但zone标记不clear）
                            self._Control:ClearSettlePointByDistributeType(distributeType)
                            
                            -- 显示新纪录标记（zone这边不clear）
                            self:_ShowNewRecordMark(zoneIndex)
                        
                            -- 获取区域名称（使用当前选中的 Buff 索引对应的名称）
                            local areaName = self._Control:GetAreaStageNameByAreaId(areaId) or ""
                            local buffName = self._Control:GetAreaStageBuffNameByAreaIdAndIndex(areaId, index) or ""
                            
                            -- 构建新纪录数据
                            local recordData = {
                                areaName = areaName,
                                buffName = buffName,
                                score = point,
                                areaId = areaId,
                                distributeType = distributeType
                            }
                            
                            -- 打开新纪录弹窗
                            XLuaUiManager.Open("UiArenaPopupNewRecord", recordData)
                            return -- 只显示第一个新纪录
                        end
                    end
                end
            end
        end
    end
end

--- 显示新纪录标记
---@param zoneIndex number zone的索引（从1开始）
function XUiArenaNew:_ShowNewRecordMark(zoneIndex)
    if not self._Scene then
        return
    end
    
    -- 获取zone（需要根据实际场景的startIndex计算）
    local zone = self._Scene:GetZoneByIndex(zoneIndex)
    if zone then
        zone:ShowNewRecord(true)
    end
end

-- endregion

return XUiArenaNew
