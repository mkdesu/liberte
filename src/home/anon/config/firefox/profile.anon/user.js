/*
  https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
*/

// UI
user_pref("accessibility.typeaheadfind", false);
user_pref("browser.startup.homepage", "file:///home/anon/info/browser.html");
user_pref("general.warnOnAboutConfig", false);

// Proxy
user_pref("network.proxy.socks", "127.0.0.1");
user_pref("network.proxy.socks_port", 9050);
user_pref("network.proxy.socks_remote_dns", true);
user_pref("network.proxy.type", 1);

// Network usage
user_pref("browser.safebrowsing.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.search.update", false);
user_pref("extensions.blocklist.enabled", false);
user_pref("extensions.update.autoUpdateDefault", false);
user_pref("network.dns.disablePrefetch", true);

// Disk usage
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.offline.enable", false);
user_pref("browser.download.dir", "/home/anon/persist/desktop");
user_pref("browser.download.folderList", 0);
user_pref("extensions.getAddons.cache.enabled", false);

// Privacy
user_pref("browser.chrome.load_toolbar_icons", 1);
user_pref("browser.download.manager.retention", 1);
user_pref("browser.privatebrowsing.autostart", true);
user_pref("browser.search.suggest.enabled", false);
user_pref("geo.enabled", false);
user_pref("privacy.donottrackheader.enabled", true);
user_pref("security.enable_tls_session_tickets", false);

// Security
user_pref("plugins.click_to_play", true);
user_pref("network.http.spdy.enabled", false);
user_pref("xpinstall.whitelist.add", "");
user_pref("xpinstall.whitelist.add.103", "");

// Fingerprint
user_pref("browser.startup.homepage_override.buildID", "0");
user_pref("browser.startup.homepage_override.mstone", "rv:17.0");
user_pref("dom.enable_performance", false);
user_pref("general.appname.override", "Netscape");
user_pref("general.appversion.override", "5.0 (Windows)");
user_pref("general.buildID.override", 0);
user_pref("general.oscpu.override", "Windows NT 6.1");
user_pref("general.platform.override", "Win32");
user_pref("general.productSub.override", "20100101");
user_pref("general.useragent.override", "Mozilla/5.0 (Windows NT 6.1; rv:17.0) Gecko/20100101 Firefox/17.0");
user_pref("general.useragent.vendor", "");
user_pref("general.useragent.vendorSub", "");
user_pref("gfx.downloadable_fonts.fallback_delay", -1);
user_pref("intl.accept_languages", "en-us,en");
