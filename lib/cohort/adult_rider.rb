module Cohort
  class AdultRider
    attr_reader :retro_months, :current_month, :min_age

    def initialize(min_age: 19, retro_months: 4, current_month:)
      @min_age = min_age
      @retro_months = retro_months
      @current_month = current_month
    end

    def file_id
      '9075'
    end

    def dataset
      HSP::DB[:am1ag1].
          with(:ag1, HSP::Group.cchp.off_exchange
                         .select_append(HSP::Group.contract_effective_date(on: current_month).as(:contract_date))
                         .select_append(HSP::Group.plan_region.as(:group_region))
                         .where(Sequel.lit('coverageeffectivedate <= ?', current_month))
                         .where(Sequel.lit('coverageexpirationdate >= ?', current_month))).
          with(:am1, HSP::Member.cchp.commercial.exclude_cancel.from_self(:alias => :m)
                         .join(HSP::MemberRider.exclude_cancel.vision_rider, {membercoverageid: :membercoverageid}, table_alias: :r)
                         .select(Sequel[:m][:memberid], Sequel[:m][:groupid], Sequel[:r][:membercoverageid],
                                 :groupnumber, :groupname, :membernumber, :ridername, :appliedlevel,
                                 Sequel.as(Sequel[:r][:effectivedate], :member_rider_eff),
                                 Sequel.as(Sequel[:r][:expirationdate], :member_rider_exp),
                                 :dateofbirth, :lastname, :firstname, :gender, :address1, :address2, :city, :state, :zip,
                                 :lineofbusiness, :productline, :riskgroupnumber)).
          with(:am1ag1, HSP::DB[:am1].join(HSP::DB[:ag1], :groupid => :groupid)
                            .select(Sequel[:am1][:memberid], Sequel[:am1][:membernumber],
                                    Sequel[:am1][:groupid], Sequel[:am1][:groupnumber], Sequel[:am1][:groupname], :planname, :group_region,
                                    :member_rider_eff, :member_rider_exp, :dateofbirth, :lastname, :firstname, :gender,
                                    :address1, :address2, :city, :state, :zip, :contract_date,
                                    :lineofbusiness, :productline, :riskgroupnumber)
                            .select_append(HSP::Member.age(on: :contract_date).as(:age))
                            .select_append(Sequel.as(vsp_division, :vsp_division))
                            .select_append(Sequel.as('9075', :file_id))
          )
          .select(:memberid, :membernumber, :groupid, :groupnumber, :groupname, :planname, :group_region, Sequel.as(:member_rider_eff, :effectivedate),
                  Sequel.as(:member_rider_exp, :expirationdate), :dateofbirth, :age, :lastname, :firstname, :gender, :address1, :address2, :city, :state, :zip,
                  :lineofbusiness, :productline, :contract_date, :riskgroupnumber, :vsp_division, :file_id)
          .where { |v| v.age >= min_age }
          .where { |v| v.member_rider_exp > current_month.prev_month(retro_months) }.from_self
    end

    def vsp_division
      # IFP = 300433990003, ESP = 300433990005
      Sequel.case([
                      [{:productline => 'ESP'}, '300433990005']
                  ], '300433990003')
    end
  end
end