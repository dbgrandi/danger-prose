# danger-prose

A description of danger-prose.

## Installation

    $ gem install danger-prose

### prose

Lint markdown files inside your projects.
This is done using the [proselint](http://proselint.com) python egg.
Results are passed out as a table in markdown.

<blockquote>Running linter with custom disabled linters
  <pre>
# Runs a linter with comma style and tense present disabled
prose.disable_linters = ["misc.scare_quotes", "misc.tense_present"]
prose.lint_files "_posts/*.md"</pre>
</blockquote>

<blockquote>Running linter with default linters
  <pre>
# Runs a linter with all styles, on modified and added markdown files in this PR
prose.lint_files</pre>
</blockquote>

<blockquote>Running the spell checker
  <pre>
# Runs a spell checker on all files in `_post`
prose.check_spelling "_posts/*.md"</pre>
</blockquote>

<blockquote>Running the spell checker, with some words whitelisted
  <pre>
prose.ignored_words = ["orta", "artsy"]
prose.lint_files</pre>
</blockquote>



#### Attributes
`disable_linters` - Allows you to disable a collection of linters from running. Doesn't work yet.
You can get a list of [them here](https://github.com/amperser/proselint#checks)
defaults to `["misc.scare_quotes", "typography.symbols"]` when it's nil.

`ignored_words` - Allows you to add a collection of words to skip in spellchecking.
defaults to `[""]` when it's nil.



#### Methods

`lint_files` - Lints the globbed markdown files. Will fail if `proselint` cannot be installed correctly.
Generates a `markdown` list of warnings for the prose in a corpus of .markdown and .md files.

`proselint_installed?` - Determine if proselint is currently installed in the system paths.

`mdspell_installed?` - Determine if mdspell is currently installed in the system paths.

`check_spelling` - Runs a markdown-specific spell checker, against a corpus of `.markdown` and `.md` files.

