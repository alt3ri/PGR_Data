---@class XUiBountyChallengeChapterDetailDifficulty : XUiNode
---@field _Control XBountyChallengeControl
local XUiBountyChallengeChapterDetailDifficulty = XClass(XUiNode, "XUiBountyChallengeChapterDetailDifficulty")

function XUiBountyChallengeChapterDetailDifficulty:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
    self._Star = {}
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
    if data.IsOpen then
        if data.IsSelected then
            self.Button:SetButtonState(CS.UiButtonState.Select)
        else
            self.Button:SetButtonState(CS.UiButtonState.Normal)
        end
        if data.IsMaxLevel then
            self.Normal1.gameObject:SetActive(false)
            self.Normal2.gameObject:SetActive(true)
            self.Select1.gameObject:SetActive(false)
            self.Select2.gameObject:SetActive(true)
        else
            self.Normal1.gameObject:SetActive(true)
            self.Normal2.gameObject:SetActive(false)
            self.Select1.gameObject:SetActive(true)
            self.Select2.gameObject:SetActive(false)
        end
    else
        self.TextLock.text = data.LockReason
        self.Button:SetButtonState(CS.UiButtonState.Disable)
    end

    -- 为什么有4种？因为普通和select有2种，难度maxLevel有2种, 2*2=4，所以有4种ui形态
    for i = 1, 4 do
        local clear = self["Clear" .. i]
        local name = self["Name" .. i]
        local slider = self["Slider" .. i]
        local star = self["Star" .. i]
        if data.IsClear then
            clear.gameObject:SetActiveEx(true)
        else
            clear.gameObject:SetActiveEx(false)
        end
        name.text = data.Name
        slider.value = data.TaskProgress / data.TaskProgressMax

        -- 星星(难度条)
        local starArray = self._Star[i]
        if not starArray then
            starArray = { star }
            self._Star[i] = starArray
        end
        local level = data.Level
        for j = 1, level do
            local grid = starArray[j]
            if not grid then
                grid = XUiHelper.Instantiate(star, star.transform.parent)
                starArray[#starArray + 1] = grid
            end
            grid.gameObject:SetActiveEx(true)
        end
        for j = level + 1, #starArray do
            local grid = starArray[j]
            grid.gameObject:SetActiveEx(false)
        end
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