require 'spec_helper'
require 'pact/tasks/verification_task'

module Pact
  describe VerificationTask do
    before :all do
      @support_file = nil
      @pact_helper = '/custom/path/support_file.rb'
      @pact_uri = 'http://example.org/pact.json'
      @task_name = 'pact:verify:pact_rake_spec'
      @task_name_with_explict_support_file = 'pact:verify:pact_rake_spec_with_explict_support_file'
      @consumer = 'some-consumer'
      @criteria = {:description => /wiffle/}

      VerificationTask.new(:pact_rake_spec_with_explict_support_file) do | pact |
        pact.uri @pact_uri, support_file: @support_file, pact_helper: @pact_helper
      end

      VerificationTask.new(:pact_rake_spec) do | pact |
        pact.uri @pact_uri
      end
    end

    after :each do
      ENV.delete 'PACT_DESCRIPTION'
    end

    before do
      ENV['PACT_DESCRIPTION'] = 'wiffle'
      VerificationTask.any_instance.stub(:publish_report)
      Provider::PactSpecRunner.stub(:new).with(consumer_contract, options).and_return(pact_spec_runner)
    end

    let(:pact_spec_runner) { double('PactSpecRunner', :run => exit_code, :output => nil)}
    let(:exit_code) {0}
    let(:consumer_contract) { [ uri: @pact_uri, support_file: nil, pact_helper: nil ] }
    let(:options) { {criteria: @criteria} }


    describe '.initialize' do
      context 'with an explict support_file' do
        it 'creates the tasks' do
          Rake::Task.tasks.should include_task @task_name
        end
      end
      context 'with no explict support_file' do
        it 'creates the tasks' do
          Rake::Task.tasks.should include_task @task_name_with_explict_support_file
        end
      end
    end

    describe 'execute' do


      context "with no explicit support file " do
        it 'verifies the pacts using PactSpecRunner' do
          Rake::Task[@task_name].execute
        end
      end

      context "with an explict support_file" do
        let(:consumer_contract) { [ uri: @pact_uri, support_file: @support_file, pact_helper: @pact_helper] }
        it 'verifies the pacts using PactSpecRunner' do
          Rake::Task[@task_name_with_explict_support_file].execute
        end
      end

      context "with criteria" do
        it 'passes the criteria to the PactSpecRunner as regexes' do
          ENV.delete 'PACT_DESCRIPTION'
          Provider::PactSpecRunner.should_receive(:new).with(
            consumer_contract, {
              criteria: {
                description: /stuff/,
                provider_state: /things/
              }
            }
          ).and_return(pact_spec_runner)
          Rake::Task[@task_name].execute(description: 'stuff', provider_state: 'things')
        end
      end

      context 'when all specs pass' do

        it 'does not raise an exception' do
          Rake::Task[@task_name].execute
        end
      end

      context 'when one or more specs fail' do

        let(:exit_code) {1}

        it 'raises an exception' do
          $stderr.should_receive(:puts) #Confusing if this shows on the screen!
          expect { Rake::Task[@task_name].execute }.to raise_error RuntimeError
        end

      end
    end
  end
end

RSpec::Matchers.define :include_task do |expected|
  match do |actual|
    actual.any? { |task| task.name == expected }
  end
end
