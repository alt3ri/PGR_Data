---@class XUiBountyChallengeChapterDetailDifficulty : XUiNode
---@field _Control XBountyChallengeControl
---@field StateCtrl XUiComponent.XUiStateControl
local XUiBountyChallengeChapterDetailDifficulty = XClass(XUiNode, "XUiBountyChallengeChapterDetailDifficulty")

function XUiBountyChallengeChapterDetailDifficulty:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
    self.IsAdd2ButtonGroup = false
end

---@param data XUiBountyChallengeChapterDetailDifficultyData
function XUiBountyChallengeChapterDetailDifficulty:Update(data)
    if self._Data then
        if self._Data.IsSelected and not data.IsSelected then
            self:PlayAnimation("NormalEnable")
            self:StopAnimation("SelectEnable")
        elseif not self._Data.IsSelected and data.IsSelected then
            self:StopAnimation("NormalEnable")
            self:PlayAnimation("SelectEnable")
        end
    end

    self._Data = data

    local csharpIndex = data.Level - 1
    
    if data.IsOpen then
        if data.IsSelected then
            self.Button:SetButtonState(CS.UiButtonState.Select)
        else
            self.Button:SetButtonState(CS.UiButtonState.Normal)
        end
        
        self.Button:SetNameByGroup(csharpIndex, data.Name)
    else
        --4.1 锁定状态仍然显示名称
        self.Button:SetNameByGroup(csharpIndex, data.Name)
        --self.Button:SetNameByGroup(csharpIndex, data.LockReason)
        self.Button:SetButtonState(CS.UiButtonState.Disable)
    end

    if self.StateCtrl then
        self.StateCtrl:ChangeState('State'..tostring(data.Level))
    end
end

function XUiBountyChallengeChapterDetailDifficulty:OnClick()
    if self._Data.IsOpen then
        self._Control:SetDifficultyLevel(self._Data.Level)
        -- 切换之后, 动画改为同步播放
        self._Control:SetPlayAnimationSync()
        self.Parent:Update()
        self.Parent:SetLine(self._Data.Level)
    else
        XUiManager.TipMsg(self._Data.LockReason)
    end
end

return XUiBountyChallengeChapterDetailDifficulty