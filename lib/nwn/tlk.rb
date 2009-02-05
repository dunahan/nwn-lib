module NWN
  module Tlk
    Languages = {
      0 => :english,
      1 => :french,
      2 => :german,
      3 => :italian,
      4 => :spanish,
      5 => :polish,
      128 => :korean,
      129 => :chinese_traditional,
      130 => :chinese_simplified,
      131 => :japanese,
    }.freeze

    ValidGender = [:male, :female].freeze

    # Tlk wraps a File object that points to a .tlk file.
    class Tlk
      # The number of strings this Tlk holds.
      attr_reader :size

      # The language_id of this Tlk.
      attr_reader :language

      # Cereate
      def initialize io
        @io = io

        # Read the header
        type, version, language_id,
          string_count, string_entries_offset =
            @io.read(20).unpack("A4 A4 I I I")

        raise ArgumentError, "The given IO does not describe a valid tlk table" unless
          type == "TLK" && version == "V3.0"

        @size = string_count
        @language = language_id
        @entries_offset = string_entries_offset
      end

      # Returns a TLK entry as a hash with the following keys:
      # +:text+          string: The text
      # +:sound+         string: A sound resref, or "" if no sound is specified.
      # +:sound_length+  float: Length of the given resref (or 0.0 if no sound is given).
      #
      # id is the numeric offset within the Tlk, starting at 0.
      # The maximum is Tlk#size - 1.
      def [](id)
        return { :text => "", :sound => "", :sound_length => 0.0 } if id == 0xffffffff

        raise ArgumentError, "No such string ID: #{id.inspect}" if id >= @size || id < 0
        data_element_size = 4 + 16 + 4 + 4 + 4 + 4 + 4
        seek_to = 20 + (id) * data_element_size
        @io.seek(seek_to)
        data = @io.read(data_element_size)

        raise ArgumentError, "Cannot read TLK file, missing string header data." if !data || data.size != 40

        flags, sound_resref, v_variance, p_variance, offset,
          size, sound_length = data.unpack("I A16 I I I I f")
        flags = flags.to_i

        @io.seek(@entries_offset + offset)
        text = @io.read(size)

        raise ArgumentError, "Cannot read TLK file, missing string text data." if !text || text.size != size

        text = flags & 0x1 > 0 ? text : ""
        sound = flags & 0x2 > 0 ? sound_resref : ""
        sound_length = flags & 0x4 > 0 ? sound_length.to_f : 0.0

        { :text => text, :sound => sound, :sound_length => sound_length }
      end
    end

    # A TlkSet wraps a set of File objects, each pointing to the respective tlk file, making
    # retrieval easier.
    class TlkSet
      # The default male Tlk.
      attr_reader :dm
      # The default female Tlk, (or the default male).
      attr_reader :df
      # The custom male Tlk, or nil.
      attr_reader :cm
      # The custom female Tlk, if specified (cm if no female custom tlk has been specified, nil if none).
      attr_reader :cf

      def initialize tlk, tlkf = nil, custom = nil, customf = nil
        @dm = Tlk.new(tlk)
        @df = tlkf ? Tlk.new(tlkf) : @dm
        @cm = custom ? Tlk.new(custom) : nil
        @cf = customf ? Tlk.new(customf) : @cm
      end

      def [](id, gender = :male)
        raise ArgumentError, "Invalid Tlk ID: #{id.inspect}" if id > 0xffffffff
        (if id < 0x01000000
          gender == :female && @df ? @df : @dm
        else
          raise ArgumentError, "Wanted a custom ID, but no custom talk table has been specified." unless @cm
          id -= 0x01000000
          gender == :female && @cf ? @cf : @cm
        end)[id]
      end
    end
  end
end

