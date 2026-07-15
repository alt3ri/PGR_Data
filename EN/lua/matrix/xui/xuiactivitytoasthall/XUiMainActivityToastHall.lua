---@class XUiMainActivityToastHall : XLuaUi
local XUiMainActivityToastHall = XLuaUiManager.Register(XLuaUi, "UiMainActivityToastHall")
local MathLerp = CS.UnityEngine.Mathf.Lerp

local DefaultSkinId = 1
local MoveType = XEnumConst.ActivityToastHall.MoveType

function XUiMainActivityToastHall:OnStart(toastId, skinId)
    local cfg = XMVCA.XUiMain:GetActivityToastHallCfgById(toastId)
    if not cfg then
        self:Close()
        return
    end

    if not self:InitSkin(cfg, skinId) then
        self:Close()
        return
    end

    self:ShowToast(cfg)
end

---@param cfg XTableActivityToastHall
function XUiMainActivityToastHall:InitSkin(cfg, skinId)
    skinId = skinId or cfg.SkinId
    if not XTool.IsNumberValid(skinId) then
        skinId = DefaultSkinId
    end

    local skinCfg = XMVCA.XUiMain:GetActivityToastHallSkinCfgById(skinId)
    if not skinCfg then
        skinId = DefaultSkinId
        skinCfg = XMVCA.XUiMain:GetActivityToastHallSkinCfgById(DefaultSkinId)
    end

    if not skinCfg or string.IsNilOrEmpty(skinCfg.SkinPrefabUiPath) then
        XLog.Error("UiMainActivityToastHall skin config invalid, skinId = " .. tostring(skinId))
        return false
    end

    local skinGo = self.SkinRoot:LoadPrefab(skinCfg.SkinPrefabUiPath)
    if not skinGo then
        XLog.Error("UiMainActivityToastHall load skin prefab failed: " .. skinCfg.SkinPrefabUiPath)
        return false
    end

    self.SkinUi = XTool.InitUiObjectByUi({}, skinGo)
    self.SkinUi.GameObject:SetActiveEx(true)

    if not self.SkinUi.Viewport or not self.SkinUi.Content or not self.SkinUi.Txt then
        XLog.Error("UiMainActivityToastHall skin prefab need UiObject: Viewport, Content, Txt")
        return false
    end

    self._ContentDefaultPosition = self.SkinUi.Content.anchoredPosition

    return true
end

---@param cfg XTableActivityToastHall
function XUiMainActivityToastHall:ShowToast(cfg)
    self:StopTweener(self._MoveTimer)
    self:StopTweener(self._StayTimer)

    local skinUi = self.SkinUi
    skinUi.Txt.text = cfg.Content or ""

    local stayTime = cfg.TipStayTime
    if not XTool.IsNumberValid(stayTime) then
        stayTime = 0
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(skinUi.Content)

    if cfg.MoveType == MoveType.Static then
        self:ShowStaticToast(stayTime)
        return
    end

    self:ShowSliderToast(cfg, stayTime)
end

function XUiMainActivityToastHall:ShowStaticToast(stayTime)
    self.SkinUi.Content.anchoredPosition = self._ContentDefaultPosition or self.SkinUi.Content.anchoredPosition
    self:ScheduleClose(stayTime)
end

---@param cfg XTableActivityToastHall
function XUiMainActivityToastHall:ShowSliderToast(cfg, stayTime)
    local moveTime = cfg.TipMoveTime
    if not XTool.IsNumberValid(moveTime) then
        moveTime = 1
    end

    local skinUi = self.SkinUi
    local startPosX = skinUi.Viewport.rect.width + skinUi.Content.rect.width
    local endPosX = 0
    skinUi.Content.anchoredPosition = Vector2(startPosX, 0)
    self._MoveTimer = XUiHelper.Tween(moveTime, function(t)
        if not skinUi.Content:Exist() then
            return true
        end
        skinUi.Content.anchoredPosition = Vector2(MathLerp(startPosX, endPosX, t), 0)
    end, function()
        self:ScheduleClose(stayTime)
    end)
    self:_AddTimerId(self._MoveTimer)
end

function XUiMainActivityToastHall:ScheduleClose(stayTime)
    self._StayTimer = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.Remove("UiMainActivityToastHall")
        XMVCA.XUiMain:TryPopActivityToastHall()
    end, stayTime)
    self:_AddTimerId(self._StayTimer)
end

return XUiMainActivityToastHall
