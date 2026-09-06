local XUiPunishaarFightMainGridBuff = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarFightMainGridBuff")

---@class XUiPunishaarFightMainPanelMainHp : XUiNode
---@field _Control XPunishaarControl
---@field CurHp UnityEngine.UI.Image
---@field RImgHead UnityEngine.UI.RawImage
---@field GroupBuff UnityEngine.RectTransform
---@field GridBuff UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field TxtHpNum UnityEngine.UI.Text 血量数值（当前值/最大值，ClientConfig 插值字符串）#70
---@field ShieldBuff XUiPunishaarFightMainGridBuff
local XUiPunishaarFightMainPanelMainHp = XClass(XUiNode, "XUiPunishaarFightMainPanelMainHp")

function XUiPunishaarFightMainPanelMainHp:InitComponents()
    -- GroupBuff 可能被上一次战斗的 RefreshShield(0) 置为 inactive，必须先还原；
    -- 真正的显隐由 RefreshShield 在 RefreshAll 阶段决定。
    if self.GroupBuff then
        self.GroupBuff.gameObject:SetActiveEx(true)
    end
    if self.GridBuff then
        ---@type XUiPunishaarFightMainGridBuff
        self.ShieldBuff = XUiPunishaarFightMainGridBuff.New(self.GridBuff, self)
        self.ShieldBuff:Open()
    end
end

function XUiPunishaarFightMainPanelMainHp:OnStart(...)
    self:InitComponents()
end

function XUiPunishaarFightMainPanelMainHp:OnEnable()
end

function XUiPunishaarFightMainPanelMainHp:OnDisable()
end

function XUiPunishaarFightMainPanelMainHp:OnDestroy()
end

function XUiPunishaarFightMainPanelMainHp:RefreshHpShow(curHp, hpMax)
    local percent = hpMax == 0 and 0 or curHp / hpMax
    self.CurHp.fillAmount = percent
    -- 血量数值：当前值/最大值，ClientConfig 插值字符串 #70
    if self.TxtHpNum then
        local fmt = XMVCA.XPunishaar:GetClientStringByKey("PunishaarHpShowFormat")
        if not string.IsNilOrEmpty(fmt) then
            self.TxtHpNum.text = XUiHelper.FormatTextEx(fmt, tostring(math.floor(curHp)), tostring(math.floor(hpMax)))  -- 血量向下取整 #4.8
        elseif not self._HpFmtWarned then
            self._HpFmtWarned = true  -- 首次守卫防每帧刷屏
            XLog.Error("[Punishaar] ClientConfig key 'PunishaarHpShowFormat' 未配置，请补上血量显示插值字符串 #70")
        end
    end
end

---@param shieldCount number 护盾数量（NoHurtTimes）
function XUiPunishaarFightMainPanelMainHp:RefreshShield(shieldCount)
    if not self.ShieldBuff then
        return
    end
    local show = shieldCount and shieldCount > 0

    -- 先填数据再显隐：反序会让 SetVisible(true)→Open 时 TxtLayer 还是上次的旧值，闪一帧
    if show then
        -- 玩家侧本期仍是单护盾实例，不接 buff 列表（敌人侧见 PanelEnemyHp:RefreshBuffList）；
        -- 护盾图标敌我共用同一 BuffIcons[Shield]
        self.ShieldBuff:Refresh(XMVCA.XPunishaar.EnumConst.BuffIconIndex.Shield, shieldCount)
    end
    self.ShieldBuff:SetVisible(show)
end

---@param name string
function XUiPunishaarFightMainPanelMainHp:SetName(name)
    if self.TxtName then
        self.TxtName.text = name or ""
    end
end

function XUiPunishaarFightMainPanelMainHp:SetRoleImg(img)
    if not string.IsNilOrEmpty(img) then
        self.RImgHead:SetRawImage(img)
    end
end

return XUiPunishaarFightMainPanelMainHp
