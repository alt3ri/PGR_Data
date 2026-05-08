---@class XUiGridTheatre6Upgrade : XUiNode 右侧等级预览Grid
---@field _Control XTheatre6Control
local XUiGridTheatre6Upgrade = XClass(XUiNode, "XUiGridTheatre6Upgrade")

local Full = 1
local Current = 2
local Lock = 3

function XUiGridTheatre6Upgrade:OnStart()
    self._Panels = {}
    self._Panels[Full] = self.Full
    self._Panels[Current] = self.NoFull
    self._Panels[Lock] = self.Disable
end

---@param talentCfg XTableTheatre6Talent 养成配置
---@param curExp number 当前经验
function XUiGridTheatre6Upgrade:Update(talentCfg, curLv, curExp)
    self._TalentCfg = talentCfg

    local attrName = ""
    local attrNum = 0
    if talentCfg.AttrTypes and #talentCfg.AttrTypes > 0 then
        local attrCfg = self._Control:GetAttrConfig(talentCfg.AttrTypes[1])
        attrName = attrCfg.Name
        attrNum = talentCfg.AttrNums[1]
    end

    local lv = talentCfg.Level
    if curLv >= lv then
        self._Status = Full
    elseif curLv + 1 == lv then
        self._Status = Current
    else
        self._Status = Lock
    end

    for status, panel in pairs(self._Panels) do
        panel.gameObject:SetActiveEx(status == self._Status)
    end

    local panel = self._Panels[self._Status]
    local uiObject = {}
    XUiHelper.InitUiClass(uiObject, panel)
    uiObject.UiTxtLv.text = string.format("Lv.%s", talentCfg.Level)
    uiObject.UiTxtName.text = attrName
    uiObject.UiTxtNum.text = attrNum > 0 and string.format("+%s", attrNum) or attrNum
    if uiObject.ImgBar then
        local fillAmount = 0
        if self._Status == Full then
            fillAmount = 1
        elseif self._Status == Current then
            fillAmount = math.min(1, curExp / talentCfg.NextExp)
        end
        uiObject.ImgBar.fillAmount = fillAmount
    end
end

return XUiGridTheatre6Upgrade
