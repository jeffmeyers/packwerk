# typed: true
# frozen_string_literal: true

require "test_helper"

module Packwerk
  class FileProcessorTest < Minitest::Test
    include FactoryHelper

    class StubChecker
      include ReferenceChecking::Checkers::Checker

      def initialize(**options)
        @is_invalid_reference = options[:invalid_reference?]
        @violation_type = options[:violation_type]
        @message = options[:message]
      end

      def violation_type
        @violation_type || ReferenceChecking::Checkers::DependencyChecker::VIOLATION_TYPE
      end

      def invalid_reference?(_reference)
        @is_invalid_reference
      end

      def message(_reference)
        @message
      end
    end

    test "#call enumerates the list of checkers to create ReferenceOffense objects" do
      input_reference = build_reference
      message = ReferenceChecking::Checkers::PrivacyChecker.new.message(input_reference)
      instance = reference_checker([StubChecker.new(
        invalid_reference?: true,
        message: message,
        violation_type: ReferenceChecking::Checkers::PrivacyChecker::VIOLATION_TYPE
      )])
      offenses = instance.call(input_reference)

      assert_equal 1, offenses.length

      offense = offenses.first
      assert_equal input_reference.relative_path, offense.file
      assert_equal input_reference.source_location, offense.location
      assert offense.message.start_with?("Privacy violation")
    end

    def reference_checker(checkers = [StubChecker.new])
      Packwerk::ReferenceChecking::ReferenceChecker.new(checkers)
    end
  end
end
