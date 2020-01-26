# frozen_string_literal: true

# Copyright 2019 Daniel Azuma
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
;

##
# Toys is a configurable command line tool. Write commands in config files
# using a simple DSL, and Toys will provide the command line executable and
# take care of all the details such as argument parsing, online help, and error
# reporting. Toys is designed for software developers, IT professionals, and
# other power users who want to write and organize scripts to automate their
# workflows. It can also be used as a Rake replacement, providing a more
# natural command line interface for your project's build tasks.
#
# This module contains the command line framework underlying Toys. It can be
# used to create command line executables using the Toys DSL and classes.
#
module Toys
  ##
  # Namespace for DSL classes. These classes provide the directives that can be
  # used in configuration files. Most are defined in {Toys::DSL::Tool}.
  #
  module DSL; end

  ##
  # Namespace for standard middleware classes.
  #
  module StandardMiddleware
    ## @private
    COMMON_FLAG_GROUP = :__common

    ## @private
    def self.append_common_flag_group(tool)
      tool.add_flag_group(type: :optional, name: COMMON_FLAG_GROUP,
                          desc: "Common Flags", report_collisions: false)
      COMMON_FLAG_GROUP
    end
  end

  ##
  # Namespace for standard mixin classes.
  #
  module StandardMixins; end

  ##
  # Namespace for common utility classes.
  #
  # These classes are not loaded by default, and must be required explicitly.
  # For example, before using {Toys::Utils::Exec}, you must
  # `require "toys/utils/exec"`.
  #
  module Utils; end

  class << self
    ##
    # Path to the executable. This can, for example, be invoked to run a subtool
    # in a clean environment.
    #
    # @return [String] if there is an executable
    # @return [nil] if there is no such executable
    #
    attr_accessor :executable_path
  end
end

require "toys/acceptor"
require "toys/arg_parser"
require "toys/cli"
require "toys/compat"
require "toys/completion"
require "toys/context"
require "toys/core"
require "toys/dsl/flag"
require "toys/dsl/flag_group"
require "toys/dsl/positional_arg"
require "toys/dsl/tool"
require "toys/errors"
require "toys/flag"
require "toys/flag_group"
require "toys/input_file"
require "toys/loader"
require "toys/middleware"
require "toys/mixin"
require "toys/module_lookup"
require "toys/positional_arg"
require "toys/source_info"
require "toys/template"
require "toys/tool"
require "toys/wrappable_string"
