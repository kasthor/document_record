describe SampleModel do
  it "includes Active Record Base" do
    SampleModel.should be < ActiveRecord::Base
  end

  context "with an arbitrary set of attributes" do
    let(:arbitrary_attributes){ { arbitrary_attribute: 'test' } }
    let(:sample){ SampleModel.new arbitrary_attributes }

    it "should allow access the previously set attributes thru direct methods" do
      sample.arbitrary_attribute.should == 'test'
    end
    it "should allow assignments thru direct methods" do
      sample.arbitrary_attribute = 'reassign'
      sample.arbitrary_attribute.should == 'reassign'
    end
    it "can be saved" do
      sample.save
    end
  end

  context "with an arbitrary hash" do
    let(:hash){ { "level1" => {"level2" => 'level3'} } }
    let(:sample){ SampleModel.new hash }
    
    it "returns the previously stored hash when requested" do
      sample.level1.should == { :level2 => 'level3' }
    end 
    it "can be saved" do
      sample.save
    end
  end

  context "with an arbitrary inner attribute" do
    let(:hash) { { "inner" => { "attribute" => "value" }}}

    it "recognizes inner_attribute as an indexed field" do
      sample = SampleModel.new hash
      sample.is_indexed?(:inner_attribute).should be_true
      
    end

    it "should write the value to an attribute" do
      sample = SampleModel.new hash
      sample.attributes["inner_attribute"].should == "value"
    end

    it "would have the inner attribute accessible" do
      sample = SampleModel.new hash
      sample.inner_attribute.should == "value"
    end

    it "changes the inner attribute indexed field when changing the attribute" do
      sample = SampleModel.new hash
      sample.inner["attribute"] = "testing"
      sample.inner_attribute.should == "testing"
    end

  end

  it "can save the indexed fields on their respective field" do
    s1 = SampleModel.create level1: { level2: 'level3' }, indexed_field: 'test'
    s1.indexed_field.should == 'test'
  end

  it "updates the document when updating an index field" do
    s1 = SampleModel.create level1: { level2: 'level3' }, indexed_field: 'test'
    s1.indexed_field = 'update'
    s1.as_json["indexed_field"].should == "update"
  end

  it "can be found by indexed_field" do
    s1 = SampleModel.create level1: { level2: 'level3' }, indexed_field: 'test'
    s2 = SampleModel.find_by_indexed_field 'test'
    s2.should == s1
  end

  it "return any key even if it was passed as string" do
    s1 = SampleModel.create "level1" => "level2"
    s1.level1.should == "level2"
  end

  it "save integers as integers" do
    s1 = SampleModel.create "number" => 1
    s1.number.should be_an Integer
  end

  it "honors indexed field type integer" do
    s1 = SampleModel.create "indexed_integer" => "1"
    s1.indexed_integer.should be_an Integer
  end

  it "honors indexed field type time" do
    s1 = SampleModel.create "indexed_date" => DateTime.now
    s1.indexed_date.should be_an DateTime
  end

  it "reports that indexed fields have been changed" do
    s1 = SampleModel.create "indexed_field" => "test"
    s1.indexed_field = "change"
    s1.indexed_field_changed?.should be_true
  end

  it "includes attributes in the json" do
    s1 = SampleModel.create "test" => "test"
    s1.as_json.should have_key "created_at"
  end

  it "doesn't include the document field" do
    s1 = SampleModel.create "test" => "test"
    s1.as_json.should_not have_key "object"
  end

  it "includes methods if passed thru options" do
    s1 = SampleModel.create "test" => "test"
    s1.as_json( methods: [ :json_method ] ).should have_key :json_method
  end

end

describe ActiveRecord::Base do
  it { ActiveRecord::Base.should respond_to :document_field }

  describe '#document_field' do
    it "should show an error if the field doesn't exist" do
      expect {
        SampleModel.class_eval { document_field :non_existent }
      }.to raise_error
      expect {
        SampleModel.class_eval { document_field :object }
      }.to_not raise_error
    end
  end
end
