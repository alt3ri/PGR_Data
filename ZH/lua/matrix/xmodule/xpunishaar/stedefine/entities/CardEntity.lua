local STEHelper = require("STEVM/STEHelper")

---@class CardEntity: STEVM.Entity
local CardEntity = XClass(STEHelper.GetClsEntity(), "Entity")

function CardEntity:Ctor(id, env, cardId, initAtk, initTickCd, initBallProduct, initBallConsume, index, posIndex, cardCfg, initTickCdMaxMin)
    -- 卡牌配置Id
    self.Fields.CardId = STEHelper.NewPropertySingle(id, env, cardId)

    --- 配置表行引用（PropertyConfig，只读）；访问 .Color / .Type / .Size 等配置常量
    ---@type PropertyConfig  XTablePunishaarCard
    self.Fields.CardConfig = STEHelper.NewPropertyConfig(id, env, cardCfg)

    ---@type PropertyModifiedNum
    self.Fields.ATK = STEHelper.NewPropertyModifiedNum(id, env, initAtk, 0)
    -- CD 单位为逻辑帧（TickCD/TickCDMax，所见即所得）；调用方须已把配置毫秒转成帧后传入
    ---@type PropertyModifiedNum
    self.Fields.TickCDMax = STEHelper.NewPropertyModifiedNum(id, env, initTickCd, initTickCdMaxMin or 0)
    ---@type PropertyModifiedNum
    self.Fields.TickCD = STEHelper.NewPropertyModifiedNum(id, env, initTickCd, 0)
    ---@type PropertyModifiedNum
    self.Fields.BallProductCount = STEHelper.NewPropertyModifiedNum(id, env, initBallProduct, 0)
    ---@type PropertyModifiedNum
    self.Fields.BallConsumeCount = STEHelper.NewPropertyModifiedNum(id, env, initBallConsume, 0)

    -- 卡牌在一维紧凑数组中的索引位置，不考虑空间上的间隔问题
    self.Fields.Index = STEHelper.NewPropertySingle(id, env, index)

    -- 卡牌当前所处位置（离散坐标值），非连续性，两张相邻的卡牌之间可能存在空格区域【左对齐起点：因为卡牌有一维体积，横跨多个离散坐标，由配置Size值决定】
    -- 由外部经开战契约显式提供（与紧凑索引 index 解耦）；空间坐标系统尚未启用，当前仅作数据存储。
    self.Fields.PosIndex = STEHelper.NewPropertySingle(id, env, posIndex)

    -- 卡牌从开局开始的触发次数
    self.Fields.DoneTimes = STEHelper.NewPropertySingle(id, env)

    -- 本帧已激发次数（每帧 ResetGlobalTickData 清零；限同帧连锁激发次数，防互相 SetCardCDEnd 刷次）#同帧激发上限
    self.Fields.TickDoneTimes = STEHelper.NewPropertySingle(id, env)
    
    -- 自定义运行时临时变量，可由effect自由修改或取用
    ---@type PropertyModifiedNum
    self.Fields.Alpha = STEHelper.NewPropertyModifiedNum(id, env, 0, 0)
end

return CardEntity