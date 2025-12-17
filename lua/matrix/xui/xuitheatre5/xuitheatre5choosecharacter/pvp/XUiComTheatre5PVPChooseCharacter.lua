local XUiComTheatre5ChooseCharacter = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiComTheatre5ChooseCharacter')

---@class XUiComTheatre5PVPChooseCharacter: XUiComTheatre5ChooseCharacter
local XUiComTheatre5PVPChooseCharacter = XClass(XUiComTheatre5ChooseCharacter, 'XUiComTheatre5PVPChooseCharacter')

function XUiComTheatre5PVPChooseCharacter:OnStart()
    self._StartRun = true
    self._Control.PVPControl:StartPVPTimer()
end

function XUiComTheatre5PVPChooseCharacter:OnEnable()
    if self._StartRun then
        self._StartRun = false
    else
        if self:CheckIsShowDetail() then
            self:PlayAnimation('Enable')
        end
        
        self.Model3D:RefreshAllCharacterAnimation()
    end
end

function XUiComTheatre5PVPChooseCharacter:OnDestroy()
    self._Control.PVPControl:StopPVPTimer()
end

---@overload
function XUiComTheatre5PVPChooseCharacter:_InitButtons()
    self.BtnRank.gameObject:SetActiveEx(true)
    
    self.BtnRank:AddEventListener(handler(self, self.OnBtnRankClickEvent))
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClickEvent))
end

---@overload
--- 刷新右侧角色详情
function XUiComTheatre5PVPChooseCharacter:RefreshDetailShow(index, cfg)
    XUiComTheatre5ChooseCharacter.RefreshDetailShow(self, index, cfg)
    
    self._CurCharacterIsUnLock = self._Control.PVPControl:CheckHasPVPCharacterDataById(cfg.Id)
    if XTool.IsNumberValid(cfg.PvpCondition) then
        self._LockDesc = XConditionManager.GetConditionDescById(cfg.PvpCondition)
    end
    
    self.BtnStart:SetButtonState(self._CurCharacterIsUnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

--region 事件回调

function XUiComTheatre5PVPChooseCharacter:OnBtnRankClickEvent()
    XMVCA.XTheatre5.PVPCom:RequestTheatre5QueryRank(0, function(success, data)
        if success then
            XLuaUiManager.Open('UiTheatre5PVPRank', data)
        end
    end)
end

function XUiComTheatre5PVPChooseCharacter:OnBtnStartClickEvent()
    if not self._CurCharacterIsUnLock then
        if not string.IsNilOrEmpty(self._LockDesc) then
            XUiManager.TipMsg(self._LockDesc)
        end
        return    
    end
    
    local characterId = self.PanelCharacterList:GetCurSelectCharacterConfigId()

    if not XTool.IsNumberValid(characterId) then
        return
    end

    XMVCA.XTheatre5.PVPCom:RequestTheatre5InitGame(characterId, function(success)
        if success then
            XMVCA.XTheatre5:RequestTheatre5EnterShop(function(success)
                if success then
                    XLuaUiManager.PopThenOpen('UiTheatre5BattleShop')
                end
            end)
        end
    end)
end

--endregion

return XUiComTheatre5PVPChooseCharacter