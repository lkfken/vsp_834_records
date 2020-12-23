module Cohort
  class Senior
    attr_reader :retro_months, :current_month, :min_age

    def initialize(retro_months: 4, current_month:)
      @retro_months = retro_months
      @current_month = current_month
    end

    def file_id
      '9075'
    end

    def dataset
      HSP::DB[:sm1sg1].
          with(:sm1, HSP::Member.medicare.where(:groupnumber => %w[CS65AB11 CS65DE01]).exclude_cancel).
          with(:sg1, HSP::Group
                         .select_append(HSP::Group.contract_effective_date(on: current_month).as(:contract_date))
                         .select_append(HSP::Group.plan_region.as(:group_region))).
          with(:sm1sg1, HSP::DB[:sm1].join(HSP::DB[:sg1], :groupid => :groupid)
                            .select(:memberid, :membernumber, Sequel[:sm1][:groupid], Sequel[:sm1][:groupnumber],
                                    Sequel[:sm1][:groupname], :planname, :group_region, eff_dt.as(:effectivedate), :expirationdate,
                                    :dateofbirth, HSP::Member.age(on: :contract_date).as(:age), :lastname, :firstname, :gender, :address1, :address2, :city, :state, :zip,
                                    :lineofbusiness, :productline, :contract_date, :riskgroupnumber)
                            .select_append(vsp_division.as(:vsp_division))
                            .select_append(Sequel.as('9075', :file_id))
          )
          .select(:memberid, :membernumber, :groupid, :groupnumber, :groupname, :planname, :group_region, :effectivedate, :expirationdate,
                  :dateofbirth, :age, :lastname, :firstname, :gender, :address1, :address2, :city, :state, :zip,
                  :lineofbusiness, :productline, :contract_date, :riskgroupnumber, :vsp_division, :file_id)
          .where { |v| v.expirationdate > current_month.prev_month(retro_months) }
          .where { effectivedate <= expirationdate }
    end

    def eff_dt
      Sequel.case([[Sequel.expr { effectivedate < contract_date }, :contract_date]], :effectivedate)
    end

    def vsp_division
      Sequel.case([
                      [{:lineofbusiness => 'MED', :productline => 'MED'}, '300276020002'],
                      [{:lineofbusiness => 'MED', :productline => 'SNP'}, '300276020001']
                  ], 'UNDEF')
    end
  end
end