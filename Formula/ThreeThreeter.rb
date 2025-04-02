# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
class Threethreeter < Formula
  desc "Local backend for the 33ter OCR code solution app"
  homepage "https://github.com/designerGenes/33ter_backend"
  url "https://github.com/designerGenes/33ter_backend/releases/download/v0.1.1/33ter_backend-0.1.1.tar.gz"
  sha256 "0a5bf3de368f3791c5c7de072a613ec5aafb9ecf9f767875640423124e6dafcb"
  license "MIT"
  version "0.1.1"

  depends_on "python@3.11"
  depends_on "tesseract"
  depends_on "tesseract-lang"

  def install
    # Define the path to requirements.txt relative to the CWD (build dir)
    requirements_path = Pathname.pwd/"req/requirements.txt" # Path relative to CWD

    # Check if requirements file exists before trying to install
    unless requirements_path.exist?
      odie "Requirements file not found at expected path: #{requirements_path}. Check tarball structure and directory listing."
    end

    # Install dependencies directly into libexec using the Homebrew Python's pip
    python_bin = Formula["python@3.11"].opt_bin
    # system python_bin/"pip3", "install", "--upgrade", "pip" # Skip pip upgrade

    # Install dependencies into the libexec prefix structure *first*
    system python_bin/"pip3", "install", "--verbose", "-r", requirements_path, "--prefix=#{libexec}"

    # Construct the site-packages path within libexec *after* installation
    site_packages = Language::Python.site_packages(Formula["python@3.11"].opt_bin/"python3")
    libexec_site_packages = libexec/site_packages.sub(Formula["python@3.11"].opt_prefix.to_s, "")

    # Now, copy the *contents* of the current directory (source code) into libexec
    # This makes libexec the root for the application files.
    libexec.install Dir["*"]

    # Create a wrapper script in bin, adjusting paths
    (bin/"33ter-backend").write <<~EOS
      #!/bin/bash
      # Add libexec (for source) and libexec site-packages (for deps) to PYTHONPATH
      export PYTHONPATH="#{libexec}:#{libexec_site_packages}:$PYTHONPATH"
      exec "#{python_bin}/python3" "#{libexec}/start_local_dev.py" "$@"
    EOS
  end

  def caveats
    <<~EOS
      The 33ter backend service can be started by running:
        33ter-backend

      Ensure Tesseract language data is correctly installed. You might need:
        brew install tesseract-lang
    EOS
  end

  test do
    assert_predicate bin/"33ter-backend", :exist?
    assert_predicate bin/"33ter-backend", :executable?
    # Test might involve checking if the script runs with a hypothetical --help flag
    # system bin/"33ter-backend", "--help"
  end
end
