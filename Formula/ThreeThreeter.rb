# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
class Threethreeter < Formula
  desc "Local backend for the 33ter OCR code solution app"
  homepage "https://github.com/designerGenes/33ter_backend"
  # The URL points to the tarball for the tag
  url "https://github.com/designerGenes/33ter_backend/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "cedbb415fcfacafe7982f56795961e8839ebe090b4842242c80334a1331df154"
  license "MIT"
  version "0.1.0"

  depends_on "python@3.11"
  depends_on "tesseract"
  depends_on "tesseract-lang"

  def install
    # Homebrew automatically unpacks the tarball. The contents will be in a
    # directory like '33ter_backend-0.1.0' within the formula's cellar path,
    # which libexec points to. We don't need libexec.install Dir["*"].

    # Define the root directory *within* libexec based on the unpacked tarball structure
    # Formula.name gives 'threethreeter', version gives '0.1.0'
    # However, GitHub archives use the repo name and tag: '33ter_backend-0.1.0'
    # It's safer to determine this dynamically or hardcode if consistent.
    # Let's assume the consistent GitHub archive naming:
    app_root = libexec/"33ter_backend-#{version}"

    # Create a virtual environment *within* the app root or alongside it in libexec
    # Putting it in libexec alongside the app root is cleaner
    venv_dir = libexec/"venv"
    system Formula["python@3.11"].opt_bin/"python3", "-m", "venv", venv_dir
    venv_bin = venv_dir/"bin"
    # No need to prepend PATH here, we call pip directly using venv_bin

    # Define the path to requirements.txt relative to the app_root
    requirements_path = app_root/"req/requirements.txt"

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
      export PYTHONPATH="#{app_root}:$PYTHONPATH"
      exec "#{venv_bin}/python3" "#{app_root}/start_local_dev.py" "$@"
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
    # A better test might be to check if the python script can be found
    # or if running with --version (if implemented) works.
    # system bin/"33ter-backend", "--version"
  end
end
