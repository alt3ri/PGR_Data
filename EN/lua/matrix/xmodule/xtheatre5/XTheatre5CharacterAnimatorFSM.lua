--- 肉鸽5 角色动画状态机
--- 因为角色动画涉及模型、特效的加载和卸载，状态切换不方便依赖Animator本身的功能，需要外部维护一套状态机
--- 先定义轻量的状态管理
---@class XTheatre5CharacterAnimatorFSM
local XTheatre5CharacterAnimatorFSM = XClass(nil, 'XTheatre5CharacterAnimatorFSM')

function XTheatre5CharacterAnimatorFSM:Ctor(index, proxy, defaultState)
    self.Index = index
    self.Proxy = proxy
    self.State = defaultState or XMVCA.XTheatre5.EnumConst.CharacterAnimaState.Start
    self:CreateData()
end

function XTheatre5CharacterAnimatorFSM:SetState(state)
    if self.State then
        local callback = self.StateCallbackDic[self.State]

        if callback and callback.on_exit then
            callback.on_exit(self, self.Proxy)
        end
    end
    
    self.State = state

    local callback = self.StateCallbackDic[self.State]

    if callback and callback.on_enter then
        callback.on_enter(self, self.Proxy)
    end
end

function XTheatre5CharacterAnimatorFSM:RefreshState()
    if self.State then
        local callback = self.StateCallbackDic[self.State]

        if callback and callback.on_re_enter then
            callback.on_re_enter(self, self.Proxy)
        end
    end
end

function XTheatre5CharacterAnimatorFSM:CreateData()
    -- state的回调
    self.StateCallbackDic = {
        [XMVCA.XTheatre5.EnumConst.CharacterAnimaState.Choose] = {
            on_enter = function(self, refProxy)
                refProxy:PlayAnimaCross(self.Index, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.ChooseSwitch)
            end,
            on_re_enter = function(self, refProxy)
                refProxy:PlayAnimaCross(self.Index, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Choose, true)
            end
        },
        [XMVCA.XTheatre5.EnumConst.CharacterAnimaState.FullView] = {
            on_enter = function(self, refProxy)
                refProxy:PlayAnimaCross(self.Index, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.FullViewSwitch)
            end,
            on_re_enter = function(self, refProxy)
                refProxy:PlayAnimaCross(self.Index, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.FullView, true)
            end
        },
        [XMVCA.XTheatre5.EnumConst.CharacterAnimaState.Detail] = {
            on_enter = function(self, refProxy)
                refProxy:PlayAnimaCross(self.Index, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Detail)
            end,
            on_re_enter = function(self, refProxy)
                refProxy:PlayAnimaCross(self.Index, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Detail, true)
            end
        },
    }
end


return XTheatre5CharacterAnimatorFSM