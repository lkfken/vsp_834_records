require 'stupidedi'
# See https://github.com/irobayna/stupidedi/issues/160
class MyBuilder < Stupidedi::Parser::BuilderDsl
  def DTP(dtp01, dtp02, dtp03, *args)
    super(dtp01, dtp02, strftime(dtp02, dtp03), *args)
  end

  def DMG(dmg01, dmg02, *args)
    super(dmg01, strftime(dmg01, dmg02), *args)
  end

  def strftime(format, value)
    Stupidedi::Versions::Common::ElementTypes::AN.strftime(format, value)
  end

end
class Composer
  attr_reader :builder, :stack, :production, :now, :bgn02
  alias_method :b, :builder

  def initialize(dataset:, production: false)
    @stack = Stupidedi::Parser::IdentifierStack.new(rand(1000000000))
    @builder = MyBuilder.build(Stupidedi::Config.hipaa)
    @production = production
    @now = Time.now
    @bgn02 = bgn02

    build(dataset)
  end

  def to_s
    # Print X12-formatted text
    edi_text = nil
    segment_terminator = production ? "~" : "~\n"
    builder.machine.zipper.tap do |z|
      separators = Stupidedi::Reader::Separators.build :segment => segment_terminator, :element => "*", :component => ":", :repetition => "^"
      edi_text = Stupidedi::Writer::Default.new(z.root, separators).write
    end
    edi_text
  end

  def build(dataset)
    isa06 = '94-3021419'
    isa08 = '94-1632821'
    version_5010 = '005010X220A1'
    b.ISA('00', nil, '00', nil, '30', isa06, 30, isa08, now, now.strftime('%H%M'), '=', '00501', stack.isa, 0, (production ? 'P' : 'T'), '>', '~')
    b.GS("BE", isa06, isa08, now, now.strftime('%H%M'), stack.gs, b.default, version_5010)
    file_ids = dataset.select_group(:file_id).select_map(:file_id)
    file_ids.each do |file_id|
      b.ST("834", stack.st, version_5010)
      b.BGN('00', rand(100000000..999999999), now, now.strftime('%H%M'), nil, nil, nil, 4)
      b.REF('38', file_id)

      # Loop 1000A
      b.N1('P5', "Chinese Community Health Plan", "FI", isa06)
      b.N1('IN', 'Vision Service Plan', "FI", isa08)

      # Loop 2000
      # PMPM = all members are subscribers
      # If member appears multiple times, only the last record will be kept on VSP system
      ds = dataset.where(:file_id => file_id)
      ds.all.each do |record|
        b.INS('Y', 18, '030', nil, 'A')
        b.REF('0F', record.fetch(:membernumber).rjust(9, '0'))
        b.REF('23', record.fetch(:membernumber).rjust(10, '0'))
        b.REF('DX', record.fetch(:vsp_division))
        b.NM1('IL', 1, record.fetch(:lastname), record.fetch(:firstname))
        b.N3(record.fetch(:address1), record.fetch(:address2))
        b.N4(record.fetch(:city), record.fetch(:state), record.fetch(:zip))
        b.DMG('D8', record.fetch(:dateofbirth), record.fetch(:gender))
        b.HD('030', nil, 'VIS', nil, 'IND')
        eff_dt = record.fetch(:effectivedate).to_date
        eff_dt = Date.civil(2020, 1, 1) if eff_dt < Date.civil(2020, 1, 1,)
        term_dt = record.fetch(:expirationdate).to_date
        term_dt = nil if term_dt > Date.today.next_month(3)
        b.DTP('348', 'D8', eff_dt)
        b.DTP('349', 'D8', term_dt) if term_dt
      end
      b.SE(stack.count(b), stack.pop_st)
    end
    b.GE(stack.count, stack.pop_gs)
    b.IEA(stack.count, stack.pop_isa)
  end
end