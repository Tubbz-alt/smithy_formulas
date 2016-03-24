class LuarocksFormula < Formula
  homepage "https://luarocks.org/"
  url "http://luarocks.org/releases/luarocks-2.2.2.tar.gz"

  module_commands [ "load lua" ]

  def install
    module_list
    system "./configure --prefix=#{prefix} --lua-version=5.1"
    system "make"
    system "make install"
  end
end
