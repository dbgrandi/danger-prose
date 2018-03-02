require 'json'

module Danger
  # Lint markdown files inside your projects.
  # This is done using the [proselint](http://proselint.com) python egg.
  # Results are passed out as a table in markdown.
  #
  # @example Running linter with custom disabled linters
  #
  #          # Runs a linter with comma style and tense present disabled
  #          prose.disable_linters = ["misc.scare_quotes", "misc.tense_present"]
  #          prose.lint_files "_posts/*.md"
  #
  # @example Running linter with default linters
  #
  #          # Runs a linter with all styles, on modified and added markdown files in this PR
  #          prose.lint_files
  #
  # @example Running the spell checker
  #
  #          # Runs a spell checker on all files in `_post`
  #          prose.check_spelling "_posts/*.md"
  #
  # @example Running the spell checker, with some words whitelisted
  #
  #          prose.ignored_words = ["orta", "artsy"]
  #          prose.check_spelling
  #
  # @see  artsy/artsy.github.io
  # @tags blogging, blog, writing, jekyll, middleman, hugo, metalsmith, gatsby, express
  #
  class DangerProse < Plugin
    # Allows you to disable a collection of linters from running. Doesn't work yet.
    # You can get a list of [them here](https://github.com/amperser/proselint#checks)
    # defaults to `["misc.scare_quotes", "typography.symbols"]` when it's nil.
    #
    # @return   [Array<String>]
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
      raise "proselint is not in the user's PATH, or it failed to install" unless proselint_installed?

      # Either use files provided, or use the modified + added
      markdown_files = get_files files

      proses = {}
      to_disable = disable_linters || ["misc.scare_quotes", "typography.symbols"]
      with_proselint_disabled(to_disable) do
        # Convert paths to proselint results
        result_jsons = Hash[markdown_files.to_a.uniq.collect { |v| [v, get_proselint_json(v)] }]
        proses = result_jsons.select { |_, prose| prose['data']['errors'].count > 0 }
      end

      # Get some metadata about the local setup
      current_slug = env.ci_source.repo_slug

      # We got some error reports back from proselint
      if proses.count > 0
        message = "### Proselint found issues\n\n"
        proses.each do |path, prose|
          github_loc = "/#{current_slug}/tree/#{github.branch_for_head}/#{path}"
          message << "#### [#{path}](#{github_loc})\n\n"

          message << "Line | Message | Severity |\n"
          message << "| --- | ----- | ----- |\n"

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

    # Determine if mdspell is currently installed in the system paths.
    # @return  [Bool]
    #
    def mdspell_installed?
      `which mdspell`.strip.empty? == false
    end

    # Allows you to add a collection of words to skip in spellchecking.
    # defaults to `[""]` when it's nil.
    # @return [Array<String>]
    attr_accessor :ignored_words
    
    # Allows you to specify that you want to ignore reporting numbers
    # as spelling errors. Defaults to `false`, switch it to `true`
    # if you wish to ignore numbers.
    # @return false
    attr_accessor :ignore_numbers
    
    # Allows you to specify that you want to ignore acronyms as spelling
    # errors. Defaults to `false`, switch it to `true` if you wish
    # to ignore acronyms.
    # @return false
    attr_accessor :ignore_acronyms
    
    # Allows you to specify dictionary language to use for spell-checking.
    # Defaults to `en-gb`, switch to `en-us`, `en-au` or `es-es`, to
    # override.
    attr_accessor :language
    
    def language
      @language || 'en-gb'
    end

    # Runs a markdown-specific spell checker, against a corpus of `.markdown` and `.md` files.
    #
    # @param   [String] files
    #          A globbed string which should return the files that you want to spell check, defaults to nil.
    #          if nil, modified and added files from the diff will be used.
    # @return  [void]
    #
    def check_spelling(files = nil)
      # Installs my fork of the spell checker if needed
      # my fork has line numbers + indexes
      system "npm install -g orta/node-markdown-spellcheck" unless mdspell_installed?

      # Check that this is in the user's PATH after installing
      raise "mdspell is not in the user's PATH, or it failed to install" unless mdspell_installed?

      markdown_files = get_files files

      arguments = ["-r"]
      skip_words = ignored_words || []

      arguments.push("-n") if ignore_numbers
      arguments.push("-a") if ignore_acronyms
      arguments.push("--#{language}")

      File.write(".spelling", skip_words.join("\n"))
      result_texts = Hash[markdown_files.to_a.uniq.collect { |md| [md, `mdspell #{md} #{arguments.join(" ")}`.strip] }]
      spell_issues = result_texts.select { |path, output| output.include? "spelling errors found" }
      File.unlink(".spelling")

      # Get some metadata about the local setup
      current_slug = env.ci_source.repo_slug

      if spell_issues.count > 0
        message = "### Spell Checker found issues\n\n"
        spell_issues.each do |path, output|
          github_loc = "/#{current_slug}/tree/#{github.branch_for_head}/#{path}"
          message << "#### [#{path}](#{github_loc})\n\n"

          message << "Line | Typo |\n"
          message << "| --- | ------ |\n"

          output.lines[1..-3].each do |line|
            index_info = line.strip.split("|").first
            index_line, index = index_info.split(":").map { |n| n.to_i }

            file = File.read(path)

            unknown_word = file[index..-1].split(" ").first

            error_text = line.strip.split("|")[1..-1].join("|").strip
            error = error_text.gsub(unknown_word, "**" + unknown_word + "**")

            message << "#{index_line} | #{error} | \n"
          end
          markdown message
        end
      end
    end

    private
    # Creates a temporary proselint settings file
    # @return  void
    #
    def with_proselint_disabled(disable_linters)
      # Create the disabled linters JSON in ~/.proselintrc
      proselint_template = File.join(File.dirname(__FILE__), 'proselintrc')
      proselintJSON = JSON.parse(File.read(proselint_template))

      # Disable individual linters
      disable_linters.each do |linter|
        proselintJSON['checks'][linter] = false
      end

      # Re-save the new JSON into the home dir
      temp_proselint_rc_path = File.join(Dir.home, '.proselintrc')
      File.write(temp_proselint_rc_path, JSON.pretty_generate(proselintJSON))

      # Run the closure
      yield

      # Delete .proselintrc
      File.unlink temp_proselint_rc_path
    end

    def get_files files
      # Either use files provided, or use the modified + added
      markdown_files = files ? Dir.glob(files) : (git.modified_files + git.added_files)
      markdown_files.select { |line| line.end_with? '.markdown', '.md' }
    end

    # Always returns a hash, regardless of whether the command gives JSON, weird data, or no response
    def get_proselint_json path
      json = `proselint "#{path}" --json`.strip
      if json[0] == "{" and json[-1] == "}"
        JSON.parse json
      else
        {}
      end
    end
  end
end
