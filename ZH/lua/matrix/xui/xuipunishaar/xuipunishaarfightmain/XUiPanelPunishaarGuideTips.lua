--- HUD 引导提示子面板（挂 FightMain PanelGuideTips）：显头像 + 文案 + 入场动画。
--- 生命周期：关卡内（随 FightMain 局内 UI，ExitRun 关 FightMain 时 GuideTips 跟隐；condition 调度的切走清/GameNoRepeat 登记 TODO）。
--- 显隐契约（condition 驱动部分 TODO）：给定 hudCfg 显 RImgGuideHead(HudIcon)+TxtGuide(HudDesc)+播 PnlTxtEnable 动画；无则 Hide。
--- condition 选哪条 HUD（Evaluate/CheckHudCondition 调用/组内加权选一）TODO，待 #86 Q1/Q2 确认后接入调度。
---@class XUiPanelPunishaarGuideTips: XUiNode
---@field RImgGuideHead UnityEngine.UI.RawImage 头像（PunishaarHud.HudIcon）
---@field TxtGuide UnityEngine.UI.Text 文案（PunishaarHud.HudDesc）
---@field BtnClose XUiComponent.XUiButton 关闭按钮（玩家点击关当前节点气泡，派注入的 onClose 回调）
local XUiPanelPunishaarGuideTips = XClass(XUiNode, "XUiPanelPunishaarGuideTips")

--- 显示 HUD：设头像 + 文案 + 显 + 播入场动画。
---@param hudCfg XTablePunishaarHud|nil PunishaarHud 行（HudIcon/HudDesc）；nil 则 no-op 不显
function XUiPanelPunishaarGuideTips:Show(hudCfg)
    XLog.Debug("[HudTrace][4显示] GuideTips:Show cfg Id=" .. tostring(hudCfg and hudCfg.Id))
    if not hudCfg then
        return
    end
    if self.RImgGuideHead and not string.IsNilOrEmpty(hudCfg.HudIcon) then
        self.RImgGuideHead:SetRawImage(hudCfg.HudIcon)
    end
    if self.TxtGuide then
        self.TxtGuide.text = hudCfg.HudDesc or ""
    end
    self:Open()
    -- 显示播入场动画 PnlTxtEnable（prefab 子节点 PnlTxt 的 Enable 动画）#86
    self:PlayAnimation("PnlTxtEnable")
end

--- 隐藏 HUD。
function XUiPanelPunishaarGuideTips:Hide()
    XLog.Debug("[HudTrace][4显示] GuideTips:Hide")
    self:Close()
end

--- 注入关闭回调（FightMain 初始化时设，转发 _DismissGuideTips：标 DismissHud + Hide）。
---@param callback function
function XUiPanelPunishaarGuideTips:SetOnClose(callback)
    self._OnCloseCallback = callback
end

function XUiPanelPunishaarGuideTips:OnStart()
    -- 绑 BtnClose（首次 Open 激活时绑一次；点击派注入回调，父管 DismissHud+Hide，子不直调父）
    if self.BtnClose then
        self.BtnClose:AddEventListener(handler(self, self._OnBtnCloseClick))
    end
end

--- 玩家点 BtnClose：派注入的 onClose 回调（父 _DismissGuideTips 管 DismissHud 标关 + Hide）。
function XUiPanelPunishaarGuideTips:_OnBtnCloseClick()
    if self._OnCloseCallback then
        self._OnCloseCallback()
    end
end

return XUiPanelPunishaarGuideTips
