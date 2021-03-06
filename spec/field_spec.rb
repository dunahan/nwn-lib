require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Gff::Field" do
  GffFieldValidations.each do |t, values|
    valid, invalid = *values
    # No field type ever accepts nil as valid
    invalid << nil

    it "accepts good values for type '#{t.inspect}'" do
      valid.each do |v|
        Gff::Field.valid_for?(v, t).should == true
      end
    end

    it "rejects bad values for type '#{t.inspect}'" do
      NWN.setting(:resref16, "1")
      invalid.each do |v|
        Gff::Field.valid_for?(v, t).should == false
      end
      NWN.setting(:resref16, nil)
    end
  end

  describe ":void" do
    it "stores data in binary" do
      void = "\xde\xad\xbe\xef".force_encoding("ASCII-8BIT")
      gff = Gff::Struct.new do |root|
        root.add_void 'Test', void
      end.to_gff
      gff.index(void).should_not be_nil
    end
  end
end
