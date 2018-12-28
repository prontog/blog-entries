Writing a Wireshark Dissector using *Lua* might be the easier than using *C* but there is a performance penalty. Since I have only written dissectors in *Lua*, I cannot make comparisons. The only comparison I have found is in Graham Bloice's [Writing-a-Wireshark-Dissector](https://sharkfestus.wireshark.org/sharkfest.13/presentations/PA-10_Writing-a-Wireshark-Dissector_Graham-Bloice.zip) presentation in [SharkFest'13](https://sharkfestus.wireshark.org/sf13).

What I know though is that load time (Edit -> Preferences -> Appearance -> Layout -> Show file load time) is about 50 times slower when my *Lua* Dissectors are enabled.

I plan to rewrite them using the [*ASN.1* generator](https://wiki.wireshark.org/Asn2wrs) but until then, is there some way to boost my *Lua* dissectors without or with minimal changes?

Luckily there is a way, and it's called [*LuaJIT*](https://luajit.org). It is a Just-In-Time compiler for *Lua* which can give even a [110x boost](https://luajit.org/performance_x86.html) depending on the algorithm. It also has big company [sponsors](https://luajit.org/sponsors.html) which rely on it. The only downside is that it implements *Lua* 5.1.4 whereas Wireshark is also compatible with *Lua* 5.2. This means you will have to replace *Lua* 5.2 features from your dissector. In my case I only had to replace \x notation with \ddd in one of my dissectors.

Using it increased the performance of my dissectors by **1.7x**. True this is not as impressive as the aforementioned 110x but still such an improvement with almost no code changes is still impressive. I also used it to analyze two years of traffic and compared the results with the ones generated by *Lua* 5.2 and found no differences.

### How to integrate it with Wireshark

#### On Linux

First, we need to build and install *LuaJIT*:
```bash
LUA_JIT_VERSION=2.0.5
curl -R -O https://luajit.org/download/LuaJIT-${LUA_JIT_VERSION}.tar.gz
tar -xf LuaJIT-${LUA_JIT_VERSION}.tar.gz
cd LuaJIT-${LUA_JIT_VERSION}
make -j $(grep processor /proc/cpuinfo | wc -l)
sudo make install
cd ..
```

For more info have a look at the [official POSIX installation guide](https://luajit.org/install.html#posix).

Then we need to build *tshark* (to build the GUI):

```bash
WIRESHARK_VERSION=2.6.5
curl -R -O https://2.na.dl.wireshark.org/src/all-versions/wireshark-${WIRESHARK_VERSION}.tar.xz
tar -xf wireshark-${WIRESHARK_VERSION}.tar.xz
cd wireshark-${WIRESHARK_VERSION}
# Add luajit first in the supported lua implementations
sed -i 's/\(lua5.2\)/luajit \1/' acinclude.m4
# See "Embedding LuaJIT" in https://luajit.org/install.html
sed -i 's/lua_newstate([^;]*)/luaL_newstate()/' epan/wslua/init_wslua.c
./autogen.sh
#
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure --with-lua
make -j $(grep processor /proc/cpuinfo | wc -l)
```

For more info have a look at the *Building on Unix* section of the [official Build Wireshark doc](https://www.wireshark.org/docs/wsdg_html_chunked/ChSrcBuildFirstTime.html#_building_on_unix)

#### On Windows

1. Download the [LuaJIT sources](https://luajit.org/download.html).
2. Build LuaJIT following the [official Windows guide](https://luajit.org/install.html#windows).
3. Download the [Wireshark source](https://www.wireshark.org/#download).
4. Use an editor to open the file *cmake/modules/FindLUA.cmake* in the Wireshark sources. Replace "NAMES lua${LUA_INC_SUFFIX} lua52 lua5.2 lua51 lua5.1 lua" with "NAMES lua51 lua${LUA_INC_SUFFIX} lua52 lua5.2 lua51 lua5.1 lua". This is necessary to give priority to Lua 5.1 which is the *Lua* version implemented by *LuaJIT*.
5. Use an editor to open the file *epan/wslua/init_wslua.c* in the Wireshark sources. Replace "lua_newstate(wslua_allocf, NULL);" with "luaL_newstate();".
6. Open a *Visual Studio Command Prompt* and `set LUA_DIR=/path/to/LuaJIT/install/dir/from/step/2`.
7. Use the command prompt from the previous step to build Wireshark following the [official Win32/64 guide](https://www.wireshark.org/docs/wsdg_html_chunked/ChSetupWin32.html).
8. Copy *lua51.dll* from the /path/to/LuaJIT/install/dir/from/step/2 to the directory containing Wireshark.exe.

Now test it with your *Lua* Wireshark Dissectors. Hopefully, your dissector will show a bigger performance boost than the 1.7x of my dissectors.

Have fun and a Happy New Year!