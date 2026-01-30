local XUiDlcMultiPlayerTitleCommon = require("XUi/XUiDlcMultiPlayer/XUiDlcMultiPlayerCommon/XUiDlcMultiPlayerTitleCommon")

---@class XUiDlcMultiPlayerLoadingItem : XUiNode
---@field Parent XUiDlcMultiPlayerLoading
---@field RImgHead UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtNum UnityEngine.UI.Text
---@field TitleGrid UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
---@field ImgSkill UnityEngine.UI.Image
---@field TxtSkillName UnityEngine.UI.Text
---@field ImgCamp UnityEngine.UI.RawImage
---@field ImgProgress UnityEngine.UI.Image
local XUiDlcMultiPlayerLoadingItem = XClass(XUiNode, "XUiDlcMultiPlayerLoadingItem")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp
-- region 生命周期

function XUiDlcMultiPlayerLoadingItem:OnStart(playerData)
    self._IsFinish = false
    self._TitleGrid = nil
    ---@type UiObject[]
    self._SkillGridList = {}

    self:_Init(playerData)
end

-- endregion

function XUiDlcMultiPlayerLoadingItem:RefreshProgress(progress)
    if progress < 100 then
        self.TxtNum.text = progress .. "%"
        self.ImgProgress.fillAmount = progress / 100.0
    else
        if not self._IsFinish then
            self.TxtNum.text = "100%"
            self.ImgProgress.fillAmount = 1.0
            self.Parent:RefreshFinishCount()
            self._IsFinish = true
        end
    end
end

-- region 私有方法

---@param playerData XDlcPlayerData
function XUiDlcMultiPlayerLoadingItem:_Init(playerData)
    local characterId = playerData:GetCharacterId()
    local icon = self._Control:GetCharacterCuteHeadIconByCharacterId(characterId)
    ---@type XDlcMultiMouseHunterPlayerData
    local customData = playerData:GetCustomData()
    local camp = playerData:GetCamp()

    -- 头像、名字、进度
    self.TxtName.text = playerData:GetNickname()
    self.TxtNum.text = "0%"
    self.ImgProgress.fillAmount = 0
    self.TxtNum.gameObject:SetActiveEx(true)
    self.ImgProgress.gameObject:SetActiveEx(true)
    self.RImgHead:SetRawImage(icon)

    -- 阵营图标
    local skillIds
    if camp == CampEnum.Cat then
        skillIds = playerData:GetCatSkillIds()
        self.ImgCamp:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("LoadingCatIcon").Values[1])
    elseif camp == CampEnum.Mouse then
        skillIds = playerData:GetMouseSkillIds()
        self.ImgCamp:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("LoadingMouseIcon").Values[1])
    end

    -- 技能图标
    if XTool.IsTableEmpty(skillIds) then
        self.PanelSkill.gameObject:SetActiveEx(false)
    else
        self.PanelSkill.gameObject:SetActiveEx(true)
        for index, skillId in ipairs(skillIds) do
            local grid = self._SkillGridList[index]
            if not grid then
                grid = index == 1 and self.GridSkill or XUiHelper.Instantiate(self.GridSkill, self.PanelSkill)
                self._SkillGridList[index] = grid
            end
            grid.gameObject:SetActiveEx(true)
            local skillConfig = self._Control:GetDlcMultiplayerSkillConfigById(skillId)
            local rawImage = grid:GetObject("ImgSkill")
            rawImage:SetRawImage(skillConfig.Icon)
            if camp == CampEnum.Cat then
                rawImage.color = XUiHelper.Hexcolor2Color("588975")
            elseif camp == CampEnum.Mouse then
                rawImage.color = XUiHelper.Hexcolor2Color("A54939")
            end
        end

        for i = #skillIds + 1, #self._SkillGridList do
            self._SkillGridList[i].gameObject:SetActiveEx(false)
        end
    end

    -- 称号
    if customData and not customData:IsClear() then
        local titleId = customData:GetTitleId()

        if XTool.IsNumberValid(titleId) then
            self._TitleGrid = XUiDlcMultiPlayerTitleCommon.New(self.TitleGrid, self, titleId)
        else
            self.TitleGrid.gameObject:SetActiveEx(false)
        end
    else
        self.TitleGrid.gameObject:SetActiveEx(false)
    end
end

-- endregion

return XUiDlcMultiPlayerLoadingItem
