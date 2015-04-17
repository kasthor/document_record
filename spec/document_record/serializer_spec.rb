describe "Serializer" do
  let( :obj ) { DocumentHash::Core[ "test" => "testing"] }

  it "serializes a document hash object" do
    dumped = DocumentRecord::Serializer.dump obj

    restored = DocumentRecord::Serializer.load dumped

    expect( restored["test"] ).to eq "testing"
  end 

  it "uses marshal when forced to use version 0" do 
    Marshal.should_receive( :dump ).and_return( "" )

    DocumentRecord::Serializer.dump obj, force_version: 0
  end

  it "uses BSON when forced to use version 1" do
    Hash.any_instance.should_receive(:to_bson).and_return('')

    DocumentRecord::Serializer.dump obj, force_version: 1
  end

  it "throws an error if a forced version does not exists" do
    expect{
      DocumentRecord::Serializer.dump obj, force_version: 999
    }.to raise_error
  end

  it "adds a version to the binary" do
    dumped = DocumentRecord::Serializer.dump obj, force_version: 0
    decoded = Base64.decode64 dumped

    expect( decoded[0,2] ).to eq( "DR" )
    expect( decoded[2,2].unpack( 'S' ).first ).to eq( 0 )
  end

  it "deserializes packages with version 0" do
    dumped = DocumentRecord::Serializer.dump obj, force_version: 0

    restored = DocumentRecord::Serializer.load dumped

    expect( restored["test"] ).to eq "testing"
  end

  it "deserializes packages with version 1" do
    dumped = DocumentRecord::Serializer.dump obj, force_version: 1

    restored = DocumentRecord::Serializer.load dumped

    expect( restored["test"] ).to eq "testing"
  end

  it "deserializes packages when no version specified" do
    dumped = DocumentRecord::Serializer.dump obj, force_version: 0, no_version: true

    restored = DocumentRecord::Serializer.load dumped

    expect( restored["test"] ).to eq "testing"
  end
end
