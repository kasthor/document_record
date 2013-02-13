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
    let(:sample){ sample = SampleModel.new hash }
    
    it "returns the previously stored hash when requested" do
      sample.level1.should == { "level2" => 'level3' }
    end 
    it "can be saved" do
      sample.save
    end
  end

  it "can save the indexed fields on their respective field" do
    s1 = SampleModel.create level1: { level2: 'level3' }, indexed_field: 'test'
    s1.indexed_field.should == 'test'
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

end

describe ActiveRecord::Base do
  it { ActiveRecord::Base.should respond_to :document_field }
  it { ActiveRecord::Base.should respond_to :index_fields }

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

  describe '#index_fields' do
    it "should show an error if the field doesn't exist" do
      expect {
        SampleModel.class_eval { index_fields :non_existent }
      }.to raise_error
      expect {
        SampleModel.class_eval { index_fields :indexed_field }
      }.to_not raise_error
    end
  end
end
