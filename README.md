# danger-proselint

A description of danger-proselint.

## Installation

    $ gem install danger-proselint

## Usage

    Add it to your Dangerfile

    ```
    # Look through all changed Markdown files
    markdown_files = (modified_files + added_files).select do |line|
      line.start_with?("_posts") && (line.end_with?(".markdown") || line.end_with?(".md"))
    end
    
    # will check any .markdown files in this PR with proselint
    proselint.lint_files markdown_files
    ```
