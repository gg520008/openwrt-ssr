local fs = require "nixio.fs"
local conffile = "/etc/config/gfw.list"

m = SimpleForm("custom", translate("GFW Custom List"))

s = m:field(TextValue, "conf")
s.rmempty = true
s.rows = 16
function s.cfgvalue()
	return fs.readfile(conffile) or ""
end

function m.handle(self, state, data)
	if state == FORM_VALID then
		if data.conf then
			fs.writefile(conffile, data.conf:gsub("\r\n", "\n"))
			luci.sys.call("/usr/share/shadowsocksr/gfw2ipset.sh && /etc/init.d/dnsmasq restart && ipset flush gfwlist")
		end
	end
	return true
end

return m