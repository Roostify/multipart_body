class MultipartBody
  attr_accessor :parts, :boundary

  def initialize(parts = nil, boundary = nil)
    @parts = []
    @boundary = boundary || "----multipart-boundary-#{rand(1000000)}"

    if parts.is_a? Hash
      @parts = parts.map {|name, body| Part.new(:name => name, :body => body) }
    elsif parts.is_a?(Array) && parts.first.is_a?(Part)
      @parts = parts
    end

    self
  end

  def self.from_hash(parts_hash)
    multipart = self.new(parts_hash)
  end

  def self.parse(str, boundary)
    parts = str.split(boundary)
      .map(&:strip)
      .select{ |part| part.strip != '' && part.strip != '--' }
      .map { |content| Part.parse(content) }
    self.new(parts, boundary)
  end

  def find_part_by_name(name)
    parts.find{ |p| p.name == name }
  end

  def to_s
    output = "--#{@boundary}\r\n"
    output << @parts.join("\r\n--#{@boundary}\r\n")
    output << "\r\n--#{@boundary}--"
  end
end
