local XUiPunishaarFightMainGridBuff = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarFightMainGridBuff")

---@class XUiPunishaarFightMainPanelMainHp : XUiNode
---@field _Control XPunishaarControl
---@field CurHp UnityEngine.UI.Image
---@field NextHp UnityEngine.UI.Image 下一拍血条（插值追 CurHp.fillAmount，扣血时延迟缩减形成"掉血尾巴"效果）
---@field NextHpFlash UnityEngine.GameObject 扣血闪光（关再开重播，随震动一起触发）
---@field FxObj UnityEngine.GameObject 扣血特效（关再开重播，定位到 CurHp 填充边界）
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
    -- 扣血特效默认隐藏（防界面打开时错误激发）
    if self.FxObj then
        self.FxObj.gameObject:SetActiveEx(false)
    end

    self._ShakeStrengthVec3 = CS.UnityEngine.Vector3(0, 0, 0)
end

function XUiPunishaarFightMainPanelMainHp:OnStart(...)
    self:InitComponents()
end

function XUiPunishaarFightMainPanelMainHp:OnEnable()
end

function XUiPunishaarFightMainPanelMainHp:OnDisable()
    self:_KillHpTweens()
end

function XUiPunishaarFightMainPanelMainHp:OnDestroy()
    self:_KillHpTweens()
end

--- Kill 所有 HP 相关 tween（震动 + NextHp 追赶），防面板切走/销毁后 tween 持续驱动已失效 transform
function XUiPunishaarFightMainPanelMainHp:_KillHpTweens()
    if self._HpShakeTweener then
        self._HpShakeTweener:Kill()
        self._HpShakeTweener = nil
    end
    if self._NextHpTweener then
        self._NextHpTweener:Kill()
        self._NextHpTweener = nil
    end
end

function XUiPunishaarFightMainPanelMainHp:RefreshHpShow(curHp, hpMax)
    local percent = hpMax == 0 and 0 or curHp / hpMax
    local oldPercent = self.CurHp.fillAmount
    self.CurHp.fillAmount = percent
    -- 扣血震动 + 闪光 + NextHp 追赶：percent < oldPercent = 扣血落地（回血/初始不震）
    if percent < oldPercent then
        -- 扣血闪光（PlayAnimation 重播）
        if self.NextHpFlash then
            self:PlayAnimation("NextHpFlash")
        end
        -- 扣血特效（定位到 CurHp 填充边界，关再开重播）
        if self.FxObj then
            local width = self:_GetHpBarWidth()
            self.FxObj.transform:SetAnchoredPositionX(width * percent)
            self.FxObj.gameObject:SetActiveEx(false)
            self.FxObj.gameObject:SetActiveEx(true)
        end
        local duration = XMVCA.XPunishaar:GetClientNumberByKey("HpShakeDuration", 1)
        local sx = XMVCA.XPunishaar:GetClientNumberByKey("HpShakeStrength", 1)
        local sy = XMVCA.XPunishaar:GetClientNumberByKey("HpShakeStrength", 2)
        if duration and duration > 0 and sx and sy then
            if not self._CacheHpRootPos then
                self._CacheHpRootPos = true
                self._HpRootDefaultPosX, self._HpRootDefaultPosY, self._HpRootDefaultPosZ = self.CurHp.transform.parent:GetPosition()
            end
            
            -- 倍速缩放：震动时长随倍速缩短（2x → duration/2），与战斗节奏同步
            local fc = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
            local speed = fc and fc.SpeedController and fc.SpeedController:GetSpeed() or 1
            if speed <= 0 then speed = 1 end
            duration = duration / speed
            
            if self._HpShakeTweener then
                self._HpShakeTweener:Kill()
                self.CurHp.transform.parent:SetPosition(self._HpRootDefaultPosX, self._HpRootDefaultPosY, self._HpRootDefaultPosZ)
            end
            
            self._ShakeStrengthVec3:Set(sx, sy, 0)
            self._HpShakeTweener = self.CurHp.transform.parent:DOShakePosition(duration, self._ShakeStrengthVec3)
        end
    end
    -- NextHp 插值追赶 CurHp：定时动画追到目标 fillAmount，相差无几则不赋值
    if self.NextHp then
        local nextPercent = self.NextHp.fillAmount
        local diff = nextPercent - percent
        if diff > 0.001 then
            -- 扣血时 NextHp 高于 CurHp（"掉血尾巴"），延迟缩减
            local nextDuration = XMVCA.XPunishaar:GetClientNumberByKey("HpShakeDuration", 1)
            if nextDuration and nextDuration > 0 then
                local fc2 = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
                local speed2 = fc2 and fc2.SpeedController and fc2.SpeedController:GetSpeed() or 1
                if speed2 <= 0 then speed2 = 1 end
                nextDuration = nextDuration / speed2
                if self._NextHpTweener then
                    self._NextHpTweener:Kill()
                end
                self._NextHpTweener = self.NextHp:DOFillAmount(percent, nextDuration)
            else
                self.NextHp.fillAmount = percent
            end
        elseif diff < -0.001 then
            -- 回血时 NextHp 低于 CurHp，立即追上（回血无尾巴）
            self.NextHp.fillAmount = percent
        end
    end
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

--- 取血条宽度（缓存，prefab 尺寸固定）
function XUiPunishaarFightMainPanelMainHp:_GetHpBarWidth()
    if not self._HpBarWidth then
        self._HpBarWidth = self.CurHp and self.CurHp.rectTransform.rect.width or 0
    end
    return self._HpBarWidth
end
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
