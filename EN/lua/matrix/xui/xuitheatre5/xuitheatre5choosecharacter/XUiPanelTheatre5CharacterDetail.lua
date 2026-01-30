---@class XUiPanelTheatre5CharacterDetail: XUiNode
---@field private _Control XTheatre5Control
---@field Parent UiTheatre5ChooseCharacter
---@field TogStory XUiComponent.XUiButton
local XUiPanelTheatre5CharacterDetail = XClass(XUiNode, 'XUiPanelTheatre5CharacterDetail')
local XUiGridTheatre5PVPRank = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVP/XUiGridTheatre5PVPRank')

function XUiPanelTheatre5CharacterDetail:OnStart()
    -- todo 判断游戏模式，pve不初始化和刷新段位信息
    ---@type XUiGridTheatre5PVPRank
    self.PVPRank = XUiGridTheatre5PVPRank.New(self.GridDan, self)

    if self.TogStory then
        self.TogStory.CallBack = handler(self, self.OnBtnFashionClickEvent)
    end
end

---@param cfg XTableTheatre5Character
function XUiPanelTheatre5CharacterDetail:RefreshShow(cfg)
    self.Config = cfg
    
    
    local condition = nil

    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self._IsUnlock = self._Control.PVPControl:CheckHasPVPCharacterDataById(cfg.Id)
        condition = self.Config.PvpCondition
        self.TxtName.gameObject:SetActiveEx(false)
    else
        self.TxtName.gameObject:SetActiveEx(true)
        self.TxtName.text = cfg.Name
    end

    if self._IsUnlock then
        self.TxtStory.text = XUiHelper.ReplaceTextNewLine(cfg.Info)
    else
        if XTool.IsNumberValid(condition) then
            local lockDesc = XConditionManager.GetConditionDescById(condition)
            self.TxtStory.text = XUiHelper.ReplaceTextNewLine(lockDesc)
        end
    end
    
    -- 刷新标签
    self._TagList = XUiHelper.RefreshUiObjectList(self._TagList, self.ListTag, self.GridTag, self.Config.Tags and #self.Config.Tags or 0, function(index, grid)
        if grid.TxtTag then
            grid.TxtTag.text = self.Config.Tags[index]
        end
    end)
    
    -- 显示段位
    self.PVPRank:Refresh(self.Config.Id)
    
    -- 显示皮肤功能按钮
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP and self._IsUnlock then
        self.PanelFashion.gameObject:SetActiveEx(true)
        self:RefreshFashionTog()
    else
        self.PanelFashion.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre5CharacterDetail:RefreshFashionTog()
    self._HasSpecialFashion = XTool.IsNumberValid(self.Config.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Special])
    
    self.Story.gameObject:SetActiveEx(self._HasSpecialFashion)
    self.Lock.gameObject:SetActiveEx(not self._HasSpecialFashion)

    if self._HasSpecialFashion then

        local fashionId = self._Control.CharacterControl:GetFashionIdByCharacterIdInCurMode(self.Config.Id)

        self._IsShowTag = fashionId == self.Config.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Special]

        self.TogStory:ShowTag(self._IsShowTag)
    end
end

function XUiPanelTheatre5CharacterDetail:OnBtnFashionClickEvent()
    if not self._HasSpecialFashion then
        return
    end
    
    local fashionId = not self._IsShowTag and self.Config.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Special] or self.Config.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Default]
    
    XMVCA.XTheatre5:RequestTheatre5CharacterSkinSet(self.Config.Id, fashionId, function(success)
        if success then
            self:RefreshFashionTog()
            
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHARACTER_FASHION_CHANGED, self.Config)
        end
    end)
end

return XUiPanelTheatre5CharacterDetail