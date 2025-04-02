class Threethreeter < Formula
  desc "Local backend for the 33ter OCR code solution app"
  homepage "https://github.com/designerGenes/33ter_backend"
  url "https://github.com/designerGenes/33ter_backend/releases/download/v0.1.2/33ter_backend-0.1.2.tar.gz"
  sha256 "a9fca66bb8c2f7dbb3d0788950ebc5aefbc274d8e819139bbcdb9787df86ff22"
  license "MIT"
  version "0.1.2"

  depends_on "python@3.11"
  depends_on "tesseract"
  depends_on "tesseract-lang"

  def install
    # Change directory into the extracted folder (usually a single subdirectory)
    cd Dir["*"].first do
      requirements_path = Pathname.pwd/"req/requirements.txt"
      unless requirements_path.exist?
        odie "Requirements file not found at expected path: #{requirements_path}. Check tarball structure and directory listing."
      end

      # Install Python dependencies into libexec using Homebrew's Python pip
      python_bin = Formula["python@3.11"].opt_bin
      system python_bin/"pip3", "install", "--verbose", "-r", requirements_path, "--prefix=#{libexec}"

      # Copy the source files from the subdirectory into libexec
      libexec.install Dir["*"]
    end

    # Determine the site-packages path for dependencies installed in libexec
    site_packages = Language::Python.site_packages(Formula["python@3.11"].opt_bin/"python3")
    libexec_site_packages = (libexec/site_packages).to_s.sub(Formula["python@3.11"].opt_prefix.to_s, "")

    # Create a wrapper script in bin that sets PYTHONPATH and runs the main script
    python_bin = Formula["python@3.11"].opt_bin
    (bin/"33ter-backend").write <<~EOS
      #!/bin/bash
      # Add libexec (for source) and its site-packages (for dependencies) to PYTHONPATH
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
    # Optionally, test the script with a flag like --help:
    # system bin/"33ter-backend", "--help"
  end
end