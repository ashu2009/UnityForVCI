local DEFINE = require("define_Module")
local controlModule = require("control_Module")

---入室メッセージ(タスク追加)
DEFINE.controlAddMessage(0, 0, 0, 0, DEFINE.CONTROLKEY_ENTER_ROOM)

function onUse(use)
    if controlModule.isSynced then
        controlModule.onUse(use)
    end
end

function onUnuse(use)
    if controlModule.isSynced then
        controlModule.onUnuse(use)
    end
end

function onTriggerEnter(item, hit)
    if controlModule.isSynced then
        controlModule.onTriggerEnter(item, hit)
    end
end

function onTriggerExit(item, hit)
    if controlModule.isSynced then
        controlModule.onTriggerExit(item, hit)
    end
end


function onGrab(target)
    if controlModule.isSynced then
        controlModule.onGrab(target)
    end
end

function onUngrab(target)
    if controlModule.isSynced then
        controlModule.onUngrab(target)
    end
end
