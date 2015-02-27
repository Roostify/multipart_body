require File.join(File.dirname(__FILE__), 'test_helper')
require 'tempfile'

describe MultipartBody do
  describe 'MultipartBody.parse(str, boundary)' do
    before do
      @boundary = '------multipart-boundary-307380'
      @example_text = [
        @boundary,
        "\r\nContent-type: text/plain; charset=UTF-8\r\nContent-Disposition: form-data; name='n1'; filename='fn1'\r\n\r\nvalue\r\n------multipart-boundary-307380",
        "\r\nContent-type: text/plain; charset=UTF-8\r\nContent-Disposition: form-data; name='n2'; filename='fn2'\r\n\r\nvalue2\r\n------multipart-boundary-307380--",
      ].join('')

    end

    it 'return a new multipart when sent #parse' do
      mp = MultipartBody.parse(@example_text, @boundary)
      mp.parts.size.must_equal 2
      mp.parts.first.name.must_equal 'n1'
      mp.parts.first.filename.must_equal 'fn1'
      mp.parts.first.body.must_equal "value\r\n"
      mp.parts.last.name.must_equal 'n2'
      mp.parts.last.filename.must_equal 'fn2'
      mp.parts.last.body.must_equal "value2\r\n"
    end
  end

  describe "MultipartBody" do
    before do
      @hash = {:test => 'test', :two => 'two'}
      @parts = [Part.new('name', 'value'), Part.new('name2', 'value2')]
      @example_text = "------multipart-boundary-307380\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nvalue\r\n------multipart-boundary-307380\r\nContent-Disposition: form-data; name=\"name2\"\r\n\r\nvalue2\r\n------multipart-boundary-307380--"
      @file = Tempfile.new('file')
      @file.write('hello')
      @file.flush
      @file.open
    end

    it "return a new multipart when sent #from_hash" do
      multipart = MultipartBody.from_hash(@hash)
      MultipartBody.must_equal multipart.class
    end

    it "create a list of parts from the hash when sent #from_hash" do
      multipart = MultipartBody.from_hash(@hash)
      @hash.must_equal Hash[multipart.parts.map{|part| [part.name, part.body] }]
    end

    it "add to the list of parts when sent #new with a hash" do
      multipart = MultipartBody.new(@hash)
      @hash.must_equal Hash[multipart.parts.map{|part| [part.name, part.body] }]
    end

    it "correctly add parts sent #new with parts" do
      multipart = MultipartBody.new(@parts)
      @parts.must_equal multipart.parts
    end

    it "assign a boundary if it is not given" do
      multpart = MultipartBody.new()
      multpart.boundary.must_match /[\w\d-]{10,}/
    end

    it "use the boundary provided if given" do
      multipart = MultipartBody.new(nil, "my-boundary")
      "my-boundary".must_equal multipart.boundary
    end

    it "starts with a boundary when sent #to_s" do
      multipart = MultipartBody.new(@parts)
      multipart.to_s.must_match /^--#{multipart.boundary}/i
    end

    it "end with a boundary when sent #to_s" do
      multipart = MultipartBody.new(@parts)
      multipart.to_s.must_match /--#{multipart.boundary}--\z/i
    end

    # it "contain the parts joined by a boundary when sent #to_s" do
    #   multipart = MultipartBody.new(@parts)
    #   multipart.parts.join("\r\n--#{multipart.boundary}\r\n").must_equal multipart.to_s
    # end

    it "contrsuct a valid multipart text when passed #to_s" do
      multipart = MultipartBody.new(@parts)
      multipart.boundary = '----multipart-boundary-307380'
      @example_text.must_equal multipart.to_s
    end

    it "construct a file part when create from hash" do
      multipart = MultipartBody.new(:test => @file)
      multipart.boundary = '----multipart-boundary-672923'
      'hello'.must_equal multipart.parts.first.body
      multipart.parts.first.filename.wont_be_nil
      multipart.to_s.must_match /------multipart-boundary-672923\r\nContent-Disposition: form-data; name=\"test\"; filename=\".*"\r\n\r\nhello\r\n------multipart-boundary-672923--/
    end

    describe '.find_part_by_name(name)' do
      it{
        multipart = MultipartBody.new(@parts)
        multipart.find_part_by_name('name').must_equal @parts.first
        multipart.find_part_by_name('name2').must_equal @parts.last
      }
    end
  end

  describe "a Part" do
    before do
      @part = Part
      @file = Tempfile.new('file')
      @file.write('hello')
      @file.flush
      @file.open
    end

    it "assign values when sent #new with a hash" do
      part = Part.new(:name => 'test', :body => 'content', :filename => 'name')
      'test'.must_equal part.name
      'content'.must_equal part.body
      'name'.must_equal part.filename
    end

    it "assign values when sent #new with values" do
      part = Part.new('test', 'content', 'name')
      'test'.must_equal part.name
      'content'.must_equal part.body
      'name'.must_equal part.filename
    end

    it "be happy when sent #new with args without a filename" do
      part = Part.new('test', 'content')
      'test'.must_equal part.name
      'content'.must_equal part.body
      nil.must_equal part.filename
    end

    it "create an empty part when sent #new with nothing" do
      part = Part.new()
      nil.must_equal part.name
      nil.must_equal part.body
      nil.must_equal part.filename
    end

    it "include a content type when one is set" do
      part = Part.new(:content_type => 'plain/text', :body => 'content')
      "Content-Type: plain\/text\r\n".must_match part.header
    end

    it "include a content disposition when sent #header and one is set" do
      part = Part.new(:content_disposition => 'content-dispo', :body => 'content')
      "Content-Disposition: content-dispo\r\n".must_match part.header
    end

    it "not include a content disposition of form-data when nothing is set" do
      part = Part.new(:body => 'content')
      part.header.wont_match /content-disposition/i
    end

    it "include a content disposition when sent #header and name is set" do
      part = Part.new(:name => 'key', :body => 'content')
      part.header.must_match /content-disposition: form-data; name="key"/i
    end

    it "include no filename when sent #header and a filename is not set" do
      part = Part.new(:name => 'key', :body => 'content')
      part.header.wont_match /content-disposition: .+; name=".+"; filename="?.*"?/i
    end

    it "include a filename when sent #header and a filename is set" do
      part = Part.new(:name => 'key', :body => 'content', :filename => 'file.jpg')
      part.header.must_match /content-disposition: .+; name=".+"; filename="file.jpg"/i
    end

    it "return the original body if encoding is not set" do
      part = Part.new(:name => 'key', :body => 'content')
      'content'.must_equal part.encoded_body
    end

    # TODO: Implement encoding tests
    it "raise an exception when an encoding is passed" do
      part = Part.new(:name => 'key', :body => 'content', :encoding => :base64)
      # assert_raises RuntimeError do
      #   part.encoded_body
      # end
    end

    it "output the header and body when sent #to_s" do
      part = Part.new(:name => 'key', :body => 'content')
      "#{part.header}\r\n#{part.body}".must_equal part.to_s
    end

    it "add the files content not the file when passed a file" do
      part = Part.new(:name => 'key', :body => @file)
      'hello'.must_equal part.body
    end

    it "automatically assign a filename when passed a file to body" do
      part = Part.new(:name => 'key', :body => @file)
      part.filename.wont_be_nil
    end
  end
end
