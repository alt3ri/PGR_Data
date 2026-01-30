--- 章节主界面事件节点
---@class XUiTheatre5PVEEventChat: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEEventChat = XClass(XUiNode, 'XUiTheatre5PVEEventChat')
local XUiTheatre5GetPVERewardItem = require("XUi/XUiTheatre5/XUiTheatre5PopupGetReward/XUiTheatre5GetPVERewardItem")
function XUiTheatre5PVEEventChat:OnStart()
    self._CurEventId = nil
    self._ItemGridList = {}
    XUiHelper.RegisterClickEvent(self, self.BtnSure, self.OnClickConfirm, true, true, 0.5) 
    
    self.TxtList = self.TxtList or XUiHelper.TryGetComponent(self.Transform, "TxtList", "RectTransform")
    self.TxtListNoReward = self.TxtListNoReward or XUiHelper.TryGetComponent(self.Transform, "TxtListNoReward", "RectTransform")
end

function XUiTheatre5PVEEventChat:UpdateData(eventCfg)
    if not eventCfg then
        return
    end
    self._CurEventId = eventCfg.Id
    self.BtnSure:SetName(eventCfg.ConfirmContent)
    if self:UpdateReward(eventCfg) then
        self.TxtContent.text = XUiHelper.ReplaceTextNewLine(eventCfg.Desc)
        self.TxtContent.gameObject:SetActiveEx(true)
        self.TxtDesc.gameObject:SetActiveEx(false)
        if self.TxtList then
            self.TxtList.gameObject:SetActiveEx(true)
        end
        if self.TxtListNoReward then
            self.TxtListNoReward.gameObject:SetActiveEx(false)
        end
    else
        self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(eventCfg.Desc)
        self.TxtDesc.gameObject:SetActiveEx(true)
        self.TxtContent.gameObject:SetActiveEx(false)
        if self.TxtList then
            self.TxtList.gameObject:SetActiveEx(false)
        end
        if self.TxtListNoReward then
            self.TxtListNoReward.gameObject:SetActiveEx(true)
        end
    end
end

function XUiTheatre5PVEEventChat:UpdateReward(eventCfg)
    local curChapterData = self._Control.PVEControl:GetCurChapterBattleData()
    local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(curChapterData.ChapterId)
    local chapterLevelCfg = self._Control.PVEControl:GetChapterLevelCfg(chapterCfg.LevelGroup ,curChapterData.CurPveChapterLevel.Level) 
    local hasReward = XTool.IsNumberValid(eventCfg.EventLevelGroup) and XTool.IsNumberValid(chapterLevelCfg.EventLevel)
    self.NodeReward.gameObject:SetActiveEx(hasReward)       
    if not hasReward then
        XTool.UpdateDynamicItem(self._ItemGridList, {}, self.GridTheatre5Item, XUiTheatre5GetPVERewardItem, self)
        return false
    end
    local eventLevelCfgs = self._Control.PVEControl:GetPveEventLevelCfgs(eventCfg.EventLevelGroup)
    local eventLevelCfg
    for _, cfg in pairs(eventLevelCfgs) do
        if cfg.EventLevel == chapterLevelCfg.EventLevel then
            eventLevelCfg = cfg
            break
        end    
    end
    if not eventLevelCfg then
        return false
    end    
    --拿到验证是否双倍奖励事件id
    local doubleEventId,isDouble
    if not XTool.IsTableEmpty(curChapterData.CurPveChapterLevel.RunEvents) then --有执行的事件时执行链最后一个事件是验证事件id
        doubleEventId = curChapterData.CurPveChapterLevel.RunEvents[#curChapterData.CurPveChapterLevel.RunEvents]
    else
        doubleEventId = eventCfg.Id  --没有执行的事件那么当前事件是验证事件id
    end
   
    local isDouble = true
    local finishEvents = self._Control.PVEControl:GetHistoryFinishEvents(curChapterData.ChapterId)
    if not XTool.IsTableEmpty(finishEvents) then
        for _, eventId in pairs(finishEvents) do
            if eventId == doubleEventId then
                isDouble = false
                break
            end     
        end
    end
    local itemList = {}
    if not XTool.IsTableEmpty(eventLevelCfg.ItemType) then
        for i = 1, #eventLevelCfg.ItemType do
            table.insert(itemList, {Id = eventLevelCfg.ItemId[i], Type = eventLevelCfg.ItemType[i], Count = eventLevelCfg.ItemCount[i]})
        end
    end
    if isDouble then
        if not XTool.IsTableEmpty(eventLevelCfg.BonusItemTypes) then
            for i = 1, #eventLevelCfg.BonusItemTypes do
                table.insert(itemList, {Id = eventLevelCfg.BonusItemIds[i], Type = eventLevelCfg.BonusItemTypes[i], 
                Count = eventLevelCfg.BonusItemCounts[i], IsFirst = true})
            end
        end
    end        
    if not XTool.IsTableEmpty(itemList) then
        XTool.UpdateDynamicItem(self._ItemGridList, itemList, self.GridTheatre5Item, XUiTheatre5GetPVERewardItem, self)
    end     
    return true
end

function XUiTheatre5PVEEventChat:OnClickConfirm()
    if not XTool.IsNumberValid(self._CurEventId) then
        return
    end    
    XMVCA.XTheatre5.PVEAgency:RequestPveEventPromote(self._CurEventId)
    self._CurEventId = nil  --点击后清空防止弹窗关闭了快速连点
end

function XUiTheatre5PVEEventChat:OnDestroy()
    self._CurEventId = nil
    self._ItemGridList = nil
end

return XUiTheatre5PVEEventChat