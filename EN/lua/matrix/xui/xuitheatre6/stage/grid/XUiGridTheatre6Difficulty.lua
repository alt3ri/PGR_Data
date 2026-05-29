local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")

---@class XUiGridTheatre6Difficulty : XUiNode 难度选项
---@field Parent XUiTheatre6ChooseDifficulty
---@field _Control XTheatre6Control
---@field _Drag XUiPanelTheatre6Drag
local XUiGridTheatre6Difficulty = XClass(XUiNode, "XUiGridTheatre6Difficulty")

function XUiGridTheatre6Difficulty:OnStart()
    self.UiTxtDes.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

function XUiGridTheatre6Difficulty:Refresh(difficultyId)
    self._Difficulty = self._Control:GetDifficultyConfig(difficultyId)
    self.TxtName.text = self._Difficulty.Name
    self.UiTxtDes.text = XUiHelper.ReplaceTextNewLine(self._Difficulty.Des)

    local ret, desc = true, ""
    if XTool.IsNumberValid(self._Difficulty.ConditionId) then
        ret, desc = XConditionManager.CheckCondition(self._Difficulty.ConditionId)
    end

    self.UiTxtLock.gameObject:SetActiveEx(not ret)
    self.UiTxtLock.text = desc
    self.RImgLevel:SetRawImage(self._Control:GetClientConfigValue("DifficultyLevelBg", self._Difficulty.HardNum))
end

return XUiGridTheatre6Difficulty
