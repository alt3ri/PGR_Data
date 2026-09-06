local STEHelper = require("STEVM/STEHelper")

---@class BuffEntity: STEVM.Entity
local BuffEntity = XClass(STEHelper.GetClsEntity(), "Entity")

function BuffEntity:Ctor(id, env, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)
    --- buff配置Id
    self.Fields.BuffId = STEHelper.NewPropertySingle(id, env, buffId)

    --- 这个buff是谁产生的
    self.Fields.OwnEntityId = STEHelper.NewPropertySingle(id, env, ownEntityId)
    --- 这个buff附加到谁身上
    self.Fields.TargetEntityId = STEHelper.NewPropertySingle(id, env, targetEntityId)
    self.Fields.TargetFieldNameEnum = STEHelper.NewPropertySingle(id, env, targetFieldNameEnum)

    --- 自由值
    self.Fields.Alpha = STEHelper.NewPropertyModifiedNum(id, env, 0, 0)

    --- 生命周期(走累计量，而不是扣除量，即到时间的判断是，该值>=配置值）
    self.Fields.LifeTimes = STEHelper.NewPropertySingle(id, env, 0)

    --- buff状态值 STECustomEnum.BuffState
    self.Fields.State = STEHelper.NewPropertySingle(id, env, 0)

    --- Ex 效果运行态：ExTickCD=当前 Ex 释放倒计时(帧)；ExDoneTimes=已释放 Ex 次数
    --- 初值由 _InitBuffEntity 依 buff 表 ExFirstImmediate/ExEffectCD 设定
    self.Fields.ExTickCD = STEHelper.NewPropertySingle(id, env, 0)
    self.Fields.ExDoneTimes = STEHelper.NewPropertySingle(id, env, 0)

    --- 字段镜像快照值（SnapshotFieldToBuff 每帧读实体字段终值 floor 后写入；按 BuffId 聚合求和供 buff 图标列表显示数值）
    self.Fields.Layer = STEHelper.NewPropertySingle(id, env, 0)
end

--- 复用一个已归还的空壳实例：改 id、各 property 归属与值，复用已有 property 对象（不 new）。
--- 契约：由 BuffEntityPool.Acquire 弹出后、RegisterScope 前调用（先写新 uid 再注册，避免撞 id 重复 assert）。
--- 单局尺度：env 不变，故只改 _OwnScopeId 不碰 _OwnEnv。
function BuffEntity:ResetForReuse(id, env, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)
    self._Id = id

    local f = self.Fields
    f.BuffId:SetOriginVal(buffId)
    f.OwnEntityId:SetOriginVal(ownEntityId)
    f.TargetEntityId:SetOriginVal(targetEntityId)
    f.TargetFieldNameEnum:SetOriginVal(targetFieldNameEnum)
    f.LifeTimes:SetOriginVal(0)
    f.State:SetOriginVal(0)
    f.ExTickCD:SetOriginVal(0)
    f.ExDoneTimes:SetOriginVal(0)
    f.Layer:SetOriginVal(0)

    -- Alpha：base 归零、运算队列经 Release 回池（见 Release）；此处仅当 Release 置 _Ops=nil 后重建取池 ListSnap（对齐 STEVM 池，避免 = {} 破坏池/泄漏）#Buff池对齐STEVM
    f.Alpha:SetOriginVal(0)
    if f.Alpha._Ops == nil then
        f.Alpha._Ops = self._Env:GetPoolListSnap()
    end

    -- 各 property / Tags 的归属 scope id 同步为新 uid
    f.BuffId._OwnScopeId = id
    f.OwnEntityId._OwnScopeId = id
    f.TargetEntityId._OwnScopeId = id
    f.TargetFieldNameEnum._OwnScopeId = id
    f.Alpha._OwnScopeId = id
    f.LifeTimes._OwnScopeId = id
    f.State._OwnScopeId = id
    f.ExTickCD._OwnScopeId = id
    f.ExDoneTimes._OwnScopeId = id
    f.Layer._OwnScopeId = id
    self.Tags._OwnScopeId = id
end

--- 释放（覆写基类）：不拆 Fields 结构，只清空可变状态后推回派生 env 的对象池，供本局后续 buff 复用。
--- Release 是「对象确定性消失」的唯一钩子（commit / 非事务 remove / 回滚，见 STEEnv），
---   因此在此归还池是安全时机，绝无回滚复活导致的别名。
function BuffEntity:Release()
    -- Alpha 运算队列经 STEVM PropertyModifiedNum:Release 回池（op-tables + ListSnap 数组），对齐池复用（避免 = {} 丢弃致池对象泄漏/破坏池）#Buff池对齐STEVM
    local alpha = self.Fields.Alpha
    if alpha then
        alpha:Release()
    end
    if self.Tags and self.Tags.Release then
        self.Tags:Release()
    end

    -- 归还派生 env 的空闲栈（env 是 XPunishaarSTEEnv，方法就在其上）
    self._Env:ReturnBuff(self)
end

return BuffEntity