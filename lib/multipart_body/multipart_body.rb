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
    parts = str.split('--' + boundary).select{ |b| b != '--' }
    parts = parts.map { |p|
      headers, body = p.split(/\r\n\r\n/)
      headers = headers.split(/\r\n/)
      headers = Hash[headers.map{ |h| h == '' ? nil : h.split(':') }.compact]
      type, name, filename = headers['Content-Disposition'].split(';').collect{ |cd|
        cd.include?('=') ? cd.split('=')[1].gsub(/["']/,'') : nil }
      Part.new(content_type: headers['Content-Type'], name: name, filename: filename, body: body)
    }
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
