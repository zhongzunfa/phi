---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2018/4/18 17:25
---
local base_component = require "component.base_component"
local get_host = require("utils").getHost
local response = require "core.response"

local ERR = ngx.ERR
local NOTICE = ngx.NOTICE
local LOGGER = ngx.log

local jwt_auth = base_component:extend()

function jwt_auth:new(ref, config)
    self.super.new(self, "jwt-auth")
    self.order = config.order
    self.service = ref
    return self
end

-- jwt认证
function jwt_auth:rewrite(ctx)
    self.super.rewrite(self)
    local hostkey = get_host(ctx)
    local isDegraded, degrader, err = ctx.degrade, self.service:getDegrader(hostkey, uri)
    if err then
        -- 查询出现错误，放行
        LOGGER(ERR, "failed to get degrader by key :", hostkey, uri, ",err : ", err)
    else
        if not isDegraded then
            -- 上文未触发降级，取全局开关
            isDegraded = degrader.enabled
        end
        if isDegraded then
            if not degrader.skip then
                -- 做降级处理 1、fake数据 2、重定向 3、内部请求
                LOGGER(NOTICE, "request will be degraded")
                degrader:doDegrade(ctx)
            else
                LOGGER(ERR, "Cannot perform a demotion strategy ,degrader is nil")
                response.failure("Cannot perform a degrade strategy :-(")
            end
        end
    end
end

return jwt_auth