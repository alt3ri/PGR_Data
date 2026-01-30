--- 章节主界面关卡节点
---@class XUiTheatre5PVEChapterLevelItem: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEChapterLevelItem = XClass(XUiNode, 'XUiTheatre5PVEChapterLevelItem')


function XUiTheatre5PVEChapterLevelItem:Update(chapterLevelCfg, levelState, index)
    local curChapterData = self._Control.PVEControl:GetCurChapterBattleData()
    local passName = ""
    --通关的关卡名字用选择的第一个事件的名字
    if not XTool.IsTableEmpty(curChapterData.HandleEvents) then
        local curIndex = 1 --通关了却没记录默认取第一个
        if XTool.IsNumberValid(curChapterData.HandleEvents[index]) then
            curIndex = index
        end    
        local eventCfg = self._Control.PVEControl:GetPVEEventCfg(curChapterData.HandleEvents[curIndex])
        passName = eventCfg.Name
    end
    self.TxtTitle.text = passName   
    self.TxtLockTitle.text = self._Control:GetClientConfigPveChapterLevelLockText()
    self.TxtNowTitle.text = self._Control:GetClientConfigPveChapterLevelLockText()
    self.Lock.gameObject:SetActiveEx(levelState == XMVCA.XTheatre5.EnumConst.PVEChapterLevelState.Lock)
    self.Now.gameObject:SetActiveEx(levelState == XMVCA.XTheatre5.EnumConst.PVEChapterLevelState.Running)
    self.Complete.gameObject:SetActiveEx(levelState == XMVCA.XTheatre5.EnumConst.PVEChapterLevelState.Completed)
end

return XUiTheatre5PVEChapterLevelItem