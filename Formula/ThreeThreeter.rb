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
    # Copy the entire application source code into libexec *first*
    # This assumes the tarball unpacks with a top-level 'LocalBackend' directory
    libexec.install Dir["*"]

    # Create a virtual environment
    venv_dir = libexec/"venv"
    system Formula["python@3.11"].opt_bin/"python3", "-m", "venv", venv_dir
    venv_bin = venv_dir/"bin"
    ENV.prepend_path "PATH", venv_bin # Ensure pip uses the venv python

    # Define the path to requirements.txt *within* the installed libexec structure
    requirements_path = libexec/"LocalBackend/req/requirements.txt"

    # Check if requirements file exists before trying to install
    unless requirements_path.exist?
      odie "Requirements file not found at expected path: #{requirements_path}"
    end

    # Install dependencies from requirements.txt into the venv
    system venv_bin/"pip", "install", "--upgrade", "pip"
    system venv_bin/"pip", "install", "-r", requirements_path

    # Create a wrapper script in bin, adjusting paths
    (bin/"33ter-backend").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}/LocalBackend:$PYTHONPATH"
      exec "#{venv_bin}/python3" "#{libexec}/LocalBackend/start_local_dev.py" "$@"
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
    # Basic test: Check if the wrapper script exists and is executable
    assert_predicate bin/"33ter-backend", :exist?
    assert_predicate bin/"33ter-backend", :executable?
    # More comprehensive test could try running --version or a similar flag
    # system bin/"33ter-backend", "--version"
  end
end
