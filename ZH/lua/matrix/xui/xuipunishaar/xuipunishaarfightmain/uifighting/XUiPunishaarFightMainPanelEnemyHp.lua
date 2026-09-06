local XUiPunishaarFightMainGridBuff = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarFightMainGridBuff")
local XUiNodeList = require("XUi/XUiCommon/XUiNodeList")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

---@class XUiPunishaarFightMainPanelEnemyHp : XUiNode
---@field _Control XPunishaarControl
---@field CurHp UnityEngine.UI.Image
---@field NextHp UnityEngine.UI.Image 下一拍血条（插值追 CurHp.fillAmount，扣血时延迟缩减形成"掉血尾巴"效果）
---@field NextHpFlash UnityEngine.GameObject 扣血闪光（关再开重播，随震动一起触发）
---@field FxObj UnityEngine.GameObject 扣血特效（关再开重播，定位到 CurHp 填充边界）
---@field RImgHead UnityEngine.UI.RawImage
---@field GroupBuff UnityEngine.RectTransform 状态图标容器（护盾 + buff 共用，恒 active）
---@field GridBuff UnityEngine.RectTransform 状态图标模板（交 _BuffList 托管，恒 inactive）
---@field TxtName UnityEngine.UI.Text
---@field TxtHpNum UnityEngine.UI.Text 血量数值（当前值/最大值，ClientConfig 插值字符串）#70
---@field GridCD UnityEngine.RectTransform 敌人CD根节点（ImgMask/RImgLight 父容器，对标卡牌 GroupInCD）#80
---@field ImgMask UnityEngine.UI.Image 敌人CD遮罩，fillAmount=剩余CD进度（自上而下填充，对标卡牌 ImgBlackMask）#80
---@field RImgLight UnityEngine.UI.RawImage 敌人CD线条，定位到遮罩当前填充边界（对标卡牌 CDLight）#80
---@field FxEnemyAttack UnityEngine.GameObject 敌人准备攻击特效（CD 到 0 激发时关再开重播）#EnemyAttack
---@field private _BuffList XUiNodeList 状态图标列表（第1项护盾 + 后续 buff）
local XUiPunishaarFightMainPanelEnemyHp = XClass(XUiNode, "XUiPunishaarFightMainPanelEnemyHp")

function XUiPunishaarFightMainPanelEnemyHp:InitComponents()
    -- GroupBuff 恒 active：显隐由列表项各自负责（Open/Close），容器不参与开关。
    if self.GroupBuff then
        self.GroupBuff.gameObject:SetActiveEx(true)
    end
    -- 逐项刷新回调绑定一次并缓存（否则每次 RefreshBuffList 都新建闭包，事件驱动的高频路径）。
    -- 不依赖任何 Unity 对象，故置于 _BuffList 的建立守卫之外。
    self._RefreshBuffGridCb = handler(self, self._OnRefreshBuffGrid)
    -- 状态图标列表：护盾与 buff 共用 GridBuff 预制，同处一个列表（护盾恒第 1 项）。
    -- GridBuff 交 XUiNodeList 托管后恒 inactive，仅作克隆源（根治特效层级二次叠层）。
    if self.GridBuff and self.GroupBuff then
        ---@type XUiNodeList
        self._BuffList = XUiNodeList.New(self.GridBuff, self.GroupBuff.transform,
                XUiPunishaarFightMainGridBuff, self)
    end
    -- 扣血特效默认隐藏（防界面打开时错误激发）
    if self.FxObj then
        self.FxObj.gameObject:SetActiveEx(false)
    end
    -- 敌人攻击特效默认隐藏（同防误激发）
    if self.FxEnemyAttack then
        self.FxEnemyAttack.gameObject:SetActiveEx(false)
    end
end

function XUiPunishaarFightMainPanelEnemyHp:OnStart()
    self:InitComponents()
    -- GridCD 常显（对标卡牌 GroupInCD），ImgMask/RImgLight 按 fillAmount/percent 控显隐 #80
    if self.GridCD then
        self.GridCD.gameObject:SetActiveEx(true)
    end
end

function XUiPunishaarFightMainPanelEnemyHp:OnEnable()
end

function XUiPunishaarFightMainPanelEnemyHp:OnDisable()
    self:_KillHpTweens()
    -- 状态图标 grid 全部 Close：本面板隐藏后 grid 若留 Open 态挂 inactive 祖先，下次 Open 时
    -- EnableChildNodes 级联 _CheckUIActive 报错（框架 Close 只对子节点调 OnDisableUi，不置
    -- _IsNodeShow=false，故必须显式 CloseAll）。对齐 PanelTopShop:CloseAllGrids。
    if self._BuffList then
        self._BuffList:CloseAll()
    end
end

function XUiPunishaarFightMainPanelEnemyHp:OnDestroy()
    self:_KillHpTweens()
end

--- Kill 所有 HP 相关 tween（震动 + NextHp 追赶），防面板切走/销毁后 tween 持续驱动已失效 transform
function XUiPunishaarFightMainPanelEnemyHp:_KillHpTweens()
    if self._HpShakeTweener then
        self._HpShakeTweener:Kill()
        self._HpShakeTweener = nil
    end
    if self._NextHpTweener then
        self._NextHpTweener:Kill()
        self._NextHpTweener = nil
    end
end

function XUiPunishaarFightMainPanelEnemyHp:RefreshHpShow(curHp, hpMax)
    local percent = hpMax == 0 and 0 or curHp / hpMax
    local oldPercent = self.CurHp.fillAmount
    self.CurHp.fillAmount = percent
    -- 扣血震动 + 闪光 + NextHp 追赶：percent < oldPercent = 扣血落地（回血/初始不震）
    if percent < oldPercent then
        -- 扣血闪光（PlayAnimation 重播）
        if self.NextHpFlash then
            self:PlayAnimation("NextHpFlash")
        end
        -- 扣血特效（定位到 CurHp 填充边界，敌方从右向左填充故 x = width * (1 - percent)）
        if self.FxObj then
            local width = self:_GetHpBarWidth()
            self.FxObj.transform:SetAnchoredPositionX(width * (1 - percent))
            self.FxObj.gameObject:SetActiveEx(false)
            self.FxObj.gameObject:SetActiveEx(true)
        end
        local duration = XMVCA.XPunishaar:GetClientNumberByKey("HpShakeDuration", 1)
        local sx = XMVCA.XPunishaar:GetClientNumberByKey("HpShakeStrength", 1)
        local sy = XMVCA.XPunishaar:GetClientNumberByKey("HpShakeStrength", 2)
        if duration and duration > 0 and sx and sy then
            -- 倍速缩放：震动时长随倍速缩短（2x → duration/2），与战斗节奏同步
            local fc = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
            local speed = fc and fc.SpeedController and fc.SpeedController:GetSpeed() or 1
            if speed <= 0 then speed = 1 end
            duration = duration / speed
            if self._HpShakeTweener then
                self._HpShakeTweener:Kill()
            end
            local strength = CS.UnityEngine.Vector3(sx, sy, 0)
            self._HpShakeTweener = self.CurHp.transform.parent:DOShakePosition(duration, strength)
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

--- 刷新敌人状态图标列表（护盾 + buff 共用 GridBuff 预制，同处一个 XUiNodeList）。
--- 顺序：护盾恒第 1 项（>0 才占位），随后 buff 按挂载顺序——BuffEntityIds 底层 PropertyList 是
--- 有序数组（PropAppend 追加末尾 / RemoveValue 走 table.remove 保序），故 FillTargetBuffIds 的
--- 输出顺序稳定，无需额外排序。
--- 只显 layer>0 的项：Layer 由 DoT buff 的 SnapshotFieldToBuff 写入，纯 modifier buff 恒 0 不显
--- （本期不接 Icon，无 Layer 的 buff 只能显个「0」无信息量）；同时兜掉 buff 销毁时序未同步的残留项。
--- 驱动：EnemyShieldChanged（护盾变）+ DotBuffLayerChanged（buff 变）双事件汇入本口。
--- 已知代价：护盾显隐会使其后 buff 整体移位（护盾与 buff 共用一列表的固有耦合）。
function XUiPunishaarFightMainPanelEnemyHp:RefreshBuffList()
    if not self._BuffList then
        return
    end
    local gameControl = self._Control and self._Control.GameControl
    local fightControl = gameControl and gameControl.FightControl
    local reader = fightControl and fightControl.STEReader
    if not reader then
        self._BuffList:Refresh(0)  -- ExitFight 后 reader 已释放，清空列表
        return
    end

    -- 显示项缓冲（成员表复用，零 per-call GC）。不截断尾部：只读前 count 项，
    -- 残留 item 留作下次复用（无别处读 #_IconBuf，故无 stale 风险）。
    self._IconBuf = self._IconBuf or {}
    local count = 0

    -- ① 护盾（非 buff）恒占第 1 项
    local shield = reader:GetEnemyShield() or 0
    if shield > 0 then
        count = count + 1
        local item = self._IconBuf[count]
        if not item then
            item = {}
            self._IconBuf[count] = item
        end
        item.IconIndex, item.Layer = XMVCA.XPunishaar.EnumConst.BuffIconIndex.Shield, shield
    end

    -- ② buff（按挂载顺序）。当前所有敌人 DoT buff 共用 EnemyDot 一张图标
    -- （Buff 表无 Icon 字段，图标按用途配在 ClientConfig.BuffIcons 下标语义）。
    local enemyId = STECustomEnum.GlobalEntityIds.Enemy
    self._BuffIdBuf = self._BuffIdBuf or {}
    local buffCount = reader:FillTargetBuffIds(enemyId, self._BuffIdBuf)
    for i = 1, buffCount do
        local buffId = self._BuffIdBuf[i]
        local layer = reader:GetDotBuffLayers(enemyId, buffId)
        if layer and layer > 0 then
            count = count + 1
            local item = self._IconBuf[count]
            if not item then
                item = {}
                self._IconBuf[count] = item
            end
            item.IconIndex, item.Layer = XMVCA.XPunishaar.EnumConst.BuffIconIndex.EnemyDot, layer
        end
    end

    self._BuffList:Refresh(count, self._RefreshBuffGridCb)
end

--- _BuffList:Refresh 的逐项刷新回调（Ctor 期经 handler 绑定一次并缓存，免每次 Refresh 新建闭包）。
---@param index number 1-based 显示序
---@param grid XUiPunishaarFightMainGridBuff
function XUiPunishaarFightMainPanelEnemyHp:_OnRefreshBuffGrid(index, grid)
    local item = self._IconBuf and self._IconBuf[index]
    if not item then
        return
    end
    grid:Refresh(item.IconIndex, item.Layer)
end

--- 刷新敌人CD进度（对标 XUiGridBattleCard:RefreshCd，去掉卡牌独有部分）。
--- ImgMask.fillAmount = 剩余CD进度（cd/cdMax）；RImgLight 定位到遮罩当前填充边界。
--- 驱动：CardCdChanged 事件（敌人复用该事件，见 XPunishaarSTEPipeline.TickEnemy 末尾 Emit）#80
function XUiPunishaarFightMainPanelEnemyHp:RefreshCd()
    local reader = self._Control.GameControl.FightControl.STEReader
    local cd = reader:GetEnemyTickCd()
    local cdMax = reader:GetEnemyTickCdMax()

    local percent = (cdMax and cdMax > 0) and (cd / cdMax) or 0

    if self.ImgMask then
        self.ImgMask.fillAmount = percent
    end

    if self.RImgLight then
        local show = percent > 0
        self.RImgLight.gameObject:SetActiveEx(show)
        if show then
            local height = self:_GetMaskHeight()
            -- SetAnchoredPositionY：C# 扩展用 tempVec2 setter(零装箱)，内部读对轴 .x 一次拆箱，避 Lua 侧 Vector2 构造+setter 双装箱 #向量GC
            self.RImgLight.rectTransform:SetAnchoredPositionY(height * 0.5 - percent * height)
        end
    end
end

--- 播放敌人准备攻击特效（关再开重播，EnemyAttackPrepare 事件经 PanelFighting 转发触发）#EnemyAttack
function XUiPunishaarFightMainPanelEnemyHp:PlayFxEnemyAttack()
    if not self.FxEnemyAttack then return end
    self.FxEnemyAttack.gameObject:SetActiveEx(false)
    self.FxEnemyAttack.gameObject:SetActiveEx(true)
end

--- 取血条宽度（缓存，prefab 尺寸固定）
function XUiPunishaarFightMainPanelEnemyHp:_GetHpBarWidth()
    if not self._HpBarWidth then
        self._HpBarWidth = self.CurHp and self.CurHp.rectTransform.rect.width or 0
    end
    return self._HpBarWidth
end

--- 取 ImgMask 高度（缓存，prefab 尺寸固定）。对标卡牌 _GetMaskHeight #80
---@return number
function XUiPunishaarFightMainPanelEnemyHp:_GetMaskHeight()
    if not self._MaskHeight then
        self._MaskHeight = self.ImgMask and self.ImgMask.rectTransform.rect.height or 0
    end
    return self._MaskHeight
end

---@param name string
function XUiPunishaarFightMainPanelEnemyHp:SetName(name)
    if self.TxtName then
        self.TxtName.text = name or ""
    end
end

function XUiPunishaarFightMainPanelEnemyHp:SetRoleImg(img)
    if not string.IsNilOrEmpty(img) then
        self.RImgHead:SetRawImage(img)
    end
end

return XUiPunishaarFightMainPanelEnemyHp
