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

require "toys/utils/exec"

module Toys
  module Helpers
    ##
    # A set of helper methods for invoking subcommands. Provides shortcuts for
    # common cases such as invoking Ruby in a subprocess or capturing output
    # in a string. Also provides an interface for controlling a spawned
    # process's streams.
    #
    # This is a frontend for {Toys::Utils::Exec}. More information is
    # available in that class's documentation.
    #
    module Exec
      ## @private
      def self.extended(context)
        context[Exec] = Utils::Exec.new do |k|
          case k
          when :logger
            context[Context::LOGGER]
          when :nonzero_status_handler
            if context[Context::EXIT_ON_NONZERO_STATUS]
              proc { |s| context.exit(s.exitstatus) }
            end
          end
        end
      end

      ##
      # Set default configuration keys.
      #
      # @param [Hash] opts The default options. See the section on
      #     configuration options in the {Toys::Utils::Exec} docs.
      #
      def configure_exec(opts = {})
        self[Exec].configure_defaults(opts)
      end

      ##
      # Execute a command. The command may be given as a single string to pass
      # to a shell, or an array of strings indicating a posix command.
      #
      # If you provide a block, a {Toys::Utils::Exec::Controller} will be
      # yielded to it, allowing you to interact with the subprocess streams.
      #
      # @param [String,Array<String>] cmd The command to execute.
      # @param [Hash] opts The command options. See the section on
      #     configuration options in the {Toys::Utils::Exec} module docs.
      # @yieldparam controller [Toys::Utils::Exec::Controller] A controller for
      #     the subprocess streams.
      #
      # @return [Toys::Utils::Result] The subprocess result, including the exit
      #     code and any captured output.
      #
      def exec(cmd, opts = {}, &block)
        self[Exec].exec(cmd, Exec._setup_exec_opts(opts, self), &block)
      end

      ##
      # Spawn a ruby process and pass the given arguments to it.
      #
      # If you provide a block, a {Toys::Utils::Exec::Controller} will be
      # yielded to it, allowing you to interact with the subprocess streams.
      #
      # @param [String,Array<String>] args The arguments to ruby.
      # @param [Hash] opts The command options. See the section on
      #     configuration options in the {Toys::Utils::Exec} module docs.
      # @yieldparam controller [Toys::Utils::Exec::Controller] A controller for
      #     for the subprocess streams.
      #
      # @return [Toys::Utils::Result] The subprocess result, including the exit
      #     code and any captured output.
      #
      def ruby(args, opts = {}, &block)
        self[Exec].ruby(args, Exec._setup_exec_opts(opts, self), &block)
      end

      ##
      # Execute the given string in a shell. Returns the exit code.
      #
      # @param [String] cmd The shell command to execute.
      # @param [Hash] opts The command options. See the section on
      #     configuration options in the {Toys::Utils::Exec} module docs.
      # @yieldparam controller [Toys::Utils::Exec::Controller] A controller for
      #     the subprocess streams.
      #
      # @return [Integer] The exit code
      #
      def sh(cmd, opts = {})
        self[Exec].sh(cmd, Exec._setup_exec_opts(opts, self))
      end

      ##
      # Execute a command. The command may be given as a single string to pass
      # to a shell, or an array of strings indicating a posix command.
      #
      # Captures standard out and returns it as a string.
      #
      # @param [String,Array<String>] cmd The command to execute.
      # @param [Hash] opts The command options. See the section on
      #     configuration options in the {Toys::Utils::Exec} module docs.
      # @yieldparam controller [Toys::Utils::Exec::Controller] A controller for
      #     the subprocess streams.
      #
      # @return [String] What was written to standard out.
      #
      def capture(cmd, opts = {})
        self[Exec].capture(cmd, Exec._setup_exec_opts(opts, self))
      end

      ## @private
      def self._setup_exec_opts(opts, context)
        return opts unless opts.key?(:exit_on_nonzero_status)
        nonzero_status_handler =
          if opts[:exit_on_nonzero_status]
            proc { |s| context.exit(s.exitstatus) }
          end
        opts.merge(nonzero_status_handler: nonzero_status_handler)
      end
    end
  end
end
