# Copyright 2018 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
;

require "logger"

module Toys
  ##
  # The object context in effect during the execution of a tool.
  #
  # The context is generally a hash of key-value pairs.
  # Keys that begin with two underscores are reserved common elements of the
  # context such as the tool being executed, or the verbosity level.
  # Other keys are available for use by your tool. Generally, they are set
  # by switches and arguments in your tool. Context values may also be set
  # by middleware. By convention, middleware-set keys begin with a single
  # underscore.
  #
  class Context
    ##
    # Context key for the verbosity value. Verbosity is an integer defaulting
    # to 0, with higher values meaning more verbose and lower meaning quieter.
    # @return [Symbol]
    #
    VERBOSITY = :__verbosity

    ##
    # Context key for the `Toys::Tool` object being executed.
    # @return [Symbol]
    #
    TOOL = :__tool

    ##
    # Context key for the full name of the tool being executed. Value is an
    # array of strings.
    # @return [Symbol]
    #
    TOOL_NAME = :__tool_name

    ##
    # Context key for the active `Toys::Loader` object.
    # @return [Symbol]
    #
    LOADER = :__loader

    ##
    # Context key for the active `Logger` object.
    # @return [Symbol]
    #
    LOGGER = :__logger

    ##
    # Context key for the name of the toys binary. Value is a string.
    # @return [Symbol]
    #
    BINARY_NAME = :__binary_name

    ##
    # Context key for the argument list passed to the current tool. Value is
    # an array of strings.
    # @return [Symbol]
    #
    ARGS = :__args

    ##
    # Context key for the usage error raised. Value is a string if there was
    # an error, or nil if there was no error.
    # @return [Symbol]
    #
    USAGE_ERROR = :__usage_error

    ##
    # Create a Context object. Applications generally will not need to create
    # these objects directly; they are created by the tool when it is preparing
    # for execution.
    # @private
    #
    # @param [Toys::Context::Base] context_base
    # @param [Hash] data
    #
    def initialize(context_base, data)
      @_context_base = context_base
      @_data = data
      @_data[LOADER] = context_base.loader
      @_data[BINARY_NAME] = context_base.binary_name
      @_data[LOGGER] = context_base.logger
    end

    ##
    # Return the verbosity as an integer.
    # @return [Integer]
    #
    def verbosity
      @_data[VERBOSITY]
    end

    ##
    # Return the tool being executed.
    # @return [Toys::Tool]
    #
    def tool
      @_data[TOOL]
    end

    ##
    # Return the name of the tool being executed, as an array of strings.
    # @return [Array[String]]
    #
    def tool_name
      @_data[TOOL_NAME]
    end

    ##
    # Return the raw arguments passed to the tool, as an array of strings.
    # This does not include the tool name itself.
    # @return [Array[String]]
    #
    def args
      @_data[ARGS]
    end

    ##
    # Return any usage error detected during argument parsing, or `nil` if
    # no error was detected.
    # @return [String,nil]
    #
    def usage_error
      @_data[USAGE_ERROR]
    end

    ##
    # Return the logger for this execution.
    # @return [Logger]
    #
    def logger
      @_data[LOGGER]
    end

    ##
    # Return the active loader that can be used to get other tools.
    # @return [Toys::Loader]
    #
    def loader
      @_data[LOADER]
    end

    ##
    # Return the name of the binary that was executed.
    # @return [String]
    #
    def binary_name
      @_data[BINARY_NAME]
    end

    ##
    # Return a piece of raw data by key.
    #
    # @param [Symbol] key
    # @return [Object]
    #
    def [](key)
      @_data[key]
    end

    ##
    # Set a piece of data by key.
    #
    # Most tools themselves will not need to do this directly. It is generally
    # used by middleware to modify the context and affect execution of tools
    # that use it.
    #
    # @param [Symbol] key
    # @param [Object] value
    #
    def []=(key, value)
      @_data[key] = value
    end

    ##
    # Return an option value by key.
    #
    # @param [Symbol] key
    # @return [Object]
    #
    def option(key)
      @_data[key]
    end

    ##
    # Returns the subset of the context that does not include well-known keys
    # such as tool and verbosity. Technically, this includes all keys that do
    # not begin with two underscores.
    #
    # @return [Hash]
    #
    def options
      @_data.select do |k, _v|
        !k.is_a?(::Symbol) || !k.to_s.start_with?("__")
      end
    end

    ##
    # Execute another tool, given by the provided arguments.
    #
    # @param [String...] args Command line arguments defining another tool
    #     to run, along with parameters and switches.
    # @param [Boolean] exit_on_nonzero_status If true, exit immediately if the
    #     run returns a nonzero error code.
    # @return [Integer] The resulting status code
    #
    def run(*args, exit_on_nonzero_status: false)
      code = @_context_base.run(args.flatten, verbosity: @_data[VERBOSITY])
      exit(code) if exit_on_nonzero_status && !code.zero?
      code
    end

    ##
    # Exit immediately with the given status code
    #
    # @param [Integer] code The status code, which should be 0 for no error,
    #     or nonzero for an error condition.
    #
    def exit(code)
      throw :result, code
    end

    ##
    # Common context data
    # @private
    #
    class Base
      def initialize(loader, binary_name, logger)
        @loader = loader
        @binary_name = binary_name || ::File.basename($PROGRAM_NAME)
        @logger = logger || ::Logger.new(::STDERR)
        @base_level = @logger.level
      end

      attr_reader :loader
      attr_reader :binary_name
      attr_reader :logger
      attr_reader :base_level

      def run(args, verbosity: 0)
        @loader.execute(self, args, verbosity: verbosity)
      end

      def create_context(data)
        Context.new(self, data)
      end
    end
  end
end