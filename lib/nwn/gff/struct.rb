# A Gff::Struct is a hash of label->Element pairs with some
# meta-information in local variables.
module NWN::Gff::Struct
  # The file-type this struct represents.
  # This is usually the file extension for root structs,
  # and nil for sub-structs.
  attr_accessor :data_type

  # The file version. Usually "V3.2" for root structs,
  # and nil for sub-structs.
  attr_accessor :data_version

  # GFF struct type
  attr_accessor :struct_id

  # The field this struct is value of.
  # It is most likely a Field of :list, or
  # :nil if it is the root struct.
  attr_accessor :element

  # Returns the path to this struct, including elements and
  # data_type.
  # For example: UTI/PropertiesList (for a struct inside PropertiesList)
  def path
    (@element ? @element.path : "") + @data_type.to_s
  end
end
