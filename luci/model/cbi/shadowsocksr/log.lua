local fs = require "nixio.fs"
local conffile = "/tmp/luci-app-shadowsocksRV.log"

f = SimpleForm("logview")

t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
  luci.sys.exec("[ -f /tmp/openwrt-ssr.log ] && sed '1!G;h;$!d' /tmp/openwrt-ssr.log > /tmp/luci-app-shadowsocksRV.log")
  return fs.readfile(conffile) or ""
end
t.readonly="readonly"

return f