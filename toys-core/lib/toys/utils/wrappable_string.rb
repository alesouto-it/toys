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
  module Utils
    ##
    # A string intended to be wrapped.
    #
    class WrappableString
      ##
      # Create a wrapped string.
      # @param [String] string The string.
      #
      def initialize(string = "")
        @string = string
      end

      ##
      # Returns the string.
      # @return [String]
      #
      attr_reader :string

      ##
      # Returns the string.
      # @return [String]
      #
      def to_s
        string
      end

      ## @private
      def ==(other)
        other.is_a?(WrappableString) ? other.string == string : false
      end
      alias eql? ==

      ## @private
      def hash
        string.hash
      end

      ##
      # Wraps the string to the given width.
      #
      # @param [Integer,nil] width Width in characters, or `nil` for infinite.
      # @param [Integer,nil] width2 Width in characters for the second and
      #     subsequent lines, or `nil` to use the same as width.
      # @return [Array<String>] Wrapped lines
      #
      def wrap(width, width2 = nil)
        lines = []
        str = string.gsub(/\s/, " ").sub(/^\s+/, "")
        return str.sub(/\s+$/, "") if width.nil?
        until str.empty?
          i = str.index(/\S(\s|$)/) + 1
          loop do
            next_i = str.index(/\S(\s|$)/, i)
            break if next_i.nil? || next_i >= width
            i = next_i + 1
          end
          lines << str[0, i]
          str = str[i..-1].sub(/^\s+/, "")
          width = width2 if width2
        end
        lines
      end

      ##
      # Wraps an array of lines to the given width.
      #
      # @param [Array<String,WrappableString>] strs Array of strings to wrap.
      # @param [Integer,nil] width Width in characters, or `nil` for infinite.
      # @param [Integer,nil] width2 Width in characters for the second and
      #     subsequent lines, or `nil` to use the same as width.
      # @return [Array<String>] Wrapped lines
      #
      def self.wrap_lines(strs, width, width2 = nil)
        result = Array(strs).map do |s|
          lines = s.is_a?(WrappableString) ? s.wrap(width, width2) : s.to_s
          width = width2 if width2
          lines
        end.flatten
        result = [] if result.all?(&:empty?)
        result
      end
    end
  end
end