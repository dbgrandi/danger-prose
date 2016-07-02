require 'JSON'

module Danger
  # Lint markdown files inside your projects.
  # This is done using the [proselint](http://proselint.com) python egg.
  # Results are passed out as a table in markdown.
  #
  # @example Specifying custom CocoaPods installation options
  #
  #          # Runs a linter with comma style disabled
  #          proselint.disable_linters = ["misc.scare_quotes", "misc.tense_present"]
  #          proselint.lint_files "_posts/*.md"
  #
  #          # Runs a linter with all styles, on modified and added markdown files in this PR
  #          proselint.lint_files
  #
  # @see  artsy/artsy.github.io
  # @tags blogging, blog, writing, jekyll, middleman, hugo, metalsmith, gatsby, express
  #
  class DangerProse < Plugin
    # Allows you to disable a collection of linters from running. Doesn't work yet.
    # You can get a list of [them here](https://github.com/amperser/proselint#checks)
    attr_accessor :disable_linters

    # Lints the globbed markdown files. Will fail if `proselint` cannot be installed correctly.
    # Generates a `markdown` list of warnings for the prose in a corpus of .markdown and .md files.
    #
    # @param   [String] files
    #          A globbed string which should return the files that you want to lint, defaults to nil.
    #          if nil, modified and added files from the diff will be used.
    # @return  [void]
    #
    def lint_files(files = nil)
      # Installs a prose checker if needed
      system 'pip install --user proselint' unless proselint_installed?

      # Check that this is in the user's PATH after installing
      unless proselint_installed?
        raise "proselint is not in the user's PATH, or it failed to install"
        return
      end

      # Either use files provided, or use the modified + added
      markdown_files = files ? Dir.glob(files) : (git.modified_files + git.added_files)
      markdown_files.select! { |line| (line.end_with?('.markdown') || line.end_with?('.md')) }

      # Create the disabled linters JSON in ~/.proselintrc
      proselint_template = File.expand_path('proselintrc', __FILE__)
      proselintJSON = JSON.parse(File.read(proselint_template))
      disable_linters.each do |linter|
        proselintJSON['checks'][linter] = false
      end
      temp_proselint_rc_path = File.join(Dir.home, '.proselintrc')
      File.write(temp_proselint_rc_path, proselintJSON.to_s)

      # Convert paths to proselint results
      result_jsons = Hash[markdown_files.uniq.collect { |v| [v, JSON.parse(`proselint #{v} --json`.strip)] }]
      proses = result_jsons.select { |_, prose| prose['data']['errors'].count }

      # Delete .proselintrc
      File.unlink temp_proselint_rc_path

      # Get some metadata about the local setup
      current_slug = env.ci_source.repo_slug

      # We got some error reports back from proselint
      if proses.count > 0
        message = '### Proselint found issues\n\n'
        proses.each do |path, prose|
          github_loc = "/#{current_slug}/tree/#{github.branch_for_base}/#{path}"
          message << "#### [#{path}](#{github_loc})\n\n"

          message << 'Line | Message | Severity |\n'
          message << '| --- | ----- | ----- |\n'

          prose['data']['errors'].each do |error|
            message << "#{error['line']} | #{error['message']} | #{error['severity']}\n"
          end
        end

        markdown message
      end
    end

    # Determine if proselint is currently installed in the system paths.
    # @return  [Bool]
    #
    def proselint_installed?
      `which proselint`.strip.empty? == false
    end
  end
end
