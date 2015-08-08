require "effective_test_bot/engine"
require "effective_test_bot/version"

module EffectiveTestBot
  mattr_accessor :except
  mattr_accessor :only

  def self.setup
    yield self
  end

  def self.skip?(test, assertion = nil)
    value = [test.to_s.presence, assertion.to_s.presence].compact.join(' ')
    return false if value.blank?

    if onlies.present?
      onlies.find { |only| only == value }.blank?
    elsif excepts.present?
      excepts.find { |except| except == value }.present?
    else
      false
    end
  end

  private

  def self.onlies
    @@onlies ||= flatten_and_sort(only)
  end

  def self.excepts
    @@excepts ||= flatten_and_sort(except)
  end

    # config.except = [
    #   'assert_path',
    #   'users#show',
    #   'users#create_invalid' => ['assert_path'],
    #   'users#create_invalid' => 'assert_unpermitted_params',
    #   'report_total_allocation_index_path'
    # ]

    # We need to flatten any Hashes into
    #   'users#create_invalid' => ['assert_path', 'assert_page_title'],
    # into this
    # ['users#create_invalid assert_path'
    # 'users#create_invalid assert_page_title']

  def self.flatten_and_sort(skips)
    Array(skips).flat_map do |skip|
      case skip
      when Symbol
        skip.to_s
      when Hash
        skip.keys.product(skip.values.flatten).map { |p| p.join(' ') }
      else
        skip
      end
    end.compact.sort
  end

end
