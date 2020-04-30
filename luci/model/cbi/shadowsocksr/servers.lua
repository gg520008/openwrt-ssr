local m, s, o
local shadowsocksr = "shadowsocksr"

local uci = luci.model.uci.cursor()
local server_count = 0
uci:foreach("shadowsocksr", "servers", function(s)
	server_count = server_count + 1
end)

m = Map(shadowsocksr,  translate("Servers Manage"))

-- Server Subscribe

s = m:section(TypedSection, "server_subscribe", translate("Server subscription"))
s.anonymous = true

o = s:option(Flag, "auto_update", translate("Auto Update"))
o.rmempty = false
o.description = translate("Auto Update Server subscription, GFW list and CHN route")

o = s:option(Flag, "proxy", translate("Through proxy update"))
o.rmempty = false

o = s:option(ListValue, "auto_update_time", translate("Update time (every day)"))
for t = 0,23 do
	o:value(t, t..":00")
end
o.default=2
o.rmempty = false

o = s:option(DynamicList, "subscribe_url", translate("Subscribe URL"))
o.rmempty = true

o = s:option(Button,"update",translate("Update Now"))
o.write = function()
	luci.sys.call("bash /usr/share/shadowsocksr/auto_update.sh >>/tmp/openwrt-ssr.log 2>&1")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shadowsocksr", "servers"))
end

s = m:section(TypedSection, "servers", translate("Server Setting"))
s.anonymous = true
s.addremove = true
s.sortable = false
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin/services/shadowsocksr/servers/%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "type", translate("Type"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("")
end

o = s:option(DummyValue, "alias", translate("Alias"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "server", translate("Server Address"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "server_port", translate("Server Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

if nixio.fs.access("/usr/bin/ssr-kcptun") then
	o = s:option(DummyValue, "kcp_enable", translate("KcpTun"))
	function o.cfgvalue(...)
		return Value.cfgvalue(...) or "?"
	end
end

o = s:option(DummyValue, "switch_enable", translate("Auto Switch"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

return m