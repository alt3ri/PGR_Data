local XUiPBRCharacterDetail = require('XUi/XUiPBRGame/XUiPBRCharacterDetail/XUiPBRCharacterDetail')

--- 进关卡前的角色选择界面，预制体用的是 UiPBRCharacterDetail
---@class XUiPBRCharacterSelection: XUiPBRCharacterDetail
---@field protected _Control XPBRGameControl
local XUiPBRCharacterSelection = XLuaUiManager.Register(XUiPBRCharacterDetail, "UiPBRCharacterSelection")

function XUiPBRCharacterSelection:OnStart(stageId)
    self.CurStageId = stageId

    local stageCfg = self._Control:GetStageCfgById(stageId)

    -- 如果有推荐角色，选择推荐角色，否则选择顺位第一个
    if XTool.IsNumberValidEx(stageCfg.RecommendChar) then
        self.PanelPick:ShowAndSelectRecommendChar(stageCfg.RecommendChar)
    else
        self.PanelPick:SelectByIndex(1)
    end
end

function XUiPBRCharacterSelection:InitComponents()
    -- 父类方法
    XUiPBRCharacterDetail.InitComponents(self)
    self.BtnEnterB.gameObject:SetActiveEx(true)
    self.BtnEnterB:AddEventListener(function() self:OnBtnEnterBClick() end)
    
    -- 选关界面需要开放天赋入口
    if self.BtnGenius then
        self.BtnGenius.gameObject:SetActiveEx(true)
        self.BtnGenius:AddEventListener(function() self:OnBtnGeniusClick() end)
    end
end

function XUiPBRCharacterSelection:OnEnable()
    XUiPBRCharacterDetail.OnEnable(self)
    self:RefreshReddot()

    if XTool.IsNumberValidEx(self.CurCharacterId) then
        local charCfg = self._Control.CharacterControl:GetCharacterCfg(self.CurCharacterId)

        if charCfg then
            self.PanelAttribute:RefreshStatusShow(charCfg.CharacterId)
            self.PanelExclusive:RefreshCharacterExclusiveDesc(charCfg.CharacterId)
        end
    end
end

---@overload
function XUiPBRCharacterSelection:GetCharacterListCls()
    return require('XUi/XUiPBRGame/XUiPBRCharacterSelection/XUiPBRCharacterSelectionPanelPick')
end


function XUiPBRCharacterSelection:OnBtnEnterBClick()
    local customCharId = self._Control.InGameControl:GetCurSelectCharId()

    if self._Control.CharacterControl:GetIsCharacterUnlock(customCharId) then
        self._Control.InGameControl:SetSegmentSettleDataCacheInBegin(self.CurStageId, customCharId)
        self:Close()
        XMVCA.XFuben:EnterFightByStageId(self.CurStageId, nil, false, 1, nil)
    else
        XUiManager.TipMsg(self._Control:GetClientPBRText('StageEnterFailWithLockChar'))
    end
end

function XUiPBRCharacterSelection:OnBtnGeniusClick()
    XLuaUiManager.Open('UiPBRGenius')
end

function XUiPBRCharacterSelection:RefreshReddot()
    if self.BtnGenius then
        self.BtnGenius:ShowReddot(XMVCA.XPBRGame:ReddotIsAnyGeniusNodeCanUnlock())
    end
end



return XUiPBRCharacterSelection