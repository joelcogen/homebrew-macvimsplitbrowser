require 'formula'

class MacvimSplitBrowser < Formula
  homepage 'https://github.com/rcarmo/macvim'
  url 'https://github.com/rcarmo/macvim/tarball/d241428f4ac8b4234c283ddde64c6e6c5bcf4a41'
  version '20130721'
  sha1 'd241428f4ac8b4234c283ddde64c6e6c5bcf4a41'

  head 'https://github.com/rcarmo/macvim.git', :branch => 'split-browser'

  def options
  [
    ["--custom-icons", "Try to generate custom document icons."],
    ["--with-cscope", "Build with Cscope support."],
    ["--override-system-vim", "Override system vim."],
    ["--with-lua", "Build with Lua scripting support."]
  ]
  end

  depends_on 'cscope' if ARGV.include? '--with-cscope'
  depends_on 'lua' if ARGV.include? '--with-lua'

  def install
    # MacVim's Xcode project gets confused by $CC, so remove it
    ENV['CC'] = nil
    ENV['CFLAGS'] = nil
    ENV['CXX'] = nil
    ENV['CXXFLAGS'] = nil

    # Set ARCHFLAGS so the Python app (with C extension) that is
    # used to create the custom icons will not try to compile in
    # PPC support (which isn't needed in Homebrew-supported systems.)
    arch = MacOS.prefer_64_bit? ? 'x86_64' : 'i386'
    ENV['ARCHFLAGS'] = "-arch #{arch}"

    args = ["--with-features=huge",
            "--with-tlib=ncurses",
            "--enable-multibyte",
            "--with-macarchs=#{arch}",
            "--enable-perlinterp",
            "--enable-pythoninterp",
            "--enable-rubyinterp",
            "--enable-tclinterp"]

    args << "--enable-cscope" if ARGV.include? "--with-cscope"

    if ARGV.include? "--with-lua"
      args << "--enable-luainterp"
      args << "--with-lua-prefix=#{HOMEBREW_PREFIX}"
    end

    system "./configure", *args

    # Building custom icons fails for many users, so off by default.
    unless ARGV.include? "--custom-icons"
      inreplace "src/MacVim/icons/Makefile", "$(MAKE) -C makeicns", ""
      inreplace "src/MacVim/icons/make_icons.py", "dont_create = False", "dont_create = True"
    end

    # Reference: https://github.com/b4winckler/macvim/wiki/building
    system "cd src/MacVim/icons && make getenvy"

    system "make"

    prefix.install "src/MacVim/build/Release/MacVim.app"
    inreplace "src/MacVim/mvim", /^# VIM_APP_DIR=\/Applications$/,
              "VIM_APP_DIR=#{prefix}"
    bin.install "src/MacVim/mvim"

    # Create MacVim vimdiff, view, ex equivalents
    executables = %w[mvimdiff mview mvimex]
    executables += %w[vi vim vimdiff view vimex] if ARGV.include? "--override-system-vim"
    executables.each {|f| ln_s bin+'mvim', bin+f}
  end

  def caveats; <<-EOS.undent
    This formula will most probably conflict with the macvim formula.
    If you already installed MacVim from Homebrew, please remove it using:
        brew uninstall macvim

    MacVim.app installed to:
      #{prefix}

    To link the application to a normal Mac OS X location:
        brew linkapps
    or:
        ln -s #{prefix}/MacVim.app /Applications
    EOS
  end
end
