local EnumConst = {
    --- 方块旋转参数(顺时针方向）
    RotateIndex = {
        Zero = 0,
        Turn_90_Degrees = 1,
        Turn_180_Degrees = 2,
        Turn_270_Degrees = 3,
    },
    
    --- 方向枚举
    DirectionIndex = {
        Up = 0,
        Right = 1,
        Down = 2,
        Left = 3
    },
    
    --- 方块类型
    BlockType = {
        --- 地板
        Floor = 0,
        --- 基础单色块
        Normal = 1,
        --- 需求块
        Target = 2,
        --- 可变色块
        ColorChangeable = 3,    
        --- 旋转色块多色型（射线）
        TurnableMultyColor = 4, 
        --- 镜子
        Mirror = 5, 
        --- 延伸块
        VariableLength = 6, 
        --- 展示块
        ShowOnly = 7,   
    },
    
    --- 局内指令类型
    CommandType = {
        --- 移除指定方块的所有影响
        RemoveBlockInfluence = 1,
        --- 施加指定方块的影响到棋盘中
        AddBlockInfluence = 2,
        --- 改变一个方块的放置状态（不改变坐标）
        SetBlockPlacedState = 3,
        ---- 更新方块自身的状态（根据所处环境）(目前仅有目标方块一种方块是受体，因此遍历只针对目标方块进行处理）
        UpdateBlocksState = 4,
        --- 修改一个方块本身的颜色属性
        ChangeBlockColor = 5,
        --- 修改一个方块的方向（顺时针）
        RotateBlock = 6,
        --- 修改延伸方块的长度
        ChangeBlockLength = 7,
        --- 将方块从位置注册表中注销（不修改方块自身坐标）
        --- 用于移动/交换的第一阶段，腾出格子
        DetachBlock = 8,
        --- 将方块绑定到新坐标，并写入位置注册表
        --- 用于移动/交换的第二阶段，落定新格
        AttachBlock = 9,
    },
    
    --- 局内动画类型
    AnimationType = {
        SelectGrid = 1, -- 选中某个方块
        PlacedGird = 2, -- 放置某个方块
        UpdateAllState = 3, -- 更新所有方块的状态
        StagePassed = 4, -- 通关后统一刷新表现
    },

    --- 局内动画优先级
    AnimationPriority = {
        SelectGrid = 10,
        PlacedGird = 20,
        UpdateAllState = 30,
        StagePassed = 40,
    },
    
    --- 方块配置自定义参数枚举映射
    BlockCfgParams = {
        --- 延伸块
        VariableLength = {
            InitLen = 1,
            MinLen = 2,
            MaxLen = 3,
            ExpandDir = 4,
        }
    },

    --- 延伸块的延伸方向类型
    VariableLengthBlockExpandType = {
        Horizontal = 1,
        Vertical = 2,
    }
}

return EnumConst