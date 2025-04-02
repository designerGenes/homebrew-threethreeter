# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
class Threethreeter < Formula
  desc "Local backend for the 33ter OCR code solution app"
  homepage "https://github.com/designerGenes/33ter_backend"
  url "https://github.com/designerGenes/33ter_backend/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "cedbb415fcfacafe7982f56795961e8839ebe090b4842242c80334a1331df154"
  license "MIT"
  version "0.1.0"

  depends_on "python@3.11"
  depends_on "tesseract"
  depends_on "tesseract-lang"

  def install
    # Define the root directory *within* libexec based on the unpacked tarball structure
    app_root = libexec/"33ter_backend-#{version}"

    # Copy the application source code into the app_root directory within libexec
    # Use cp_r to copy contents correctly
    cp_r ".", app_root

    # Define the path to requirements.txt relative to the app_root
    requirements_path = app_root/"req/requirements.txt"

    # Check if requirements file exists before trying to install
    unless requirements_path.exist?
      odie "Requirements file not found at expected path: #{requirements_path}"
    end

    # Install dependencies directly into libexec using the Homebrew Python's pip
    # This will install packages into libexec/lib/python3.11/site-packages
    python_bin = Formula["python@3.11"].opt_bin
    system python_bin/"pip3", "install", "--upgrade", "pip"
    system python_bin/"pip3", "install", "-r", requirements_path, "--prefix=#{libexec}"

    # Create a wrapper script in bin, adjusting paths
    # Ensure PYTHONPATH includes both the app source and the libexec site-packages
    site_packages = Language::Python.site_packages(Formula["python@3.11"].opt_bin/"python3")
    # Construct the site-packages path within libexec
    libexec_site_packages = libexec/site_packages.sub(Formula["python@3.11"].opt_prefix, "")

    (bin/"33ter-backend").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{app_root}:#{libexec_site_packages}:$PYTHONPATH"
      exec "#{python_bin}/python3" "#{app_root}/start_local_dev.py" "$@"
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
