require File.expand_path('../../spec_helper', __FILE__)

module Danger::Dangerfile::DSL
  describe Proselint do
    it 'is a plugin' do
      (Proselint < Danger::Dangerfile::DSL::Plugin).should.be.true
    end
    
    it 'should have a description' do
      Proselint.description.should.equal("Run a PR through Proselint (http://proselint.com)")
    end
  end
end

