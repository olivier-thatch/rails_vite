require "test_helper"

class TasksTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @dir = Dir.mktmpdir
    Dir.chdir(@dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@dir)
  end

  def test_detects_bun_from_bun_lockb
    FileUtils.touch("bun.lockb")
    assert_equal :bun, RailsVite::Tasks.tool
  end

  def test_detects_bun_from_bun_lock
    FileUtils.touch("bun.lock")
    assert_equal :bun, RailsVite::Tasks.tool
  end

  def test_detects_yarn_from_yarn_lock
    FileUtils.touch("yarn.lock")
    assert_equal :yarn, RailsVite::Tasks.tool
  end

  def test_detects_pnpm_from_pnpm_lock
    FileUtils.touch("pnpm-lock.yaml")
    assert_equal :pnpm, RailsVite::Tasks.tool
  end

  def test_detects_npm_from_package_lock
    FileUtils.touch("package-lock.json")
    assert_equal :npm, RailsVite::Tasks.tool
  end

  def test_bun_lockfile_takes_priority
    FileUtils.touch("bun.lockb")
    FileUtils.touch("yarn.lock")
    assert_equal :bun, RailsVite::Tasks.tool
  end

  def test_install_command
    FileUtils.touch("yarn.lock")
    assert_equal "yarn install", RailsVite::Tasks.install_command
  end

  def test_dev_command
    FileUtils.touch("yarn.lock")
    assert_equal "yarn vite", RailsVite::Tasks.dev_command
  end

  def test_build_command
    FileUtils.touch("yarn.lock")
    assert_equal "yarn vite build", RailsVite::Tasks.build_command
  end

  def test_add_command_appends_packages
    FileUtils.touch("yarn.lock")
    assert_equal "yarn add -D vite @vitejs/plugin-react", RailsVite::Tasks.add_command("vite", "@vitejs/plugin-react")
  end

  def test_npm_commands
    FileUtils.touch("package-lock.json")
    assert_equal "npm install", RailsVite::Tasks.install_command
    assert_equal "npm install -D vite", RailsVite::Tasks.add_command("vite")
    assert_equal "npx vite", RailsVite::Tasks.dev_command
    assert_equal "npx vite build", RailsVite::Tasks.build_command
  end

  def test_pnpm_commands
    FileUtils.touch("pnpm-lock.yaml")
    assert_equal "pnpm install", RailsVite::Tasks.install_command
    assert_equal "pnpm add -D vite", RailsVite::Tasks.add_command("vite")
    assert_equal "pnpm vite", RailsVite::Tasks.dev_command
    assert_equal "pnpm vite build", RailsVite::Tasks.build_command
  end

  def test_build_command_adds_mode_test_in_test
    FileUtils.touch("yarn.lock")
    with_env("test") do
      assert_equal "yarn vite build --mode test", RailsVite::Tasks.build_command
    end
  end

  def test_build_command_uses_custom_build_mode
    FileUtils.touch("yarn.lock")
    with_config(build_mode: "e2e") do
      assert_equal "yarn vite build --mode e2e", RailsVite::Tasks.build_command
    end
  end

  def test_build_command_has_no_mode_when_build_mode_is_nil
    FileUtils.touch("yarn.lock")
    with_env("test") do
      with_config(build_mode: nil) do
        assert_equal "yarn vite build", RailsVite::Tasks.build_command
      end
    end
  end

  def test_build_env_sets_build_dir
    assert_equal({"RAILS_VITE_BUILD_DIR" => "vite"}, RailsVite::Tasks.build_env)
  end

  def test_build_env_keeps_test_build_dir_without_mode_test
    with_env("test") do
      with_config(build_mode: nil) do
        assert_equal({"RAILS_VITE_BUILD_DIR" => "vite-test"}, RailsVite::Tasks.build_env)
        assert_equal Rails.root.join("public/vite-test/manifest.json"), RailsVite.config.manifest_path
      end
    end
  end

  def test_build_env_uses_custom_build_dir
    with_config(build_dir: "assets") do
      assert_equal({"RAILS_VITE_BUILD_DIR" => "assets"}, RailsVite::Tasks.build_env)
    end
  end

  private

  def with_env(env, &block)
    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new(env), &block)
  end

  def with_config(**options, &block)
    config = RailsVite::Config.new
    options.each { |key, value| config.public_send(:"#{key}=", value) }
    RailsVite.stub(:config, config, &block)
  end
end
