require 'RMagick'

module EffectiveTestBotScreenshotsHelper
  include Magick

  # Creates a screenshot based on the current test and the order in this test.
  def save_test_bot_screenshot
    return unless EffectiveTestBot.screenshots? && defined?(current_test)
    page.save_screenshot(current_test_temp_path + '/' + "#{current_test_screenshot_id}.png")
  end

  # # This is run before every test
  # def before_setup
  #   super
  #   return unless (EffectiveTestBot.screenshots? && defined?(current_test))

  #   # If we're in tour mode, delete all the old screenshots
  # end


  # This gets called after every test.  Minitest hook for plugin developers
  def after_teardown
    super
    return unless EffectiveTestBot.screenshots? && defined?(current_test) && (@test_bot_screenshot_id || 0) > 0

    if !passed? && EffectiveTestBot.autosave_animated_gif_on_failure?
      save_gif_for_failure
    end

    if passed? && EffectiveTestBot.tour_mode?
      save_gif_for_tour
    end
  end

  protected

  def save_gif_for_failure
    Dir.mkdir(current_test_failure_path) unless File.exists?(current_test_failure_path)

    full_path = (current_test_failure_path + '/' + current_test_failure_filename)

    animation = ImageList.new(*Dir[current_test_temp_path + '/*.png'].first(@test_bot_screenshot_id))
    animation.delay = 20 # delay 1/5 of a second between images.
    animation.write(full_path)

    puts_yellow("    Animated .gif: #{full_path}")
  end

  def save_gif_for_tour
    Dir.mkdir(current_test_tour_path) unless File.exists?(current_test_tour_path)

    full_path = (current_test_tour_path + '/' + current_test_tour_filename)

    animation = ImageList.new(*Dir[current_test_temp_path + '/*.png'].first(@test_bot_screenshot_id))
    animation.delay = 20 # delay 1/5 of a second between images.
    animation.write(full_path)

    puts("    TOUR .gif: #{full_path}")
  end

  private

  # There are 3 different paths we're working with
  # current_test_temp_path: contains individually numbered .png screenshots produced by capybara
  # current_test_tour_path: destination for .gifs of passing tests
  # current_test_failure_path: destination for .gifs of failing tests

  def current_test_temp_path
    File.join(Rails.root, 'tmp', 'test_bot', current_test)
  end

  def current_test_failure_path
    File.join(Rails.root, 'tmp', 'test_bot')
  end

  def current_test_failure_filename
    # Match Capybara-screenshots format-ish
    "#{current_test}_falure_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.gif"
  end

  # Where the tour animated gif ends up
  def current_test_tour_path
    File.join(Rails.root, 'test', 'tour')
  end

  def current_test_tour_filename
    current_test + '.gif'
  end

  # Auto incrementing counter
  def current_test_screenshot_id
    @test_bot_screenshot_id = (@test_bot_screenshot_id || 0) + 1

    if @test_bot_screenshot_id < 10
      "0#{@test_bot_screenshot_id}"
    else
      @test_bot_screenshot_id.to_s
    end
  end

  def puts_yellow(text)
    puts "\e[33m#{text}\e[0m" # 33 is yellow
  end

end
