class Part
  attr_accessor :headers, :name, :body, :filename, :content_disposition, :content_type, :encoding

  def initialize(*args)
    if args.flatten.first.is_a? Hash
      from_hash(args.flatten.first)
    elsif args.length > 0
      from_args(*args)
    end
  end

  def self.parse(content)
    lines = content.strip.split(/\r?\n/)
    p = Part.new
    p.headers = lines[0..1]
    p.body = lines[2..-1].join("\n").strip
    p.content_type = p.headers[0].split(':')[1].strip
    p.content_disposition = p.headers[1].split(':')[1].strip
    c_d_arry = p.content_disposition.split(';')
    p.name = c_d_arry[1].split('=')[1].gsub(/["']/,'')
    p.filename = c_d_arry[2].split('=')[1].gsub(/["']/,'')
    return p
  end

  def from_hash(hash)
    hash.each_pair do |k, v|
      if k.to_s == 'body' && (v.is_a?(File) || v.is_a?(Tempfile))
        self.send("#{k}=", v.read)
        self.filename = File.basename(v.path)
      else
        self.send("#{k}=", v)
      end
    end
  end

  def from_args(name, body, filename=nil)
    self.from_hash(:name => name, :body => body, :filename => filename)
  end

  def header
    header = ""
    if content_disposition || name
      header << "Content-Disposition: #{content_disposition || 'form-data'}"
      header << "; name=\"#{name}\"" if name && !content_disposition
      header << "; filename=\"#{filename}\"" if filename && !content_disposition
      header << "\r\n"
    end
    header << "Content-Type: #{content_type}\r\n" if content_type
    header << "Content-Transfer-Encoding: #{encoding}\r\n" if encoding
    header
  end

  # TODO: Implement encodings
  def encoded_body
    case encoding
    when nil
      body
    else
      raise "Encodings have not been implemented"
    end
  end

  def to_s
    "#{header}\r\n#{encoded_body}"
  end
end
