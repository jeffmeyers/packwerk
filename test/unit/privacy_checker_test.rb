# typed: ignore
# frozen_string_literal: true

require "test_helper"

module Packwerk
  class PrivacyCheckerTest < Minitest::Test
    include ApplicationFixtureHelper
    include FactoryHelper

    setup do
      setup_application_fixture
      use_template(:skeleton)
      @reference_lister = CheckingDeprecatedReferences.new(app_dir)
    end

    teardown do
      teardown_application_fixture
    end

    test "ignores if destination package is not enforcing" do
      checker = privacy_checker
      reference = build_reference

      refute checker.invalid_reference?(reference, @reference_lister)
    end

    test "ignores if destination package is only enforcing for other constants" do
      destination_package = Package.new(
        name: "destination_package",
        config: { "enforce_privacy" => ["::OtherConstant"] }
      )
      checker = privacy_checker
      reference = build_reference(destination_package: destination_package)

      refute checker.invalid_reference?(reference, @reference_lister)
    end

    test "complains about private constant if enforcing privacy for everything" do
      destination_package = Package.new(name: "destination_package", config: { "enforce_privacy" => true })
      checker = privacy_checker
      reference = build_reference(destination_package: destination_package)

      assert checker.invalid_reference?(reference, @reference_lister)
    end

    test "complains about private constant if enforcing for specific constants" do
      destination_package = Package.new(name: "destination_package", config: { "enforce_privacy" => ["::SomeName"] })
      checker = privacy_checker
      reference = build_reference(destination_package: destination_package)

      assert checker.invalid_reference?(reference, @reference_lister)
    end

    test "complains about nested constant if enforcing for specific constants" do
      destination_package = Package.new(name: "destination_package", config: { "enforce_privacy" => ["::SomeName"] })
      checker = privacy_checker
      reference = build_reference(destination_package: destination_package)

      assert checker.invalid_reference?(reference, @reference_lister)
    end

    test "ignores constant that starts like enforced constant" do
      destination_package = Package.new(name: "destination_package", config: { "enforce_privacy" => ["::SomeName"] })
      checker = privacy_checker
      reference = build_reference(destination_package: destination_package, constant_name: "::SomeNameButNotQuite")

      refute checker.invalid_reference?(reference, @reference_lister)
    end

    test "ignores public constant even if enforcing privacy for everything" do
      destination_package = Package.new(name: "destination_package", config: { "enforce_privacy" => true })
      checker = privacy_checker
      reference = build_reference(destination_package: destination_package, public_constant: true)

      refute checker.invalid_reference?(reference, @reference_lister)
    end

    test "only checks the deprecated references file for private constants" do
      destination_package = Package.new(name: "destination_package", config: { "enforce_privacy" => ["::SomeName"] })
      checker = privacy_checker
      reference = build_reference(destination_package: destination_package)

      @reference_lister.expects(:listed?).with(reference, violation_type: ViolationType::Privacy).once

      checker.invalid_reference?(reference, @reference_lister)
    end

    private

    def privacy_checker
      PrivacyChecker.new
    end
  end
end
