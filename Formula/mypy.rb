class Mypy < Formula
  desc "Experimental optional static type checker for Python"
  homepage "http://www.mypy-lang.org/"
  url "https://github.com/python/mypy.git",
      :tag      => "v0.761",
      :revision => "f53b718bdf5935443332a43d8c1b448af8b80b57"
  head "https://github.com/python/mypy.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "f6254003146ab4e1ade60be5ab23bcca0f3e3086d2949ca1fd93c63d5ef627f0" => :catalina
    sha256 "539a9f99c6f0118e0c6e3ee0c80e201272244ea29939fdadc3ebde276c39ef4f" => :mojave
    sha256 "954d03c00690939582b135c17fc6aa90f24a698bdd27c4e5c6ecc7946a3c6b3d" => :high_sierra
  end

  depends_on "sphinx-doc" => :build
  depends_on "python"

  resource "psutil" do
    url "https://files.pythonhosted.org/packages/73/93/4f8213fbe66fc20cb904f35e6e04e20b47b85bee39845cc66a0bcf5ccdcb/psutil-5.6.7.tar.gz"
    sha256 "ffad8eb2ac614518bbe3c0b8eb9dffdb3a8d2e3a7d5da51c5b974fb723a5c5aa"
  end

  resource "sphinx_rtd_theme" do
    url "https://files.pythonhosted.org/packages/ed/73/7e550d6e4cf9f78a0e0b60b9d93dba295389c3d271c034bf2ea3463a79f9/sphinx_rtd_theme-0.4.3.tar.gz"
    sha256 "728607e34d60456d736cc7991fd236afb828b21b82f956c5ea75f94c8414040a"
  end

  resource "typed-ast" do
    url "https://files.pythonhosted.org/packages/34/de/d0cfe2ea7ddfd8b2b8374ed2e04eeb08b6ee6e1e84081d151341bba596e5/typed_ast-1.4.0.tar.gz"
    sha256 "66480f95b8167c9c5c5c87f32cf437d585937970f3fc24386f313a4c97b44e34"
  end

  resource "mypy_extensions" do
    url "https://files.pythonhosted.org/packages/63/60/0582ce2eaced55f65a4406fc97beba256de4b7a95a0034c6576458c6519f/mypy_extensions-0.4.3.tar.gz"
    sha256 "2d82818f5bb3e369420cb3c4060a7970edba416647068eb4c5343488a6c604a8"
  end

  resource "typing_extensions" do
    url "https://files.pythonhosted.org/packages/e7/dd/f1713bc6638cc3a6a23735eff6ee09393b44b96176d3296693ada272a80b/typing_extensions-3.7.4.1.tar.gz"
    sha256 "091ecc894d5e908ac75209f10d5b4f118fbdb2eb1ede6a63544054bb1edb41f2"
  end

  def install
    xy = Language::Python.major_minor_version "python3"

    # https://github.com/python/mypy/issues/2593
    version_static = buildpath/"mypy/version_static.py"
    version_static.write "__version__ = '#{version}'\n"
    inreplace "docs/source/conf.py", "mypy.version", "mypy.version_static"

    (buildpath/"docs/sphinx_rtd_theme").install resource("sphinx_rtd_theme")
    # Inject sphinx_rtd_theme's path into sys.path
    inreplace "docs/source/conf.py",
              "sys.path.insert(0, os.path.abspath('../..'))",
              "sys.path[:0] = [os.path.abspath('../..'), os.path.abspath('../sphinx_rtd_theme')]"
    system "make", "-C", "docs", "html"
    doc.install Dir["docs/build/html/*"]

    rm version_static

    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python#{xy}/site-packages"
    resources.each do |r|
      r.stage do
        system "python3", *Language::Python.setup_install_args(libexec/"vendor")
      end
    end

    ENV.prepend_create_path "PYTHONPATH", libexec/"lib/python#{xy}/site-packages"
    ENV["MYPY_USE_MYPYC"] = "1"
    system "python3", *Language::Python.setup_install_args(libexec)

    bin.install Dir[libexec/"bin/*"]
    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  test do
    (testpath/"broken.py").write <<~EOS
      def p() -> None:
        print('hello')
      a = p()
    EOS
    output = pipe_output("#{bin}/mypy broken.py 2>&1")
    assert_match '"p" does not return a value', output
  end
end
