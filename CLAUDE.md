# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`openbox` is a Ruby gem: a zero-configuration container entrypoint for Rack/Rails apps. Host apps run `bin/openbox server` (etc.) as their Docker `ENTRYPOINT`. Only runtime deps are `thor` and `dotenv`; Rails is deliberately **never** loaded by openbox itself to keep boot fast.

## Commands

```bash
bin/setup                                  # bundle install
bundle exec rake                           # rspec (default task), SimpleCov enabled
bundle exec rspec spec/openbox/runtime_spec.rb            # single file
bundle exec rspec spec/openbox/runtime_spec.rb:12         # single example
bundle exec rubocop                        # lint (CI fails on any offense; TargetRubyVersion 2.5, NewCops enabled)
bundle exec rubocop -A path/to/file.rb     # autocorrect changed Ruby files only
bundle exec rake install                   # install gem locally
bundle exec rake release                   # bump lib/openbox/version.rb first; tags + pushes to rubygems
```

Git hooks are managed by `overcommit` (`.overcommit.yml`): RuboCop (warnings fail), trailing whitespace, bundle-audit. CI runs RuboCop plus RSpec on Ruby 2.6–3.1.

## Architecture

Boot order matters because command registration is conditional on the host app's Gemfile:

1. `exe/openbox` requires `openbox`, then `require`s every file under the **host app's** `lib/openbox/commands/**/*.rb` (custom commands), then calls `Openbox::Entrypoint.start(ARGV)`.
2. `lib/openbox.rb` defines two lazily built, mutex-guarded singletons:
   - `Openbox.runtime` → `Runtime.new(Bundler.definition.current_dependencies)`. `has?`/`select` only consider gems in the `:default` group plus the group named by `RAILS_ENV`/`RACK_ENV`.
   - `Openbox.database` → `Database`. `ensure_connection!` is a no-op unless `pg` or `mysql2` is a dependency; otherwise it retries connecting to `DATABASE_URL` for 30s then `exit 1`.
   - It requires `openbox/entrypoint` **last**, so the singletons exist when commands register.
3. `Openbox::Entrypoint < Thor` requires each built-in command file. Each file defines `Openbox::Commands::X < Openbox::Command` (a `Thor::Group`) and calls `Openbox::Entrypoint.register(...)` **only if** `Openbox.runtime.has?(...)` for the relevant gem. So the same gem exposes different subcommands depending on the host app.

`Openbox::Command#before_execute` loads Docker Swarm secret files (`/run/secrets/<name>` for each name in `SWARM_SECRETS`) via Dotenv. Every built-in `execute` calls `Openbox.database.ensure_connection!` first, then `exec`s (replaces the process) or `system`s a `bundle exec ...` command. `Server` additionally `invoke`s `Migrate` when `AUTO_MIGRATION` is set and picks `rails server -b 0.0.0.0` vs `rackup -o 0.0.0.0` based on `Openbox.runtime.rails?`.

### Adding a built-in command

Create `lib/openbox/commands/<name>.rb` following the existing pattern (class + guarded `register`), then add the `require` to `lib/openbox/entrypoint.rb`. Update the commands table in `README.md`.

## Testing notes

Specs construct `Runtime` directly with stub dependency objects rather than relying on Bundler; `Database` specs stub `Openbox.runtime`. `spec_helper` uses `disable_monkey_patching!`, so use `RSpec.describe`, not bare `describe`.
