local EnumConst = {
    PbrAdventureState = {
        None = 0,--不在局内
        Shopping = 1,--商店中
        Batting = 2,--战斗中
    },
    
    GameShop = {
        ChooseResultType = {
            None = 0, -- 不能做处理
            Addition = 1, -- 新增
            Replace = 2, -- 替换
            Upgrade = 3, -- 升阶
        }
    },
    
    --- UI输入相关枚举, 按界面划分。 Id即为优先级，数值越小优先级越高
    UIInputTypes = {
        UIChapter = {
            SelectStage = 10,
        },
        UIShop = {
            Exit = 1, -- 退出商店，最高优先级
            GoNextWave = 2, -- 进入下一波战斗
            SelectGoods = 3, -- 选择商品
            RefreshGoods = 4, -- 刷新商品
        }
    },
    
    StatusValueType = {
      Default = 0, -- 默认十进制数值
      Permyriad = 1, --万分比
    },
    
    --- 战斗内属性显示的时候，取战斗数据的哪个值？
    StatusFightSrcType = {
        CurValue = 0,
        MaxValue = 1,
    },
    
    --- 关卡类型，内部定义类型
    StageCustomType = {
        Teaching = 1, -- 教学关
        Normal = 2,
        Challenge = 3, -- 无尽关
    },
    
    --- 万分比的数值基数
    PermyriadValueBase = 10000,
    
    --- 万分比转百分比的基数
    Permyriad2PercentValueBase = 100,
    
    --- 道具类型
    ItemType = {
        Skill = 1,
        Other = 2,
    },
    
    FightExitType = {
        GiveUp = 1, -- 放弃当前波次战斗
        Settle = 2, -- 提前结算
    },
    
    WaveShowType = {
        Normal = 0,
        Elite = 1, -- 精英怪
        Boss = 2,
    },
    
    -- 天赋节点类型
    GeniusNodeType = {
        Normal = 0, -- 普通节点
        Important = 1, -- 重要节点
        Special = 2, -- 特殊节点
    },
    
    --- 关卡入口样式类型
    StageGridStyleType = {
        Style1 = 0,
        Style2 = 1,
        Style3 = 2,
    },
    
    --- 图鉴
    Collections = {
        -- 图鉴页签类型
        TabType = {
            -- 道具部分与道具类型一致，其他部分在道具类型后面顺位
            Skill = 1,
            Other = 2,
            Monster = 3,
        },
        MonsterTagType = {
            Normal = 1,
            Elite = 2, -- 精英怪
            Boss = 3,
        },
        --- 图鉴统计信息类型
        SummaryDataType = {
            GotTimes = 1, -- 获得次数
            TriggerTimes = 2, -- 触发次数
            KillTimes = 3, -- 击杀次数
            TotalDamage = 4, -- 总伤害
        },
        --- 图鉴排序类型
        SortType =  {
            Default = 1, -- 按Id升序排序
            UnlockTime = 2, -- 解锁时间早的在前
            Quality = 3, -- 品质高的在前
        },
        --- 各页签的排序列表
        Tab2SortTypeList = {
            [1] = {1, 2}, -- 技能页签支持的排序类型
            [2] = {1, 2, 3}, -- 其他道具页签支持的排序类型
            [3] = {1, 2}, -- 怪物页签支持的排序类型
        },
    },
    
    -- 任务组配置类型
    TaskGroupType = {
        TaskId = 0, -- 配置的是taskId
        TaskTimeLimitId = 1, -- 配置的是限时任务组id
    }
}

return EnumConst