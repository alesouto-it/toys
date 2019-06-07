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

module Toys
  ##
  # An internal class that parses command line arguments for a tool.
  #
  # Generally, you should not need to use this class directly. It is called
  # from {Toys::Runner}.
  #
  class ArgParser
    ##
    # Base representation of a usage error reported by the ArgParser.
    #
    # This functions similarly to an exception, but is not raised. Rather, it
    # is returned in the {Toys::ArgParser#errors} array.
    #
    class UsageError
      ##
      # Create a UsageError given a message and common data
      #
      # @param [String] message The basic error message.
      # @param [String] name The name of the element (normally flag or
      #     positional argument) that reported the error.
      # @param [String] value The value that was rejected.
      # @param [Array<String>,nil] suggestions An array of suggestions from
      #     DidYouMean, or nil if not applicable.
      def initialize(message, name: nil, value: nil, suggestions: nil)
        @message = message
        @name = name
        @value = value
        @suggestions = suggestions
      end

      ##
      # The basic error message. Does not include suggestions, if any.
      # @return [String]
      #
      attr_reader :message

      ##
      # The name of the element (normally flag or positional argument) that
      # reported the error.
      # @return [String]
      #
      attr_reader :name

      ##
      # The value that was rejected.
      # @return [String]
      #
      attr_reader :value

      ##
      # An array of suggestions from DidYouMean, or nil if not applicable.
      # @return [Array<String>,nil]
      #
      attr_reader :suggestions

      ##
      # A fully formatted error message including suggestions.
      # @return [String]
      #
      def to_s
        if suggestions && !suggestions.empty?
          alts_str = suggestions.join("\n                 ")
          "#{message}\nDid you mean...  #{alts_str}"
        else
          message
        end
      end
    end

    ##
    # A UsageError indicating a value was provided for a flag that does not
    # take a value.
    #
    class FlagValueNotAllowedError < UsageError
      ##
      # Create a FlagValueNotAllowedError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] name The name of the flag. Normally required.
      #
      def initialize(message = nil, name: nil)
        super(message || "Flag \"#{name}\" should not take an argument.", name: name)
      end
    end

    ##
    # A UsageError indicating a value was not provided for a flag that requires
    # a value.
    #
    class FlagValueMissingError < UsageError
      ##
      # Create a FlagValueMissingError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] name The name of the flag. Normally required.
      #
      def initialize(message = nil, name: nil)
        super(message || "Flag \"#{name}\" is missing a value.", name: name)
      end
    end

    ##
    # A UsageError indicating a flag name was not recognized.
    #
    class FlagUnrecognizedError < UsageError
      ##
      # Create a FlagUnrecognizedError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] value The requested flag name. Normally required.
      # @param [Array<String>] suggestions An array of suggestions to present
      #     to the user. Optional.
      #
      def initialize(message = nil, value: nil, suggestions: nil)
        super(message || "Flag \"#{value}\" is not recognized.",
              value: value, suggestions: suggestions)
      end
    end

    ##
    # A UsageError indicating a flag name prefix was given that matched
    # multiple flags.
    #
    class FlagAmbiguousError < UsageError
      ##
      # Create a FlagAmbiguousError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] value The requested flag name. Normally required.
      # @param [Array<String>] suggestions An array of suggestions to present
      #     to the user. Optional.
      #
      def initialize(message = nil, value: nil, suggestions: nil)
        super(message || "Flag prefix \"#{value}\" is ambiguous.",
              value: value, suggestions: suggestions)
      end
    end

    ##
    # A UsageError indicating a flag did not accept the value given it.
    #
    class FlagValueUnacceptableError < UsageError
      ##
      # Create a FlagValueUnacceptableError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] name The name of the flag. Normally required.
      # @param [String] value The value given. Normally required.
      # @param [Array<String>] suggestions An array of suggestions to present
      #     to the user. Optional.
      #
      def initialize(message = nil, name: nil, value: nil, suggestions: nil)
        super(message || "Unacceptable value \"#{value}\" for flag \"#{name}\".",
              name: name, suggestions: suggestions)
      end
    end

    ##
    # A UsageError indicating a positional argument did not accept the value
    # given it.
    #
    class ArgValueUnacceptableError < UsageError
      ##
      # Create an ArgValueUnacceptableError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] name The name of the argument. Normally required.
      # @param [String] value The value given. Normally required.
      # @param [Array<String>] suggestions An array of suggestions to present
      #     to the user. Optional.
      #
      def initialize(message = nil, name: nil, value: nil, suggestions: nil)
        super(message || "Unacceptable value \"#{value}\" for positional argument \"#{name}\".",
              name: name, suggestions: suggestions)
      end
    end

    ##
    # A UsageError indicating a required positional argument was not fulfilled.
    #
    class ArgMissingError < UsageError
      ##
      # Create an ArgMissingError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] name The name of the argument. Normally required.
      #
      def initialize(message = nil, name: nil)
        super(message || "Required positional argument \"#{name}\" is missing.", name: name)
      end
    end

    ##
    # A UsageError indicating extra arguments were supplied.
    #
    class ExtraArgumentsError < UsageError
      ##
      # Create an ExtraArgumentsError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] value The first extra argument. Normally required.
      # @param [Array<String>] values All extra arguments. Normally required.
      #
      def initialize(message = nil, value: nil, values: nil)
        super(message || "Extra arguments: \"#{Array(values).join(' ')}\".", value: value)
      end
    end

    ##
    # A UsageError indicating the given subtool name does not exist.
    #
    class ToolUnrecognizedError < UsageError
      ##
      # Create a ToolUnrecognizedError.
      #
      # @param [String,nil] message A custom message. Normally omitted, in
      #     which case an appropriate default is supplied.
      # @param [String] value The requested subtool. Normally required.
      # @param [Array<String>] values The full path of the requested tool.
      #     Normally required.
      # @param [Array<String>] suggestions An array of suggestions to present
      #     to the user. Optional.
      #
      def initialize(message = nil, value: nil, values: nil, suggestions: nil)
        super(message || "Tool not found: \"#{Array(values).join(' ')}\".",
              value: value, suggestions: suggestions)
        @name = name
      end
    end

    ##
    # A UsageError indicating a flag group constraint was not fulfilled.
    #
    class FlagGroupConstraintError < UsageError
      ##
      # Create a FlagGroupConstraintError.
      #
      # @param [String] message The message. Required.
      #
      def initialize(message)
        super(message)
      end
    end

    ##
    # Create an argument parser for a particular tool.
    #
    # @param [Toys::CLI] cli The CLI in effect.
    # @param [Toys::Tool] tool The tool defining the argument format.
    # @param [Integer] verbosity The initial verbosity level (default is 0).
    #
    def initialize(cli, tool, verbosity: 0)
      @loader = cli.loader
      @data = initial_data(cli, tool, verbosity)
      @tool = tool
      @seen_flag_keys = []
      @errors = []
      @extra_args = []
      @unmatched_flags = []
      @parsed_args = []
      @active_flag_def = nil
      @active_flag_arg = nil
      @arg_defs = tool.positional_args
      @arg_def_index = 0
      @flags_allowed = true
      @finished = false
    end

    ##
    # The tool definition governing this parser.
    # @return [Toys::Tool]
    #
    attr_reader :tool

    ##
    # All command line arguments that have been parsed.
    # @return [Array<String>]
    #
    attr_reader :parsed_args

    ##
    # Extra positional args that were not matched.
    # @return [Array<String>]
    #
    attr_reader :extra_args

    ##
    # Flags that were not matched.
    # @return [Array<String>]
    #
    attr_reader :unmatched_flags

    ##
    # The collected tool data from parsed arguments.
    # @return [Hash]
    #
    attr_reader :data

    ##
    # An array of parse error messages.
    # @return [Array<String>]
    #
    attr_reader :errors

    ##
    # The current flag definition whose value is still pending, or `nil` if
    # there is no pending flag.
    # @return [Toys::Flag,nil]
    #
    attr_reader :active_flag_def

    ##
    # Whether flags are currently allowed. Returns false after `--` is received.
    # @return [Boolean]
    #
    attr_reader :flags_allowed
    alias flags_allowed? flags_allowed

    ##
    # Determine if this parser is finished
    # @return [Boolean]
    #
    attr_reader :finished
    alias finished? finished

    ##
    # The argument definition that will be applied to the next argument, or
    # `nil` if all arguments have been filled.
    # @return [Toys::PositionalArg,nil]
    #
    def next_arg_def
      @arg_defs[@arg_def_index]
    end

    ##
    # Incrementally parse an array of strings
    #
    # @param [Array<String>] args
    # @return [self]
    #
    def parse(args)
      args.each { |arg| add(arg) }
      self
    end

    ##
    # Incrementally parse a single string
    #
    # @param [String] arg
    # @return [self]
    #
    def add(arg)
      raise "Parser has finished" if @finished
      @parsed_args << arg
      unless @tool.argument_parsing_disabled?
        check_flag_value(arg) || check_flag(arg) || handle_positional(arg)
      end
      self
    end

    ##
    # Complete parsing. This should be called after all arguments have been
    # processed. It does a final check for any errors, including:
    #
    # *   The arguments ended with a flag that was expecting a value but wasn't
    #     provided.
    # *   One or more required arguments were never given a value.
    # *   One or more extra arguments were provided.
    # *   Restrictions defined in one or more flag groups were not fulfilled.
    #
    # Any errors are added to the errors array. It also fills in final values
    # for `Context::Key::USAGE_ERRORS` and `Context::Key::ARGS`.
    #
    # After this method is called, this object is locked down, and no
    # additional arguments may be parsed.
    #
    # @return [self]
    #
    def finish
      finish_active_flag
      finish_arg_defs
      finish_flag_groups
      finish_special_data
      @finished = true
      self
    end

    private

    REMAINING_HANDLER = ->(val, prev) { prev.is_a?(::Array) ? prev << val : [val] }
    ARG_HANDLER = ->(val, _prev) { val }

    def initial_data(cli, tool, verbosity)
      data = {
        Context::Key::ARGS => nil,
        Context::Key::BINARY_NAME => cli.binary_name,
        Context::Key::CLI => cli,
        Context::Key::CONTEXT_DIRECTORY => tool.context_directory,
        Context::Key::LOADER => cli.loader,
        Context::Key::LOGGER => cli.logger,
        Context::Key::TOOL => tool,
        Context::Key::TOOL_SOURCE => tool.source_info,
        Context::Key::TOOL_NAME => tool.full_name,
        Context::Key::USAGE_ERRORS => [],
      }
      Compat.merge_clones(data, tool.default_data)
      data[Context::Key::VERBOSITY] ||= verbosity
      data
    end

    def check_flag_value(arg)
      return false unless @active_flag_def
      result = @active_flag_def.value_type == :required || !arg.start_with?("-")
      add_data(@active_flag_def.key, @active_flag_def.handler, @active_flag_def.acceptor,
               result ? arg : nil, :flag, @active_flag_arg)
      @seen_flag_keys << @active_flag_def.key
      @active_flag_def = nil
      @active_flag_arg = nil
      result
    end

    def check_flag(arg)
      return false unless @flags_allowed
      case arg
      when "--"
        @flags_allowed = false
      when /\A(--\w[\?\w-]*)=(.*)\z/
        handle_valued_flag(::Regexp.last_match(1), ::Regexp.last_match(2))
      when /\A--.+\z/
        handle_plain_flag(arg)
      when /\A-(.+)\z/
        handle_single_flags(::Regexp.last_match(1))
      else
        return false
      end
      true
    end

    def handle_single_flags(str)
      until str.empty?
        str = handle_plain_flag("-#{str[0]}", str[1..-1])
      end
    end

    def handle_plain_flag(name, following = "")
      flag_result = find_flag(name)
      flag_def = flag_result.unique_flag
      return "" unless flag_def
      @seen_flag_keys << flag_def.key
      if flag_def.flag_type == :boolean
        add_data(flag_def.key, flag_def.handler, nil, !flag_result.unique_flag_negative?,
                 :flag, name)
      elsif following.empty?
        if flag_def.value_type == :required || flag_result.unique_flag_syntax.value_delim == " "
          @active_flag_def = flag_def
          @active_flag_arg = name
        else
          add_data(flag_def.key, flag_def.handler, flag_def.acceptor, nil, :flag, name)
        end
      else
        add_data(flag_def.key, flag_def.handler, flag_def.acceptor, following, :flag, name)
        following = ""
      end
      following
    end

    def handle_valued_flag(name, value)
      flag_result = find_flag(name)
      flag_def = flag_result.unique_flag
      return unless flag_def
      @seen_flag_keys << flag_def.key
      if flag_def.flag_type == :value
        add_data(flag_def.key, flag_def.handler, flag_def.acceptor, value, :flag, name)
      else
        add_data(flag_def.key, flag_def.handler, nil, !flag_result.unique_flag_negative?,
                 :flag, name)
        @errors << FlagValueNotAllowedError.new(name: name)
      end
    end

    def handle_positional(arg)
      if @tool.flags_before_args_enforced?
        @flags_allowed = false
      end
      arg_def = next_arg_def
      unless arg_def
        @extra_args << arg
        return
      end
      @arg_def_index += 1 unless arg_def.type == :remaining
      handler = arg_def.type == :remaining ? REMAINING_HANDLER : ARG_HANDLER
      add_data(arg_def.key, handler, arg_def.acceptor, arg, :arg, arg_def.display_name)
    end

    def find_flag(name)
      flag_result = @tool.resolve_flag(name)
      if flag_result.not_found?
        @errors << FlagUnrecognizedError.new(
          value: name, suggestions: Compat.suggestions(name, @tool.used_flags)
        )
        @unmatched_flags << name
      elsif flag_result.found_multiple?
        @errors << FlagAmbiguousError.new(
          value: name, suggestions: flag_result.matching_flag_strings
        )
        @unmatched_flags << name
      end
      flag_result
    end

    def add_data(key, handler, accept, value, type_name, display_name)
      if accept
        match = accept.match(value)
        unless match
          error_class = type_name == :flag ? FlagValueUnacceptableError : ArgValueUnacceptableError
          suggestions = accept.respond_to?(:suggestions) ? accept.suggestions(value) : nil
          @errors << error_class.new(value: value, name: display_name, suggestions: suggestions)
          return
        end
        value = accept.convert(*Array(match))
      end
      if handler
        value = handler.call(value, @data[key])
      end
      @data[key] = value
    end

    def finish_active_flag
      if @active_flag_def
        if @active_flag_def.value_type == :required
          @errors << FlagValueMissingError.new(name: @active_flag_arg)
        else
          add_data(@active_flag_def.key, @active_flag_def.handler, @active_flag_def.acceptor,
                   nil, :flag, @active_flag_arg)
        end
      end
    end

    def finish_arg_defs
      arg_def = @arg_defs[@arg_def_index]
      if arg_def && arg_def.type == :required
        @errors << ArgMissingError.new(name: arg_def.display_name)
      end
      unless @extra_args.empty?
        first_arg = @extra_args.first
        @errors <<
          if @tool.runnable? || !@seen_flag_keys.empty?
            ExtraArgumentsError.new(values: @extra_args, value: first_arg)
          else
            dictionary = @loader.list_subtools(@tool.full_name).map(&:simple_name)
            ToolUnrecognizedError.new(values: @tool.full_name + [first_arg],
                                      value: first_arg,
                                      suggestions: Compat.suggestions(first_arg, dictionary))
          end
      end
    end

    def finish_flag_groups
      @tool.flag_groups.each do |group|
        @errors += Array(group.validation_errors(@seen_flag_keys))
      end
    end

    def finish_special_data
      @data[Context::Key::USAGE_ERRORS] = @errors
      @data[Context::Key::ARGS] = @parsed_args
      @data[Context::Key::EXTRA_ARGS] = @extra_args
    end
  end
end
