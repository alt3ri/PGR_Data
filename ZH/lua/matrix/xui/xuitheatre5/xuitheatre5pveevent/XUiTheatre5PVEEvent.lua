---@class XUiTheatre5PVEEvent: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEEvent = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEEvent')
local XUiTheatre5PVEEventChat = require("XUi/XUiTheatre5/XUiTheatre5PVEEvent/XUiTheatre5PVEEventChat")
local XUiTheatre5PVEEventOption = require("XUi/XUiTheatre5/XUiTheatre5PVEEvent/XUiTheatre5PVEEventOption")

function XUiTheatre5PVEEvent:OnAwake()
    self._RewardList = nil
    self._OpenItemBoxs = nil
    self._ClueId = nil
    self._NextEventId = nil
    self._ChapterBattlePromoteCb = nil
    self.PanelReward.gameObject:SetActiveEx(true)
    self.PanelOption.gameObject:SetActiveEx(true)
    self._PVEEventChat = XUiTheatre5PVEEventChat.New(self.PanelReward,self)
    self._PVEEventOption = XUiTheatre5PVEEventOption.New(self.PanelOption,self)
    self:AddUIListener()
    self:AddEventListener()
end

function XUiTheatre5PVEEvent:OnStart(eventId, chapterBattlePromoteCb)
    self._ChapterBattlePromoteCb = chapterBattlePromoteCb
    self:RefreshAll(eventId)
end

function XUiTheatre5PVEEvent:OnEnable()

end

function XUiTheatre5PVEEvent:OnDisable()

end

function XUiTheatre5PVEEvent:AddUIListener()
    self:RegisterClickEvent(self.UiTheatre5BtnMain, self.OnClickBag, true)
    self:RegisterClickEvent(self.BtnClose, self.OnClickClose, true)
end

function XUiTheatre5PVEEvent:AddEventListener()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_UPDATE_EVENT, self.UpdateEvent, self)
end

function XUiTheatre5PVEEvent:RemoveEventListener()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_UPDATE_EVENT, self.UpdateEvent, self)
end

function XUiTheatre5PVEEvent:RefreshAll(eventId)
    local eventCfg = self._Control.PVEControl:GetPVEEventCfg(eventId)
    if not eventCfg then
        return
    end
    self:PlayAnimation('FadeOut', function()
        self:RefreshPanel(eventCfg)
        self:RefreshEventType(eventCfg) 
        self:PlayAnimation('FadeIn')
    end)  
end

function XUiTheatre5PVEEvent:RefreshPanel(eventCfg)
    self.TxtCoinNum.text = tostring(self._Control:GetGoldNum())
    
    local roleIcon = self._Control.PVEControl:GetEventRoleIcon(eventCfg.Id)
    local hasRoleIcon = not string.IsNilOrEmpty(roleIcon)
    self.RImgRole.gameObject:SetActiveEx(hasRoleIcon)
    if hasRoleIcon then
        self.RImgRole:SetRawImage(roleIcon)
    end
    
    local roleName = self._Control.PVEControl:GetEventRoleName(eventCfg.Id)
    local hasRoleName = not string.IsNilOrEmpty(roleName)
    self.TxtRoleName.gameObject:SetActiveEx(hasRoleName)
    if hasRoleName then
        self.TxtRoleName.text = roleName
    end

    local roleContent = self._Control.PVEControl:GetEventRoleContent(eventCfg.Id)
    local hasRoleContent = not string.IsNilOrEmpty(roleContent)
    self.TxtRoleContent.transform.parent.gameObject:SetActiveEx(hasRoleContent)
    if hasRoleContent then
        self.TxtRoleContent.text = XUiHelper.ReplaceTextNewLine(roleContent)
    end

    self.TxtTitle.text = eventCfg.Name
    local bgPath = eventCfg.BgAsset
    if string.IsNilOrEmpty(bgPath) then --事件没配背景图用章节的
        local chapterData = self._Control.PVEControl:GetCurChapterBattleData()
        if chapterData then
            local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(chapterData.ChapterId)
            bgPath = chapterCfg.BgAsset
        end
    end        

    self.Background:SetRawImage(bgPath)
end

function XUiTheatre5PVEEvent:RefreshEventType(eventCfg)
    self._PVEEventChat:SetVisible(eventCfg.Type == XMVCA.XTheatre5.EnumConst.PVEEventType.Chat)
    self._PVEEventOption:SetVisible(eventCfg.Type == XMVCA.XTheatre5.EnumConst.PVEEventType.Option)
    if eventCfg.Type == XMVCA.XTheatre5.EnumConst.PVEEventType.Chat then
        self._PVEEventChat:UpdateData(eventCfg)
    elseif eventCfg.Type == XMVCA.XTheatre5.EnumConst.PVEEventType.Option then
        self._PVEEventOption:UpdateData(eventCfg)
    end             
end

function XUiTheatre5PVEEvent:UpdateEvent(res)
    self._RewardList = {}
    self._OpenItemBoxs = {}
    self._ClueId = res.ClueId
    self._NextEventId = res.NextEventId
    if res.PveEventReward then
        self:SetRewardGroup(res.PveEventReward)
    end
    if res.ExtPveEventReward then
        self:SetRewardGroup(res.ExtPveEventReward)
    end    
    self:OpenItemBoxs()
end

function XUiTheatre5PVEEvent:SetRewardGroup(eventReward, isFirst)
    if not XTool.IsTableEmpty(eventReward.Items) then
        for _, theatre5Item in pairs(eventReward.Items) do
            if theatre5Item.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.ItemBox then
                table.insert(self._OpenItemBoxs, {Theatre5Item = theatre5Item, IsFirst = isFirst})
            else  --宝箱里没有金币
                table.insert(self._RewardList, {Id = theatre5Item.ItemId, Type = theatre5Item.ItemType, Count = 1, IsFirst = isFirst}) 
            end    
        end
    end
    if XTool.IsNumberValid(eventReward.GoldNum) then
        table.insert(self._RewardList, {Id = 1, Type = XMVCA.XTheatre5.EnumConst.ItemType.Gold, Count = eventReward.GoldNum,  IsFirst = isFirst})
    end
end

--打开宝箱
function XUiTheatre5PVEEvent:OpenItemBoxs()
    if XTool.IsTableEmpty(self._OpenItemBoxs) then
        self:ShowRewards()
        return
    end
    local times = #self._OpenItemBoxs
    for _, itemBoxData in pairs(self._OpenItemBoxs) do
        XMVCA.XTheatre5.PVEAgency:RequestItemBoxOpen(itemBoxData.Theatre5Item.InstanceId, function(success,res)
            if not success then
                return
            end
            if res.OpenType == XMVCA.XTheatre5.EnumConst.ItemBoxOpenType.All and res.ItemBoxSelectData then
                for _, theatre5Item in pairs(res.ItemBoxSelectData) do
                    table.insert(self._RewardList, {Id = theatre5Item.ItemId, Type = theatre5Item.ItemType, 
                    Count = 1, IsFirst = itemBoxData.IsFirst}) 
                end
            end    
            times = times - 1
            if times <= 0 then
                self:ShowRewards()
            end     
        end)     
    end    
end

--展示奖励弹出
function XUiTheatre5PVEEvent:ShowRewards()
    if XTool.IsTableEmpty(self._RewardList) then
        self:ShowClue()
        return
    end
    XLuaUiManager.Open("UiTheatre5PopupGetReward", nil, self._RewardList, function()
        self:ShowClue()
    end)  
end

--展示线索弹窗
function XUiTheatre5PVEEvent:ShowClue()
    if not XTool.IsNumberValid(self._ClueId) then
        self:ShowItemBoxSelect()
        return
    end
    XLuaUiManager.Open("UiTheatre5PVEPopupClueDetail", self._ClueId, function()
        self:ShowItemBoxSelect()
    end)    
end

--展示三选一
function XUiTheatre5PVEEvent:ShowItemBoxSelect()
    local itemBoxSelectData = self._Control.PVEControl:GetItemBoxSelectData()
    if XTool.IsTableEmpty(itemBoxSelectData) then
        self:ExcuteNext()
        return
    end
    if self._ChapterBattlePromoteCb then
        self._ChapterBattlePromoteCb(XMVCA.XTheatre5.EnumConst.PVENodeType.ItemBoxSelect)
    end    
end

function XUiTheatre5PVEEvent:ExcuteNext()
    if not XTool.IsNumberValid(self._NextEventId) then --事件执行完成
        local chapterBattleData = self._Control.PVEControl:GetCurChapterBattleData()
        if self._ChapterBattlePromoteCb then
            XLuaUiManager.Open("UiBlackScreen", nil, nil, nil, nil, 1)
            self._ChapterBattlePromoteCb(XMVCA.XTheatre5.EnumConst.PVENodeType.Battle, chapterBattleData)
        end    
        return
    end
    self:RefreshAll(self._NextEventId)    
end

function XUiTheatre5PVEEvent:OnClickClose()
    self._Control:ReturnTheatre5Main()
end

function XUiTheatre5PVEEvent:OnClickBag()
    XLuaUiManager.Open("UiTheatre5PVECheckCharacter")
end

function XUiTheatre5PVEEvent:OnDestroy()
    self:RemoveEventListener()
    self._PVEEventChat = nil
    self._PVEEventOption = nil
    self._RewardList = nil
    self._OpenItemBoxs = nil
    self._ClueId = nil
    self._NextEventId = nil
    self._ChapterBattlePromoteCb = nil
end

return XUiTheatre5PVEEvent