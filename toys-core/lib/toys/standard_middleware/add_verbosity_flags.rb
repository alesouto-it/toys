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

module Toys
  module StandardMiddleware
    ##
    # A middleware that provides flags for editing the verbosity.
    #
    # This middleware adds `-v`, `--verbose`, `-q`, and `--quiet` flags, if
    # not already defined by the tool. These flags affect the setting of
    # {Toys::Tool::Keys::VERBOSITY}, and, thus, the logger level.
    #
    class AddVerbosityFlags
      include Middleware

      ##
      # Default verbose flags
      # @return [Array<String>]
      #
      DEFAULT_VERBOSE_FLAGS = ["-v", "--verbose"].freeze

      ##
      # Default quiet flags
      # @return [Array<String>]
      #
      DEFAULT_QUIET_FLAGS = ["-q", "--quiet"].freeze

      ##
      # Create a AddVerbosityFlags middleware.
      #
      # @param [Boolean,Array<String>,Proc] verbose_flags Specify flags
      #     to increase verbosity. The value may be any of the following:
      #
      #     *  An array of flags that increase verbosity.
      #     *  The `true` value to use {DEFAULT_VERBOSE_FLAGS}. (Default)
      #     *  The `false` value to disable verbose flags.
      #     *  A proc that takes a tool and returns any of the above.
      #
      # @param [Boolean,Array<String>,Proc] quiet_flags Specify flags
      #     to decrease verbosity. The value may be any of the following:
      #
      #     *  An array of flags that decrease verbosity.
      #     *  The `true` value to use {DEFAULT_QUIET_FLAGS}. (Default)
      #     *  The `false` value to disable quiet flags.
      #     *  A proc that takes a tool and returns any of the above.
      #
      def initialize(verbose_flags: true, quiet_flags: true)
        @verbose_flags = verbose_flags
        @quiet_flags = quiet_flags
      end

      ##
      # Configure the tool flags.
      #
      def config(tool_definition, _loader)
        add_verbose_flags(tool_definition)
        add_quiet_flags(tool_definition)
        yield
      end

      private

      def add_verbose_flags(tool_definition)
        verbose_flags = resolve_flags_spec(@verbose_flags, tool_definition,
                                           DEFAULT_VERBOSE_FLAGS)
        unless verbose_flags.empty?
          tool_definition.add_flag(
            Tool::Keys::VERBOSITY, verbose_flags,
            report_collisions: false,
            handler: ->(_val, cur) { cur + 1 },
            desc: "Increase verbosity",
            long_desc: "Increase verbosity, causing additional logging levels to display."
          )
        end
      end

      def add_quiet_flags(tool_definition)
        quiet_flags = resolve_flags_spec(@quiet_flags, tool_definition, DEFAULT_QUIET_FLAGS)
        unless quiet_flags.empty?
          tool_definition.add_flag(
            Tool::Keys::VERBOSITY, quiet_flags,
            report_collisions: false,
            handler: ->(_val, cur) { cur - 1 },
            desc: "Decrease verbosity",
            long_desc: "Decrease verbosity, causing fewer logging levels to display."
          )
        end
      end

      def resolve_flags_spec(flags, tool, defaults)
        flags = flags.call(tool) if flags.respond_to?(:call)
        case flags
        when true, :default
          Array(defaults)
        when ::String
          [flags]
        when ::Array
          flags
        else
          []
        end
      end
    end
  end
end