module Cohort
  class Pediatric
    attr_reader :under_age, :retro_months, :current_month

    def initialize(under_age: 19, retro_months: 4, current_month:)
      @under_age = under_age
      @retro_months = retro_months
      @current_month = current_month
    end

    def file_id
      '7204657'
    end

    def dataset
      HSP::DB[:pm1pg1].
          with(:pg1, HSP::Group.cchp
                         .select_append(HSP::Group.contract_effective_date(on: current_month).as(:contract_date))
                         .select_append(HSP::Group.plan_region.as(:group_region))
                         .where(Sequel.lit('coverageeffectivedate <= ?', current_month))
                         .where(Sequel.lit('coverageexpirationdate >= ?', current_month))).
          with(:pm1, HSP::Member.cchp.commercial.exclude_cancel).
          with(:pm1pg1, HSP::DB[:pm1].join(HSP::DB[:pg1], :groupid => :groupid)
                            .select(Sequel[:pm1][:memberid], Sequel[:pm1][:membernumber],
                                    Sequel[:pm1][:groupid], Sequel[:pm1][:groupnumber], :planname, :group_region,
                                    Sequel[:pm1][:groupname],
                                    :effectivedate, :expirationdate, :dateofbirth, :lastname, :firstname, :gender,
                                    :address1, :address2, :city, :state, :zip,
                                    :lineofbusiness, :productline, :contract_date,:riskgroupnumber)
                            .select_append(HSP::Member.age(on: :contract_date).as(:age))
                            .select_append(Sequel.as(vsp_division, :vsp_division))
                            .select_append(Sequel.as('4204657', :file_id))
          )
          .select(:memberid, :membernumber, :groupid, :groupnumber, :groupname, :planname, :group_region, :effectivedate, :expirationdate,
                  :dateofbirth, :age, :lastname, :firstname, :gender, :address1, :address2, :city, :state, :zip,
                  :lineofbusiness, :productline, :contract_date, :riskgroupnumber,:vsp_division, :file_id)
          .where { |v| v.age < under_age }
          .where { |v| v.expirationdate > current_month.prev_month(retro_months) }
    end

    def vsp_division
      Sequel.case([
                      [{:lineofbusiness => 'OFF', :productline => 'ESP'}, 'OFF0002'],
                      [{:lineofbusiness => 'OFF', :productline => 'IFP'}, 'OFF0001'],
                      [{:lineofbusiness => 'ONE', :productline => 'ESP'}, 'ON0002'],
                      [{:lineofbusiness => 'ONE', :productline => 'IFP'}, 'ON0001'],
                  ], 'UNDEF')
    end
  end
end