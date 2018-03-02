require File.expand_path('../spec_helper', __FILE__)

module Danger
  describe DangerProse do
    it 'is a plugin' do
      expect(Danger::DangerProse < Danger::Plugin).to be_truthy
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @prose = testing_dangerfile.prose
      end

      describe 'linter' do
        it 'handles proselint not being installed' do
          allow(@prose).to receive(:`).with('which proselint').and_return('')
          expect(@prose.proselint_installed?).to be_falsy
        end

        it 'handles proselint being installed' do
          allow(@prose).to receive(:`).with('which proselint').and_return('/bin/thing/proselint')
          expect(@prose.proselint_installed?).to be_truthy
        end

        describe :lint_files do
          before do
            # So it doesn't try to install on your computer
            allow(@prose).to receive(:`).with('which proselint').and_return('/bin/thing/proselint')

            # Proselint returns JSON data, which is nice 👍
            errors = '[{"start": 1441, "replacements": null, "end": 1445, "severity": "warning", "extent": 4, "column": 1, "message": "!!! is hyperbolic.", "line": 46, "check": "hyperbolic.misc"}]'
            proselint_response = '{"status" : "success", "data" : { "errors" : ' + errors + '}}'

            # This is where we generate our JSON
            allow(@prose).to receive(:`).with('proselint "spec/fixtures/blog_post.md" --json').and_return(proselint_response)

            # it's worth noting - you can call anything on your plugin that a Dangerfile responds to
            # The request source's PR JSON typically looks like
            # https://raw.githubusercontent.com/danger/danger/bffc246a11dac883d76fc6636319bd6c2acd58a3/spec/fixtures/pr_response.json

            @prose.env.request_source.pr_json = { "head" => { "ref" => 'my_fake_branch' } }
          end

          it 'handles a known JSON report from proselint' do
            @prose.lint_files('spec/fixtures/*.md')
            output = @prose.status_report[:markdowns].first

            # A title
            expect(output.message).to include('Proselint found issues')
            # A warning
            expect(output.message).to include('!!! is hyperbolic. | warning')
            # A link to the file inside the fixtures dir
            expect(output.message).to include('[spec/fixtures/blog_post.md](/artsy/eigen/tree/my_fake_branch/spec/fixtures/blog_post.md)')
          end
        end
      end

      describe 'spell checking' do
        it 'handles proselint not being installed' do
          allow(@prose).to receive(:`).with('which mdspell').and_return('')
          expect(@prose.mdspell_installed?).to be_falsy
        end

        it 'handles proselint being installed' do
          allow(@prose).to receive(:`).with('which mdspell').and_return('/bin/thing/mdspell')
          expect(@prose.mdspell_installed?).to be_truthy
        end

        describe 'full command' do
          before do
            # So it doesn't try to install on your computer
            allow(@prose).to receive(:`).with('which mdspell').and_return('/bin/thing/mdspell')

            # mdspell returns JSON data, which is nice 👍
            proselint_response = "    spec/fixtures/blog_post.md\n        1:27 | This post intentional left blank-ish.\n        4:84 | Here's a tpyo - it should registor.\n        4:101 | Here's a tpyo - it should registor.\n\n >> 3 spelling errors found in 1 file"

            # This is where we generate our JSON
            allow(@prose).to receive(:`).with('mdspell spec/fixtures/blog_post.md -r --en-gb').and_return(proselint_response)

            # it's worth noting - you can call anything on your plugin that a Dangerfile responds to
            # The request source's PR JSON typically looks like
            # https://raw.githubusercontent.com/danger/danger/bffc246a11dac883d76fc6636319bd6c2acd58a3/spec/fixtures/pr_response.json

            @prose.env.request_source.pr_json = { "head" => { "ref" => 'my_fake_branch' } }
          end

          it 'handles a known JSON report from mdspell' do
            @prose.check_spelling('spec/fixtures/*.md')
            output = @prose.status_report[:markdowns].first

            # A title
            expect(output.message).to include('Spell Checker found issues')
            # A typo, in bold
            expect(output.message).to include('**tpyo**')
            # A link to the file inside the fixtures dir
            expect(output.message).to include('[spec/fixtures/blog_post.md](/artsy/eigen/tree/my_fake_branch/spec/fixtures/blog_post.md)')
          end
        end
      end
    end
  end
end
