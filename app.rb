module RcdType
  DEBIT = "\x00"
  CREDIT = "\x01"
  START_AUTOPAY = "\x02"
  END_AUTOPAY = "\x03"
end



class Header
  attr_reader :bytes, :code, :version, :nbr_of_records
  def initialize(data)
    @bytes = 9
    @code = data[0..3]
    @version = data[4].unpack("c")
    @nbr_of_records = data[5..8].unpack('L>*')[0].to_i
  end
end

# def bin_to_hex(s)
#   s.each_byte.map { |b| b.to_s(16) }.join
# end


class BaseRecord
  @@record_size = 13
  # | 1 byte record type enum | 4 byte (uint32) Unix timestamp | 8 byte (uint64) user ID |
  attr_reader :type, :timestamp, :user_id
  def initialize(data)
    @type = data[0]
    @timestamp = data[1..4].unpack("N")[0]
    @user_id = data[5..12].unpack('Q')[0]
  end
  def self.record_size
    @@record_size
  end
end


class DebitCredit < BaseRecord
  @@bytes = BaseRecord.record_size + 8
  attr_reader :amount
  def initialize(data)
    super(data)
    d = data[@@bytes-8..@@bytes]
    @amount = d.unpack('G')[0]  # making the assumption it is double float
  end
  def self.bytes
    @@bytes
  end
end

class Autopay < BaseRecord
  @@bytes = BaseRecord.record_size
  def initialize(data)
    super(data)
  end
  def self.bytes
    @@bytes
  end
end



# ************************* Main routine ********************

data = File.binread("data.dat")

header = Header.new(data)



start = header.bytes
autopay_started = 0
autopay_ended = 0
user_balance = 0
debits = 0.0
credits = 0.0


for rcdNbr in 0..header.nbr_of_records
  record_type = data[start]
  case record_type
  when RcdType::DEBIT
    rcd = DebitCredit.new(data[start..start+DebitCredit.bytes])
    start += DebitCredit.bytes
    debits += rcd.amount
  when RcdType::CREDIT
    rcd = DebitCredit.new(data[start..start+DebitCredit.bytes])
    start += DebitCredit.bytes
    credits += rcd.amount
  when RcdType::START_AUTOPAY
    rcd = Autopay.new(data[start..start+Autopay.bytes])
    start += Autopay.bytes
    autopay_started += 1
  when RcdType::END_AUTOPAY
    rcd = Autopay.new(data[start..start+Autopay.bytes])
    start += Autopay.bytes
    autopay_ended += 1
  else
    puts "******** unknown type"
    break
  end

  # puts rcd.amount if defined? rcd.amount
  if rcd.user_id == 2456938384156277127
    user_balance += 1
  end

end


puts "**********************"
puts "autopay started: #{autopay_started}"
puts "autopay ended: #{autopay_ended}"
puts "user balance: #{user_balance}"
puts "debits: #{debits}"
puts "credits: #{credits}"
