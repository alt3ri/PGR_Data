---@class XUiGridEnhanceProgressUnit : XUiNode
---@field Parent XUiEquipEnhanceProgressPopup
---@field DefaultDoneText string 完成状态默认文案
---@field Data XUiGridEnhanceProgressUnitData
---@field ImgBreakIcon UnityEngine.UI.Image 突破档图标（升级单元用）
local XUiGridEnhanceProgressUnit = XClass(XUiNode, "XUiGridEnhanceProgressUnit")
local XUiCultureStarGroup = require("XUi/XUiRole/XUiRoleCulture/XUiCultureStarGroup")

local STATUS = {
    Waiting = 1,
    Processing = 2,
    Done = 3,
}
XUiGridEnhanceProgressUnit.STATUS = STATUS

local CsTween = CS.DG.Tweening
local ROTATE_VEC3 = CS.UnityEngine.Vector3(0, 0, -360)
local ROTATE_DURATION = 1.2

function XUiGridEnhanceProgressUnit:OnStart()
    self.StarGroup = XUiCultureStarGroup.New(self.Parent, self)
    self.DefaultDoneText = self.UiTxtDone.text
end

--- data = { Key, Name, Target, CharacterId, GradeValue }
--- 晋升模块用星级展示，其余模块用文字目标
---@class XUiGridEnhanceProgressUnitData
---@field Key string
---@field Name string
---@field Target string
---@field CharacterId number|nil
---@field GradeValue number|nil
---@field ProcessingTextKey string|nil 自定义进行中文本 Key，首个格式化参数为当前进度
---@param data XUiGridEnhanceProgressUnitData
function XUiGridEnhanceProgressUnit:Update(data)
    self.Data = data
    self.UiTxtUnitName.text = data.Name

    if self.ImgBreakIcon then
        local hasIcon = data.BreakIcon and data.BreakIcon ~= ""
        self.ImgBreakIcon.gameObject:SetActiveEx(hasIcon == true)
        if hasIcon then
            self.Parent:SetUiSprite(self.ImgBreakIcon, data.BreakIcon)
        end
    end
    local isGrade = data.Key == "Grade"
    self.UiTxtPreview.gameObject:SetActiveEx(not isGrade)
    self.PanelStarGoup.gameObject:SetActiveEx(isGrade)
    if isGrade then
        self.StarGroup:Refresh(data.CharacterId, data.GradeValue)
    else
        self.UiTxtPreview.text = data.Target
    end

    self:SetStatus(STATUS.Waiting)
end

---@param status number
---@param progressCur number|nil
---@param progressTotal number|nil
function XUiGridEnhanceProgressUnit:SetStatus(status, progressCur, progressTotal)
    self.Status = status
    self.BgItemWaiting.gameObject:SetActiveEx(status == STATUS.Waiting)
    self.BgItemProcessing.gameObject:SetActiveEx(status == STATUS.Processing)
    self.BgItemDone.gameObject:SetActiveEx(status == STATUS.Done)

    self.PanelStatusWaiting.gameObject:SetActiveEx(status == STATUS.Waiting)
    self.PanelStatusProcessing.gameObject:SetActiveEx(status == STATUS.Processing)
    self.PanelStatusDone.gameObject:SetActiveEx(status == STATUS.Done)

    if status == STATUS.Processing then
        if self.Data.ProcessingTextKey then
            self.UiTxtProcessing.text = CS.XTextManager.GetText(self.Data.ProcessingTextKey, progressCur)
        elseif progressCur and progressTotal then
            self.UiTxtProcessing.text = CS.XTextManager.GetText("RoleCultureUnitProcessingProgress", progressCur, progressTotal)
        else
            self.UiTxtProcessing.text = CS.XTextManager.GetText("RoleCultureUnitProcessing")
        end
        self:StartRotate()
    elseif status == STATUS.Waiting then
        self.UiTxtWaiting.text = CS.XTextManager.GetText("RoleCultureUnitWaiting")
        self:StopRotate()
    else
        local isPartiallyDone = progressCur and progressTotal and progressCur < progressTotal
        if isPartiallyDone then
            self.UiTxtDone.text = CS.XTextManager.GetText("RoleCultureUnitPartiallyDone", progressCur, progressTotal)
        else
            self.UiTxtDone.text = self.DefaultDoneText
        end
        self:StopRotate()
    end
end

function XUiGridEnhanceProgressUnit:StartRotate()
    if self.RotateTween then
        return
    end
    self.RotateTween = self.IconProcessing.transform:DOLocalRotate(
        ROTATE_VEC3, ROTATE_DURATION, CsTween.RotateMode.LocalAxisAdd
    ):SetEase(CsTween.Ease.Linear):SetLoops(-1, CsTween.LoopType.Restart)
end

function XUiGridEnhanceProgressUnit:StopRotate()
    if self.RotateTween then
        self.RotateTween:Kill()
        self.RotateTween = nil
    end
end

function XUiGridEnhanceProgressUnit:OnDisable()
    self:StopRotate()
end

function XUiGridEnhanceProgressUnit:OnDestroy()
    self:StopRotate()
end

return XUiGridEnhanceProgressUnit
