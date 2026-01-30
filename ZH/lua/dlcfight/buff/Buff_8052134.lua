local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8052134 : XFightBase
local XBuffScript8052134 = XDlcScriptManager.RegBuffScript(8052134, "XBuffScript8052134", Base)
local OperationKeyList={
    ENpcOperationKey.Move,
    ENpcOperationKey.Jump,
    ENpcOperationKey.Dodge,
    ENpcOperationKey.Attack,
    ENpcOperationKey.Ball1,
    ENpcOperationKey.Ball2,
    ENpcOperationKey.Ball3,
    ENpcOperationKey.Ball4,
    ENpcOperationKey.Focus,
    ENpcOperationKey.Jump,
    ENpcOperationKey.ExSkill,
}

--效果说明：Relink小辉辉冲刺技能过程中屏蔽玩家界面UI用
function XBuffScript8052134:Init()
    --初始化
    Base.Init(self)
    --设置所有按钮隐藏
    for i, operationKey in pairs(OperationKeyList) do
        self._proxy:SetMonsterButtonOpEnabled(operationKey,self._uuid,false) 
    end
end

--被销毁的时候把UI设置回来
function XBuffScript8052134:Terminate()
    Base.Terminate(self)
    --设置所有按钮显示
    for i, operationKey in pairs(OperationKeyList) do
        self._proxy:SetMonsterButtonOpEnabled(operationKey,self._uuid,true)
    end
end

return XBuffScript8052134
